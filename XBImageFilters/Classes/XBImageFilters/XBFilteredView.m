//
//  XBFilteredView.m
//  XBImageFilters
//
//  Created by xiss burg on 3/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XBFilteredView.h"
#import "GLKProgram.h"

typedef struct {
    GLKVector3 position;
    GLKVector2 texCoord;
} Vertex;

@interface XBFilteredView ()

@property (strong, nonatomic) EAGLContext *context;
@property (strong, nonatomic) GLKView *glkView;

@property (assign, nonatomic) GLuint imageQuadVertexBuffer;
@property (assign, nonatomic) GLuint mainTexture;
@property (assign, nonatomic) GLint textureWidth, textureHeight;

@property (assign, nonatomic) GLKMatrix4 contentModeTransform;

/**
 * Multi-pass filtering support.
 */
@property (assign, nonatomic) GLuint oddPassTexture;
@property (assign, nonatomic) GLuint evenPassTexture;
@property (assign, nonatomic) GLuint oddPassFramebuffer;
@property (assign, nonatomic) GLuint evenPassFrambuffer;

- (void)setupGL;
- (void)destroyGL;
- (GLuint)generateDefaultTextureWithWidth:(GLint)width height:(GLint)height data:(GLvoid *)data;
- (GLuint)generateDefaultFramebufferWithTargetTexture:(GLuint)texture;
- (void)setupEvenPass;
- (void)destroyEvenPass;
- (void)setupOddPass;
- (void)destroyOddPass;
- (void)refreshContentTransform;

- (GLKMatrix4)transformForAspectFitOrFill:(BOOL)fit;
- (GLKMatrix4)transformForPositionalContentMode:(UIViewContentMode)contentMode;

@end

@implementation XBFilteredView

@synthesize context = _context;
@synthesize glkView = _glkView;
@synthesize imageQuadVertexBuffer = _imageQuadVertexBuffer;
@synthesize mainTexture = _mainTexture;
@synthesize textureWidth = _textureWidth, textureHeight = _textureHeight;
@synthesize contentTransform = _contentTransform;
@synthesize contentModeTransform = _contentModeTransform;
@synthesize contentSize = _contentSize;
@synthesize programs = _programs;
@synthesize oddPassTexture = _oddPassTexture;
@synthesize evenPassTexture = _evenPassTexture;
@synthesize oddPassFramebuffer = _oddPassFramebuffer;
@synthesize evenPassFrambuffer = _evenPassFrambuffer;

/**
 * Actual initializer. Called both in initWithFrame: when creating an instance programatically and in awakeFromNib when creating an instance
 * from a nib/storyboard.
 */
- (void)_XBFilteredViewInit //Use a weird name to avoid being overidden
{
    self.contentScaleFactor = [[UIScreen mainScreen] scale];
    
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    self.glkView = [[GLKView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height) context:self.context];
    self.glkView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.glkView.delegate = self;
    self.glkView.enableSetNeedsDisplay = YES;
    [self addSubview:self.glkView];
    
    [self setupGL];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self _XBFilteredViewInit];
    }
    return self;
}

- (void)awakeFromNib
{
    [self _XBFilteredViewInit];
}

- (void)dealloc
{
    [self destroyGL];
    [EAGLContext setCurrentContext:nil];
}

#pragma mark - Properties

- (void)setContentTransform:(GLKMatrix4)contentTransform
{
    _contentTransform = contentTransform;
    [self refreshContentTransform];
}

- (void)setContentModeTransform:(GLKMatrix4)contentModeTransform
{
    _contentModeTransform = contentModeTransform;
    [self refreshContentTransform];
}

- (void)setContentSize:(CGSize)contentSize
{
    _contentSize = contentSize;
    [self refreshContentTransform];
}

#pragma mark - Protected Methods

