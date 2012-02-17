//
//  XBFilteredImageView.m
//  XBImageFilters
//
//  Created by xiss burg on 2/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XBFilteredImageView.h"

typedef struct {
    GLKVector3 position;
    GLKVector2 texCoord;
} Vertex;

@interface XBFilteredImageView ()

@property (strong, nonatomic) EAGLContext *context;
@property (strong, nonatomic) GLKView *glkView;

@property (assign, nonatomic) GLuint imageQuadVertexBuffer;
@property (assign, nonatomic) GLuint imageFilterProgram;

@property (assign, nonatomic) GLuint imageTexture;

@property (assign, nonatomic) GLint positionHandle;
@property (assign, nonatomic) GLint texCoordHandle;
@property (assign, nonatomic) GLint textureHandle;

/**
 * The texCoordScale is a vec2 that is multipled by the texCoords of each vertex in the vertex shader. We have to do this because in
 * OpenGL ES 2 the texture sides must be power of two, but most of the images won't be power of two on each side, then we have to 
 * adjust the texture coordinates so that the image will fit perfectly in the rectangle/quad. This vec2 is actually equals to
 * vec2(imageWidth/textureWidth, imageHeight/textureHeight).
 */
@property (assign, nonatomic) GLint texCoordScale;

- (void)setupGL;
- (void)destroyGL;
- (GLuint)createShaderFromFile:(NSString *)filename type:(GLenum)type;

@end

@implementation XBFilteredImageView

@synthesize context = _context;
@synthesize glkView = _glkView;
@synthesize imageQuadVertexBuffer = _imageQuadVertexBuffer;
@synthesize imageFilterProgram = _imageFilterProgram;
@synthesize imageTexture = _imageTexture;
@synthesize positionHandle = _positionHandle;
@synthesize texCoordHandle = _texCoordHandle;
@synthesize textureHandle = _textureHandle;
@synthesize texCoordScale = _texCoordScale;
@synthesize image = _image;

/**
 * Actual initializer. Called both in initWithFrame: when creating an instance programatically and in awakeFromNib when creating an instance
 * from a nib/storyboard.
 */
- (void)initialize
{
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    self.glkView = [[GLKView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height) context:self.context];
    self.glkView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.glkView.delegate = self;
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
    
    CGFloat scaledWidth = width*self.contentScaleFactor;
    CGFloat scaledHeight = height*self.contentScaleFactor;
    
    //Compute the lowest power of two that is greater than the scaled image size
    GLint textureWidth  = 1<<((int)floorf(log2f(scaledWidth - 1)) + 1);
    GLint textureHeight = 1<<((int)floorf(log2f(scaledHeight - 1)) + 1);
    
    if (textureWidth < 64) {
        textureWidth = 64;
    }
    
    if (textureHeight < 64) {
        textureHeight = 64;
    }
    
    CGSize imageSize = CGSizeMake(textureWidth, textureHeight);
    UIGraphicsBeginImageContextWithOptions(imageSize, NO, self.contentScaleFactor);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(context, 0, 0);
    CGContextScaleCTM(context, 1, 1);
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), image.CGImage);
    GLubyte *textureData = (GLubyte *)CGBitmapContextGetData(context);
    
    glGenTextures(1, &_imageTexture);
    glBindTexture(GL_TEXTURE_2D, self.imageTexture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, textureWidth, textureHeight, 0, GL_BGRA, GL_UNSIGNED_BYTE, textureData);
    glBindTexture(GL_TEXTURE_2D, 0);
    
    UIGraphicsEndImageContext();
    
    // Update tex coord scale in shader
    glUseProgram(self.imageFilterProgram);
    glUniform2f(self.texCoordScale, (GLfloat)width/textureWidth, (GLfloat)height/textureHeight);
    glUseProgram(0);
    
    [self.glkView setNeedsDisplay];
}

#pragma mark - Methods

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
    
    // Setup shader
    GLuint vertexShader = [self createShaderFromFile:@"VertexShader.glsl" type:GL_VERTEX_SHADER];
    GLuint fragmentShader = [self createShaderFromFile:@"FragmentShader.glsl" type:GL_FRAGMENT_SHADER];
    self.imageFilterProgram = glCreateProgram();
    
    glAttachShader(self.imageFilterProgram, vertexShader);
    glAttachShader(self.imageFilterProgram, fragmentShader);
    glLinkProgram(self.imageFilterProgram);
    
    GLint linked = 0;
    glGetProgramiv(self.imageFilterProgram, GL_LINK_STATUS, &linked);
    
    if (linked == 0) {
        glDeleteProgram(self.imageFilterProgram);
        return;
    }
    
    // Get handles to uniform shader variables
    self.positionHandle = glGetAttribLocation(self.imageFilterProgram, "a_position");
    self.texCoordHandle = glGetAttribLocation(self.imageFilterProgram, "a_texCoord");
    self.texCoordScale = glGetUniformLocation(self.imageFilterProgram, "u_texCoordScale");
    self.textureHandle = glGetUniformLocation(self.imageFilterProgram, "s_texture");
}

- (void)destroyGL
{
    [EAGLContext setCurrentContext:self.context];
    
    glDeleteProgram(self.imageFilterProgram);
    self.imageFilterProgram = 0;
    
    glDeleteBuffers(1, &_imageQuadVertexBuffer);
    self.imageQuadVertexBuffer = 0;
}

- (GLuint)createShaderFromFile:(NSString *)filename type:(GLenum)type 
{
    GLuint shader = glCreateShader(type);
    
    if (shader == 0) {
        return 0;
    }
    
    NSString *path = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:filename];
    NSString *shaderString = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    const GLchar *shaderSource = [shaderString cStringUsingEncoding:NSUTF8StringEncoding];
    
    glShaderSource(shader, 1, &shaderSource, NULL);
    glCompileShader(shader);
    
    GLint success = 0;
    glGetShaderiv(shader, GL_COMPILE_STATUS, &success);
    
    if (success == 0) {
        char errorMsg[2048];
        glGetShaderInfoLog(shader, sizeof(errorMsg), NULL, errorMsg);
        NSString *errorString = [NSString stringWithCString:errorMsg encoding:NSUTF8StringEncoding];
        NSLog(@"Failed to compile %@: %@", filename, errorString);
        glDeleteShader(shader);
        return 0;
    }
    
    return shader;
}

- (void)setContentMode:(UIViewContentMode)contentMode
{
    [super setContentMode:contentMode];
}

#pragma mark - GLKViewDelegate

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    [EAGLContext setCurrentContext:self.context];
    
    CGFloat r, g, b, a;
    [self.backgroundColor getRed:&r green:&g blue:&b alpha:&a];
    glClearColor(r, g, b, a);
    glClear(GL_COLOR_BUFFER_BIT);
    
    glUseProgram(self.imageFilterProgram);
    
    glBindBuffer(GL_ARRAY_BUFFER, self.imageQuadVertexBuffer);
    glVertexAttribPointer(self.positionHandle, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), (GLvoid *)offsetof(Vertex, position));
    glEnableVertexAttribArray(self.positionHandle);
    
    if (self.imageTexture != 0) {
        glVertexAttribPointer(self.texCoordHandle, 2, GL_FLOAT, GL_FALSE, sizeof(Vertex), (GLvoid *)offsetof(Vertex, texCoord));
        glEnableVertexAttribArray(self.texCoordHandle);
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D, self.imageTexture);
        glUniform1i(self.textureHandle, 0);
    }
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
#ifdef DEBUG
    GLenum error = glGetError();
    if (error != GL_NO_ERROR) {
        NSLog(@"%d", error);
    }
#endif
}

@end






















