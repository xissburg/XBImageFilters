//
//  XBFilteredImageView.m
//  XBImageFilters
//
//  Created by xiss burg on 2/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XBFilteredImageView.h"
#import "GLKProgram.h"

typedef struct {
    GLKVector3 position;
    GLKVector2 texCoord;
} Vertex;

@interface XBFilteredImageView ()

@property (strong, nonatomic) EAGLContext *context;
@property (strong, nonatomic) GLKView *glkView;
@property (strong, nonatomic) GLKProgram *program;

@property (assign, nonatomic) GLuint imageQuadVertexBuffer;
@property (assign, nonatomic) GLuint imageTexture;
@property (assign, nonatomic) GLint textureWidth, textureHeight;

/**
 * The texCoordScale is a vec2 that is multipled by the texCoords of each vertex in the vertex shader. We have to do this because in
 * OpenGL ES 2 the texture sides must be power of two, but most of the images won't be power of two on each side, then we have to 
 * adjust the texture coordinates so that the image will fit perfectly in the rectangle/quad. This vec2 is actually equals to
 * vec2(imageWidth/textureWidth, imageHeight/textureHeight).
 */
@property (assign, nonatomic) GLint texCoordScale;

- (void)setupGL;
- (void)destroyGL;

- (GLKMatrix4)transformForAspectFitOrFill:(BOOL)fit;
- (GLKMatrix4)transformForPositionalContentMode:(UIViewContentMode)contentMode;

@end

@implementation XBFilteredImageView

@synthesize context = _context;
@synthesize glkView = _glkView;
@synthesize program = _program;
@synthesize imageQuadVertexBuffer = _imageQuadVertexBuffer;
@synthesize imageTexture = _imageTexture;
@synthesize textureWidth = _textureWidth, textureHeight = _textureHeight;
@synthesize texCoordScale = _texCoordScale;
@synthesize contentTransfom = _contentTransfom;
@synthesize image = _image;

/**
 * Actual initializer. Called both in initWithFrame: when creating an instance programatically and in awakeFromNib when creating an instance
 * from a nib/storyboard.
 */
- (void)initialize
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
        [self initialize];
    }
    return self;
}

- (void)awakeFromNib
{
    [self initialize];
}

- (void)dealloc
{
    [self destroyGL];
    [EAGLContext setCurrentContext:nil];
}

#pragma mark - Properties

- (void)setImage:(UIImage *)image
{
    _image = image;
    
    [EAGLContext setCurrentContext:self.context];
    
    glDeleteTextures(1, &_imageTexture);
    
    if (_image == nil) {
        self.imageTexture = 0;
        return;
    }
    
    size_t width = CGImageGetWidth(image.CGImage);
    size_t height = CGImageGetHeight(image.CGImage);
    
    //Compute the lowest power of two that is greater than the image size
    self.textureWidth  = 1<<((int)floorf(log2f(width - 1)) + 1);
    self.textureHeight = 1<<((int)floorf(log2f(height - 1)) + 1);
    
    if (self.textureWidth < 64) {
        self.textureWidth = 64;
    }
    
    if (self.textureHeight < 64) {
        self.textureHeight = 64;
    }
    
    CGSize imageSize = CGSizeMake(self.textureWidth/self.contentScaleFactor, self.textureHeight/self.contentScaleFactor);
    UIGraphicsBeginImageContextWithOptions(imageSize, NO, self.contentScaleFactor);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(context, 0, 0);
    CGContextScaleCTM(context, 1, 1);
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), image.CGImage);
    GLubyte *textureData = (GLubyte *)CGBitmapContextGetData(context);
    
    glGenTextures(1, &_imageTexture);
    glBindTexture(GL_TEXTURE_2D, self.imageTexture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, self.textureWidth, self.textureHeight, 0, GL_BGRA, GL_UNSIGNED_BYTE, textureData);
    glBindTexture(GL_TEXTURE_2D, 0);
    
    UIGraphicsEndImageContext();
    
    // Update tex coord scale in shader
    GLfloat texCoordScale[] = {(GLfloat)width/self.textureWidth, (GLfloat)height/self.textureHeight};
    [self.program setValue:texCoordScale forUniformNamed:@"u_texCoordScale"];
    
    [self.glkView setNeedsDisplay];
}