- (void)_setTextureData:(GLvoid *)textureData width:(GLint)width height:(GLint)height
{
    [EAGLContext setCurrentContext:self.context];
    
    glDeleteTextures(1, &_mainTexture);
    
    self.textureWidth = width;
    self.textureHeight = height;
    self.mainTexture = [self generateDefaultTextureWithWidth:self.textureWidth height:self.textureHeight data:textureData];
    
    // Resize the even and odd textures because their size have to match that of the mainTexture
    if (self.programs.count >= 2) {
        [self destroyEvenPass];
        [self setupEvenPass];
    }
    
    if (self.programs.count > 2) {
        [self destroyOddPass];
        [self setupOddPass];
    }
    
    // Update the texture in the first shader
    if (self.programs.count > 0) {
        GLKProgram *firstProgram = [self.programs objectAtIndex:0];
        [firstProgram bindSamplerNamed:@"s_texture" toTexture:self.mainTexture unit:0];
    }
    
    // Force an update on the contentTransform since it depends on the textureWidth and textureHeight
    [self setNeedsLayout];
    
    [self.glkView setNeedsDisplay];
}

- (void)_updateTextureWithData:(GLvoid *)textureData
{
    [EAGLContext setCurrentContext:self.context];
    
    glBindTexture(GL_TEXTURE_2D, self.mainTexture);
    glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, self.textureWidth, self.textureHeight, GL_BGRA, GL_UNSIGNED_BYTE, textureData);
    glBindTexture(GL_TEXTURE_2D, 0);
    
    [self.glkView setNeedsDisplay];
}

- (void)_deleteMainTexture
{
    [EAGLContext setCurrentContext:self.context];
    glDeleteTextures(1, &_mainTexture);
    _mainTexture = 0;
}

#pragma mark - Public Methods

- (BOOL)setFilterFragmentShaderFromFile:(NSString *)path error:(NSError *__autoreleasing *)error
{
    NSArray *paths = [[NSArray alloc] initWithObjects:path, nil];
    return [self setFilterFragmentShadersFromFiles:paths error:error];
}

- (BOOL)setFilterFragmentShadersFromFiles:(NSArray *)paths error:(NSError *__autoreleasing *)error
{
    [EAGLContext setCurrentContext:self.context];
    
    /* Create frame buffers for render to texture in multi-pass filters if necessary. If we have a single pass/fragment shader, we'll render
     * directly to the framebuffer. If we have two passes, we'll render to the evenPassFramebuffer using the original image as the filter source
     * texture and then render directly to the framebuffer using the evenPassTexture as the filter source. If we have three passes, the second
     * filter will instead render to the oddPassFramebuffer and the third/last pass will render to the framebuffer using the oddPassTexture.
     * And so on... */
    if (paths.count >= 2) {
        // Two or more passes, create evenPass*
        [self setupEvenPass];
    }
    else {
        [self destroyEvenPass];
    }
    
    if (paths.count > 2) {
        // More than two passes, create oddPass*
        [self setupOddPass];
    }
    else {
        [self destroyOddPass];
    }
    
    NSMutableArray *programs = [[NSMutableArray alloc] initWithCapacity:paths.count];
    NSString *vertexShaderPath = [[NSBundle mainBundle] pathForResource:@"DefaultVertexShader" ofType:@"glsl"];
    
    for (int i = 0; i < paths.count; ++i) {
        NSString *fragmentShaderPath = [paths objectAtIndex:i];
        GLKProgram *program = [[GLKProgram alloc] initWithVertexShaderFromFile:vertexShaderPath fragmentShaderFromFile:fragmentShaderPath error:error];
        
        if (program == nil) {
            return NO;
        }
        
        [program setValue:(void *)&GLKMatrix4Identity forUniformNamed:@"u_contentTransform"];
        
        GLuint sourceTexture = 0;
        
        if (i == 0) { // First pass always uses the original image
            sourceTexture = self.mainTexture;
        }
        else if (i%2 == 1) { // Second pass uses the result of the first, and the first is 0, hence even
            sourceTexture = self.evenPassTexture;
        }
        else { // Third pass uses the result of the second, which is number 1, then it's odd
            sourceTexture = self.oddPassTexture;
        }
        
        [program bindSamplerNamed:@"s_texture" toTexture:sourceTexture unit:0];
        
        [programs addObject:program];
    }
    
    self.programs = [programs copy];
    
    [self setNeedsLayout];
    [self setNeedsDisplay];
    
    return YES;
}

