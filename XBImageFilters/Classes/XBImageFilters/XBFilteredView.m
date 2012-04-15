//
//  XBFilteredView.m
//  XBImageFilters
//
//  Created by xiss burg on 3/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XBFilteredView.h"
#import "GLKProgram.h"
#import <QuartzCore/QuartzCore.h>

const GLKMatrix2 GLKMatrix2Identity = {1, 0, 0, 1};

typedef struct {
    GLKVector3 position;
    GLKVector2 texCoord;
} Vertex;

@interface XBFilteredView ()

@property (strong, nonatomic) EAGLContext *context;
@property (assign, nonatomic) GLuint framebuffer;
@property (assign, nonatomic) GLuint colorRenderbuffer;
@property (assign, nonatomic) GLuint depthRenderbuffer;
@property (assign, nonatomic) GLint viewportWidth;
@property (assign, nonatomic) GLint viewportHeight;

@property (assign, nonatomic) CGRect previousBounds; //used in layoutSubviews to determine whether the framebuffer should be recreated

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
@synthesize framebuffer = _framebuffer;
@synthesize colorRenderbuffer = _colorRenderbuffer;
@synthesize depthRenderbuffer = _depthRenderbuffer;
@synthesize viewportWidth = _viewportWidth;
@synthesize viewportHeight = _viewportHeight;
@synthesize previousBounds = _previousBounds;
@synthesize imageQuadVertexBuffer = _imageQuadVertexBuffer;
@synthesize mainTexture = _mainTexture;
@synthesize textureWidth = _textureWidth, textureHeight = _textureHeight;
@synthesize contentTransform = _contentTransform;
@synthesize contentModeTransform = _contentModeTransform;
@synthesize contentSize = _contentSize;
@synthesize texCoordTransform = _texCoordTransform;
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
    self.layer.opaque = YES;

    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    self.previousBounds = CGRectZero;
    
    if ([self needsToCreateFramebuffer]) {
        [self createFramebuffer];
        self.previousBounds = self.bounds;
    }
    
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
    [EAGLContext setCurrentContext:self.context];
    [self destroyGL];
    self.context = nil;
    [EAGLContext setCurrentContext:nil];
}

#pragma mark - Overrides

+ (Class)layerClass
{
    return [CAEAGLLayer class];
}