#pragma mark - Public Methods

- (void)setFilterFragmentShaderFromFile:(NSString *)path error:(NSError *__autoreleasing *)error
{
    [EAGLContext setCurrentContext:self.context];
    NSString *vertexShaderPath = [[NSBundle mainBundle] pathForResource:@"DefaultVertexShader" ofType:@"glsl"];
    self.program = [[GLKProgram alloc] initWithVertexShaderFromFile:vertexShaderPath fragmentShaderFromFile:path error:error];
    
    // Update tex coord scale in shader
    size_t width = CGImageGetWidth(self.image.CGImage);
    size_t height = CGImageGetHeight(self.image.CGImage);
    GLfloat texCoordScale[] = {(GLfloat)width*self.contentScaleFactor/self.textureWidth, (GLfloat)height*self.contentScaleFactor/self.textureHeight};
    [self.program setValue:texCoordScale forUniformNamed:@"u_texCoordScale"];
    
    [self.program bindSamplerNamed:@"s_texture" toTexture:self.imageTexture unit:0];
    
    [self setNeedsDisplay];
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
    NSString *vertexShaderPath = [[NSBundle mainBundle] pathForResource:@"DefaultVertexShader" ofType:@"glsl"];
    NSString *fragmentShaderPath = [[NSBundle mainBundle] pathForResource:@"DefaultFragmentShader" ofType:@"glsl"];
    
    NSError *error = nil;
    self.program = [[GLKProgram alloc] initWithVertexShaderFromFile:vertexShaderPath fragmentShaderFromFile:fragmentShaderPath error:&error];
    
    if (error != nil) {
        NSLog(@"%@", [error localizedDescription]);
    }
    
    // Initialize transform to the most basic projection
    self.contentTransfom = GLKMatrix4MakeOrtho(-1.f, 1.f, -1.f, 1.f, -1.f, 1.f);
}

- (void)destroyGL
{
    [EAGLContext setCurrentContext:self.context];
    
    self.program = nil;
    
    glDeleteBuffers(1, &_imageQuadVertexBuffer);
    self.imageQuadVertexBuffer = 0;
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
            self.contentTransfom = GLKMatrix4MakeOrtho(-1.f, 1.f, -1.f, 1.f, -1.f, 1.f);
            break;
            
        case UIViewContentModeScaleAspectFit:
            self.contentTransfom = [self transformForAspectFitOrFill:YES];
            break;
            
        case UIViewContentModeScaleAspectFill:
            self.contentTransfom = [self transformForAspectFitOrFill:NO];
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
            self.contentTransfom = [self transformForPositionalContentMode:self.contentMode];
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
    float imageAspect = self.image.size.width/self.image.size.height;
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
    float widthRatio = self.bounds.size.width/self.image.size.width;
    float heightRatio = self.bounds.size.height/self.image.size.height;
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
    
    [self.program setValue:self.contentTransfom.m forUniformNamed:@"u_contentTransform"];
    [self.program prepareToDraw];
    
    glBindBuffer(GL_ARRAY_BUFFER, self.imageQuadVertexBuffer);
    
    GLKAttribute *positionAttribute = [self.program.attributes objectForKey:@"a_position"];
    glVertexAttribPointer(positionAttribute.location, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), (GLvoid *)offsetof(Vertex, position));
    glEnableVertexAttribArray(positionAttribute.location);
    
    GLKAttribute *texCoordAttribute = [self.program.attributes objectForKey:@"a_texCoord"];
    glVertexAttribPointer(texCoordAttribute.location, 2, GL_FLOAT, GL_FALSE, sizeof(Vertex), (GLvoid *)offsetof(Vertex, texCoord));
    glEnableVertexAttribArray(texCoordAttribute.location);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
#ifdef DEBUG
    GLenum error = glGetError();
    if (error != GL_NO_ERROR) {
        NSLog(@"%d", error);
    }
#endif
}

@end






