- (UIImage *)takeScreenshot
{
    return [self takeScreenshotWithImageOrientation:UIImageOrientationDownMirrored];
}

- (UIImage *)takeScreenshotWithImageOrientation:(UIImageOrientation)orientation
{
    [EAGLContext setCurrentContext:self.context];
    
    int width = (int)(self.bounds.size.width * self.contentScaleFactor);
    int height = (int)(self.bounds.size.height * self.contentScaleFactor);
    size_t size = width * height * 4;
    GLvoid *pixels = malloc(size);
    glReadPixels(0, 0, width, height, GL_RGBA, GL_UNSIGNED_BYTE, pixels);
    
    size_t bitsPerComponent = 8;
    size_t bitsPerPixel = 32;
    size_t bytesPerRow = width * bitsPerPixel / bitsPerComponent;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault;
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, pixels, size, NULL);
    CGImageRef cgImage = CGImageCreate(width, height, bitsPerComponent, bitsPerPixel, bytesPerRow, colorSpace, bitmapInfo, provider, NULL, FALSE, kCGRenderingIntentDefault);
    CGDataProviderRelease(provider);
    
    UIImage *image = [UIImage imageWithCGImage:cgImage scale:self.contentScaleFactor orientation:orientation];
    CGImageRelease(cgImage);
    CGColorSpaceRelease(colorSpace);
    
    return image;
}

- (void)forceDisplay
{
    [self.glkView display];
}

#pragma mark - Private Methods