- (void)layoutSubviews
{
    if ([self needsToCreateFramebuffer]) {
        [self createFramebuffer];
    }
    
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
    
    self.previousBounds = self.bounds;
    [self display];
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

- (void)setTexCoordTransform:(GLKMatrix2)texCoordTransform
{
    _texCoordTransform = texCoordTransform;
    
    // The transform is applied only on the first program, because the next ones will already receive and image with the transform applied.
    // The transform would be applied again on each filter otherwise.
    GLKProgram *firstProgram = [self.programs objectAtIndex:0];
    [firstProgram setValue:&texCoordTransform forUniformNamed:@"u_texCoordTransform"];
}

#pragma mark - Protected Methods

- (void)_setTextureData:(GLvoid *)textureData width:(GLint)width height:(GLint)height
{
    [EAGLContext setCurrentContext:self.context];
    
    glDeleteTextures(1, &_mainTexture);
    [self destroyEvenPass];
    [self destroyOddPass];
    
    self.textureWidth = width;
    self.textureHeight = height;
    self.mainTexture = [self generateDefaultTextureWithWidth:self.textureWidth height:self.textureHeight data:textureData];
    
    // Resize the even and odd textures because their size have to match that of the mainTexture
    if (self.programs.count >= 2) {
        [self setupEvenPass];
    }
    
    if (self.programs.count > 2) {
        [self setupOddPass];
    }
    
    // Update the texture in the first shader
    if (self.programs.count > 0) {
        GLKProgram *firstProgram = [self.programs objectAtIndex:0];
        [firstProgram bindSamplerNamed:@"s_texture" toTexture:self.mainTexture unit:0];
    }
    
    // Force an update on the contentTransform since it depends on the textureWidth and textureHeight
    [self setNeedsLayout];
}

- (void)_updateTextureWithData:(GLvoid *)textureData
{
    [EAGLContext setCurrentContext:self.context];
    
    glBindTexture(GL_TEXTURE_2D, self.mainTexture);
    glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, self.textureWidth, self.textureHeight, GL_BGRA, GL_UNSIGNED_BYTE, textureData);
    glBindTexture(GL_TEXTURE_2D, 0);
    
    [self display];
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
    
    [self destroyEvenPass];
    [self destroyOddPass];
    
    /* Create frame buffers for render to texture in multi-pass filters if necessary. If we have a single pass/fragment shader, we'll render
     * directly to the framebuffer. If we have two passes, we'll render to the evenPassFramebuffer using the original image as the filter source
     * texture and then render directly to the framebuffer using the evenPassTexture as the filter source. If we have three passes, the second
     * filter will instead render to the oddPassFramebuffer and the third/last pass will render to the framebuffer using the oddPassTexture.
     * And so on... */
    
    if (paths.count >= 2) {
        // Two or more passes, create evenPass*
        [self setupEvenPass];
    }
    
    if (paths.count > 2) {
        // More than two passes, create oddPass*
        [self setupOddPass];
    }
    
    NSMutableArray *programs = [[NSMutableArray alloc] initWithCapacity:paths.count];
    NSString *vertexShaderPath = [[NSBundle mainBundle] pathForResource:@"DefaultVertexShader" ofType:@"glsl"];
    
    for (int i = 0; i < paths.count; ++i) {
        NSString *fragmentShaderPath = [paths objectAtIndex:i];
        GLKProgram *program = [[GLKProgram alloc] initWithVertexShaderFromFile:vertexShaderPath fragmentShaderFromFile:fragmentShaderPath error:error];
        
        if (program == nil) {
            return NO;
        }

        [program setValue:i == paths.count - 1?&_contentTransform: (void *)&GLKMatrix4Identity forUniformNamed:@"u_contentTransform"];
        [program setValue:i == 0?&_texCoordTransform: (void *)&GLKMatrix2Identity forUniformNamed:@"u_texCoordTransform"];
        
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

- (void)display
{
    [EAGLContext setCurrentContext:self.context];
    
    CGFloat r, g, b, a;
    [self.backgroundColor getRed:&r green:&g blue:&b alpha:&a];
    glClearColor(r, g, b, a);
    glDisable(GL_DEPTH_TEST);
    
    for (int pass = 0; pass < self.programs.count; ++pass) {
        GLKProgram *program = [self.programs objectAtIndex:pass];
        
        if (pass == self.programs.count - 1) { // Last pass, bind framebuffer
            glViewport(0, 0, self.viewportWidth, self.viewportHeight);
            glBindFramebuffer(GL_FRAMEBUFFER, self.framebuffer);
        }
        else if (pass%2 == 0) {
            glViewport(0, 0, self.textureWidth, self.textureHeight);
            glBindFramebuffer(GL_FRAMEBUFFER, self.evenPassFrambuffer);
        }
        else {
            glViewport(0, 0, self.textureWidth, self.textureHeight);
            glBindFramebuffer(GL_FRAMEBUFFER, self.oddPassFramebuffer);
        }
            
        glClear(GL_COLOR_BUFFER_BIT);
        
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
    
    glBindRenderbuffer(GL_RENDERBUFFER, self.colorRenderbuffer);
    [self.context presentRenderbuffer:GL_RENDERBUFFER];
    
#ifdef DEBUG
    GLenum error = glGetError();
    if (error != GL_NO_ERROR) {
        NSLog(@"%d", error);
    }
#endif
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
    
    // Initialize transform to the most basic projection, and set others to identity
    self.contentModeTransform = GLKMatrix4MakeOrtho(-1.f, 1.f, -1.f, 1.f, -1.f, 1.f);
    self.contentTransform = GLKMatrix4Identity;
    self.texCoordTransform = GLKMatrix2Identity;
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
    
    [self destroyFramebuffer];
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
    
    // The contentTransform is only applied on the last program otherwise it would be reapplied in each filter. Also, the contentTransform's
    // purpose is to adjust the final image on the framebuffer/screen. That is why it is applied only in the end.
    GLKProgram *lastProgram = [self.programs lastObject];
    [lastProgram setValue:composedTransform.m forUniformNamed:@"u_contentTransform"];
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

- (BOOL)needsToCreateFramebuffer
{
    return !CGSizeEqualToSize(self.previousBounds.size, self.bounds.size);
}

- (BOOL)createFramebuffer
{
    [EAGLContext setCurrentContext:self.context];
    
    [self destroyFramebuffer];
    
    glGenFramebuffers(1, &_framebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, self.framebuffer);
    
    glGenRenderbuffers(1, &_colorRenderbuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, self.colorRenderbuffer);
    [self.context renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer *)self.layer];
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, self.colorRenderbuffer);
    
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &_viewportWidth);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &_viewportHeight);
    
    glGenRenderbuffers(1, &_depthRenderbuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, self.depthRenderbuffer);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, self.viewportWidth, self.viewportHeight);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, self.depthRenderbuffer);
    
    GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    
    if (status != GL_FRAMEBUFFER_COMPLETE) {
        NSLog(@"Failed to create framebuffer: %x", status);
        return NO;
    }
    
    return YES;
}

- (void)destroyFramebuffer
{
    glDeleteFramebuffers(1, &_framebuffer);
    self.framebuffer = 0;
    
    glDeleteRenderbuffers(1, &_colorRenderbuffer);
    self.colorRenderbuffer = 0;
    
    glDeleteRenderbuffers(1, &_depthRenderbuffer);
    self.depthRenderbuffer = 0;
}

@end