- (void)setupGL
{
    [EAGLContext setCurrentContext:self.context];
    
    // Create vertices
    Vertex vertices[] = {
        {{ 1,  1, 0}, {1, 1}},
        {{-1,  1, 0}, {0, 1}},
        {{ 1, -1, 0}, {1, 0}},
        {{-1, -1, 0}, {0, 0}}
    };
    
    // Create vertex buffer and fill it with data
    glGenBuffers(1, &_imageQuadVertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, self.imageQuadVertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
    
    // Setup default shader
    NSString *fragmentShaderPath = [[NSBundle mainBundle] pathForResource:@"DefaultFragmentShader" ofType:@"glsl"];
    NSError *error = nil;
    [self setFilterFragmentShaderFromFile:fragmentShaderPath error:&error];
    
    if (error != nil) {
        NSLog(@"%@", [error localizedDescription]);
    }
    
    // Initialize transform to the most basic projection
    self.contentModeTransform = GLKMatrix4MakeOrtho(-1.f, 1.f, -1.f, 1.f, -1.f, 1.f);
    self.contentTransform = GLKMatrix4Identity;
}

- (void)destroyGL
{
    [EAGLContext setCurrentContext:self.context];
    
    glDeleteBuffers(1, &_imageQuadVertexBuffer);
    self.imageQuadVertexBuffer = 0;
    
    glDeleteTextures(1, &_mainTexture);
    glDeleteTextures(1, &_evenPassTexture);
    glDeleteTextures(1, &_oddPassTexture);
    
    glDeleteFramebuffers(1, &_evenPassFrambuffer);
    glDeleteFramebuffers(1, &_oddPassFramebuffer);
}

- (GLuint)generateDefaultTextureWithWidth:(GLint)width height:(GLint)height data:(GLvoid *)data
{
    GLuint texture = 0;
    glGenTextures(1, &texture);
    glBindTexture(GL_TEXTURE_2D, texture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_BGRA, GL_UNSIGNED_BYTE, data);
    glBindTexture(GL_TEXTURE_2D, 0);
    return texture;
}

- (GLuint)generateDefaultFramebufferWithTargetTexture:(GLuint)texture
{
    GLuint framebuffer = 0;
    glGenFramebuffers(1, &framebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, texture, 0);
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    return framebuffer;
}

- (void)setupEvenPass
{
    self.evenPassTexture = [self generateDefaultTextureWithWidth:self.textureWidth height:self.textureHeight data:NULL];
    self.evenPassFrambuffer = [self generateDefaultFramebufferWithTargetTexture:self.evenPassTexture];
}

- (void)destroyEvenPass
{
    glDeleteTextures(1, &_evenPassTexture);
    self.evenPassTexture = 0;
    glDeleteFramebuffers(1, &_evenPassFrambuffer);
    self.evenPassFrambuffer = 0;
}

- (void)setupOddPass
{
    self.oddPassTexture = [self generateDefaultTextureWithWidth:self.textureWidth height:self.textureHeight data:NULL];
    self.oddPassFramebuffer = [self generateDefaultFramebufferWithTargetTexture:self.oddPassTexture];
}

- (void)destroyOddPass
{
    glDeleteTextures(1, &_oddPassTexture);
    self.oddPassTexture = 0;
    glDeleteFramebuffers(1, &_oddPassFramebuffer);
    self.oddPassFramebuffer = 0;
}

- (void)refreshContentTransform
{
    GLKMatrix4 composedTransform = GLKMatrix4Multiply(self.contentTransform, self.contentModeTransform);
    GLKProgram *lastProgram = [self.programs lastObject];
    [lastProgram setValue:composedTransform.m forUniformNamed:@"u_contentTransform"];
}

- (void)setContentMode:(UIViewContentMode)contentMode
{
    [super setContentMode:contentMode];
}

- (void)setNeedsDisplay
{
    [super setNeedsDisplay];
    [self.glkView setNeedsDisplay];
}

- (void)layoutSubviews
{
    switch (self.contentMode) {
        case UIViewContentModeScaleToFill:
            self.contentModeTransform = GLKMatrix4MakeOrtho(-1.f, 1.f, -1.f, 1.f, -1.f, 1.f);
            break;
            
        case UIViewContentModeScaleAspectFit:
            self.contentModeTransform = [self transformForAspectFitOrFill:YES];
            break;
            
        case UIViewContentModeScaleAspectFill:
            self.contentModeTransform = [self transformForAspectFitOrFill:NO];
            break;
            
        case UIViewContentModeCenter:
        case UIViewContentModeBottom:
        case UIViewContentModeTop:
        case UIViewContentModeLeft:
        case UIViewContentModeRight:
        case UIViewContentModeBottomLeft:
        case UIViewContentModeBottomRight:
        case UIViewContentModeTopLeft:
        case UIViewContentModeTopRight:
            self.contentModeTransform = [self transformForPositionalContentMode:self.contentMode];
            break;
            
        case UIViewContentModeRedraw:
            break;
            
        default:
            break;
    }
    
    [self.glkView setNeedsDisplay];
}

- (GLKMatrix4)transformForAspectFitOrFill:(BOOL)fit
{
    float imageAspect = (float)self.contentSize.width/self.contentSize.height;
    float viewAspect = self.bounds.size.width/self.bounds.size.height;
    GLKMatrix4 transform;
    
    if ((imageAspect > viewAspect && fit) || (imageAspect < viewAspect && !fit)) {
        transform = GLKMatrix4MakeOrtho(-1, 1, -imageAspect/viewAspect, imageAspect/viewAspect, -1, 1);
    }
    else {
        transform = GLKMatrix4MakeOrtho(-viewAspect/imageAspect, viewAspect/imageAspect, -1, 1, -1, 1);
    }
    
    return transform;
}

- (GLKMatrix4)transformForPositionalContentMode:(UIViewContentMode)contentMode
{
    float widthRatio = self.bounds.size.width/self.contentSize.width*self.contentScaleFactor;
    float heightRatio = self.bounds.size.height/self.contentSize.height*self.contentScaleFactor;
    GLKMatrix4 transform = GLKMatrix4Identity;
    
    switch (contentMode) {
        case UIViewContentModeCenter:
            transform = GLKMatrix4MakeOrtho(-widthRatio, widthRatio, -heightRatio, heightRatio, -1, 1);
            break;
            
        case UIViewContentModeBottom:
            transform = GLKMatrix4MakeOrtho(-widthRatio, widthRatio, -1, 2*heightRatio - 1, -1, 1);
            break;
            
        case UIViewContentModeTop:
            transform = GLKMatrix4MakeOrtho(-widthRatio, widthRatio, -2*heightRatio + 1, 1, -1, 1);
            break;
            
        case UIViewContentModeLeft:
            transform = GLKMatrix4MakeOrtho(-1, 2*widthRatio - 1, -heightRatio, heightRatio, -1, 1);
            break;
            
        case UIViewContentModeRight:
            transform = GLKMatrix4MakeOrtho(-2*widthRatio + 1, 1, -heightRatio, heightRatio, -1, 1);
            break;
            
        case UIViewContentModeTopLeft:
            transform = GLKMatrix4MakeOrtho(-1, 2*widthRatio - 1, -2*heightRatio + 1, 1, -1, 1);
            break;
            
        case UIViewContentModeTopRight:
            transform = GLKMatrix4MakeOrtho(-2*widthRatio + 1, 1, -2*heightRatio + 1, 1, -1, 1);
            break;
            
        case UIViewContentModeBottomLeft:
            transform = GLKMatrix4MakeOrtho(-1, 2*widthRatio - 1, -1, 2*heightRatio - 1, -1, 1);
            break;
            
        case UIViewContentModeBottomRight:
            transform = GLKMatrix4MakeOrtho(-2*widthRatio + 1, 1, -1, 2*heightRatio - 1, -1, 1);
            break;
            
        default:
            NSLog(@"Warning: Invalid contentMode given to transformForPositionalContentMode: %d", contentMode);
            break;
    }
    
    return transform;
}

#pragma mark - GLKViewDelegate

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    CGFloat r, g, b, a;
    [self.backgroundColor getRed:&r green:&g blue:&b alpha:&a];
    glClearColor(r, g, b, a);
    glClear(GL_COLOR_BUFFER_BIT);
    
    for (int pass = 0; pass < self.programs.count; ++pass) {
        GLKProgram *program = [self.programs objectAtIndex:pass];
        
        if (pass == self.programs.count - 1) { // Last pass
            [self.glkView bindDrawable];
        }
        else if (pass%2 == 0) {
            glViewport(0, 0, self.textureWidth, self.textureHeight);
            glBindFramebuffer(GL_FRAMEBUFFER, self.evenPassFrambuffer);
        }
        else {
            glViewport(0, 0, self.textureWidth, self.textureHeight);
            glBindFramebuffer(GL_FRAMEBUFFER, self.oddPassFramebuffer);
        }
        
        [program prepareToDraw];
        
        glBindBuffer(GL_ARRAY_BUFFER, self.imageQuadVertexBuffer);
        
        GLKAttribute *positionAttribute = [program.attributes objectForKey:@"a_position"];
        glVertexAttribPointer(positionAttribute.location, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), (GLvoid *)offsetof(Vertex, position));
        glEnableVertexAttribArray(positionAttribute.location);
        
        GLKAttribute *texCoordAttribute = [program.attributes objectForKey:@"a_texCoord"];
        glVertexAttribPointer(texCoordAttribute.location, 2, GL_FLOAT, GL_FALSE, sizeof(Vertex), (GLvoid *)offsetof(Vertex, texCoord));
        glEnableVertexAttribArray(texCoordAttribute.location);
        
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    }
    
#ifdef DEBUG
    GLenum error = glGetError();
    if (error != GL_NO_ERROR) {
        NSLog(@"%d", error);
    }
#endif
}

@end
