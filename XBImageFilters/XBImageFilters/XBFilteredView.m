//
//  XBFilteredView.m
//  XBImageFilters
//
//  Created by xiss burg on 3/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XBFilteredView.h"
#import <QuartzCore/QuartzCore.h>

typedef struct {
    GLKVector3 position;
    GLKVector2 texCoord;
} Vertex;

void ImageProviderReleaseData(void *info, const void *data, size_t size);

@interface XBFilteredView ()

@property (strong, nonatomic) XBGLFramebuffer *framebuffer;
@property (strong, nonatomic) XBGLRenderbuffer *renderbuffer;

@property (assign, nonatomic) CGRect previousBounds; //used in layoutSubviews to determine whether the framebuffer should be recreated

@property (assign, nonatomic) GLuint imageQuadVertexBuffer;
@property (strong, nonatomic) XBGLTexture *mainTexture;

@property (assign, nonatomic) GLKMatrix4 contentModeTransform;

/**
 * Multi-pass filtering support.
 */
@property (strong, nonatomic) XBGLTexture *oddPassTexture;
@property (strong, nonatomic) XBGLTexture *evenPassTexture;
@property (strong, nonatomic) XBGLFramebuffer *oddPassFramebuffer;
@property (strong, nonatomic) XBGLFramebuffer *evenPassFrambuffer;
@property (strong, nonatomic) NSMutableDictionary *passTargetTextures;
@property (strong, nonatomic) NSMutableDictionary *passTargetFramebuffers;

@end

@implementation XBFilteredView

/**
 * Actual initializer. Called both in initWithFrame: when creating an instance programatically and in awakeFromNib when creating an instance
 * from a nib/storyboard.
 */
- (void)_XBFilteredViewInit
{
    self.contentScaleFactor = [[UIScreen mainScreen] scale];
    self.layer.opaque = YES;
    ((CAEAGLLayer *)self.layer).drawableProperties = @{kEAGLDrawablePropertyRetainedBacking : @YES};
    
    [self createFramebuffer];
    [self setupGL];
    self.previousBounds = self.bounds;
    
    self.passTargetFramebuffers = [[NSMutableDictionary alloc] init];
    self.passTargetTextures = [[NSMutableDictionary alloc] init];
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
    glDeleteBuffers(1, &_imageQuadVertexBuffer);
    self.imageQuadVertexBuffer = 0;
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
    
    [self refreshContentModeTransform];
    
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
    [self refreshContentModeTransform];
}

- (void)setTexCoordTransform:(GLKMatrix2)texCoordTransform
{
    _texCoordTransform = texCoordTransform;
    
    // The transform is applied only on the first program, because the next ones will already receive the image with the transform applied.
    // The transform would be applied again on each filter otherwise.
    XBGLProgram *firstProgram = self.programs[0];
    [firstProgram setValue:&_texCoordTransform forUniformNamed:@"u_texCoordTransform"];
}

- (void)setContentMode:(UIViewContentMode)contentMode
{
    [super setContentMode:contentMode];
    [self refreshContentModeTransform];
}

- (void)setPrograms:(NSArray *)programs
{
    if (programs == _programs) {
        return;
    }
    _programs = [programs copy];
    
    [self destroyEvenOddPasses];
    
    /* Create frame buffers for render to texture in multi-pass filters if necessary. If we have a single pass/fragment shader, we'll render
     * directly to the framebuffer. If we have two passes, we'll render to the evenPassFramebuffer using the original image as the filter source
     * texture and then render directly to the framebuffer using the evenPassTexture as the filter source. If we have three passes, the second
     * filter will instead render to the oddPassFramebuffer and the third/last pass will render to the framebuffer using the oddPassTexture.
     * And so on... */
    
    if (_programs.count >= 2) {
        // Two or more passes, create evenPass*
        [self setupEvenPass];
    }
    
    if (_programs.count > 2) {
        // More than two passes, create oddPass*
        [self setupOddPass];
    }
    
    for (int i = 0; i < _programs.count; ++i) {
        XBGLProgram *program = _programs[i];
        GLKMatrix4 m = GLKMatrix4Identity;
        
        if (i == _programs.count - 1) {
            m = GLKMatrix4Multiply(self.contentModeTransform, self.contentTransform);
        }
        
        [program setValue:&m forUniformNamed:@"u_contentTransform"];
        [program setValue:i == 0? &_texCoordTransform: (void *)&GLKMatrix2Identity forUniformNamed:@"u_texCoordTransform"];
        
        XBGLTexture *sourceTexture = nil;
        
        if (i == 0) { // First pass always uses the original image
            sourceTexture = self.mainTexture;
        }
        else if (self.passTargetTextures[@(i-1)] != nil) {
            sourceTexture = self.passTargetTextures[@(i-1)];
        }
        else if (i%2 == 1) { // Second pass uses the result of the first, and the first is 0, hence even
            sourceTexture = self.evenPassTexture;
        }
        else { // Third pass uses the result of the second, which is number 1, then it's odd
            sourceTexture = self.oddPassTexture;
        }
        
        [program bindSamplerNamed:@"s_texture" toXBTexture:sourceTexture unit:0];
        
        // Enable vertex position and texCoord attributes
        XBGLShaderAttribute *positionAttribute = program.attributes[@"a_position"];
        glVertexAttribPointer(positionAttribute.location, 4, GL_FLOAT, GL_FALSE, sizeof(Vertex), (GLvoid *)offsetof(Vertex, position));
        glEnableVertexAttribArray(positionAttribute.location);
        
        XBGLShaderAttribute *texCoordAttribute = program.attributes[@"a_texCoord"];
        glVertexAttribPointer(texCoordAttribute.location, 2, GL_FLOAT, GL_FALSE, sizeof(Vertex), (GLvoid *)offsetof(Vertex, texCoord));
        glEnableVertexAttribArray(texCoordAttribute.location);
    }
    [self refreshContentTransform];
}

#pragma mark - Protected Methods

- (void)_setTextureData:(GLvoid *)textureData width:(GLint)width height:(GLint)height
{
    if (width != self.mainTexture.width || height != self.mainTexture.height) {
        [self destroyEvenOddPasses];
        
        self.mainTexture = [[XBGLTexture alloc] initWithWidth:width height:height data:textureData];
        [self.mainTexture setSafeTextureParameters];
        
        // Resize the even and odd textures because their size have to match that of the mainTexture
        if (self.programs.count >= 2) {
            [self setupEvenPass];
        }
        
        if (self.programs.count > 2) {
            [self setupOddPass];
        }
        
        // Force an update on the contentTransform since it depends on the textureWidth and textureHeight
        [self refreshContentTransform];
    }
    else {
        [self _updateTextureWithData:textureData];
    }
    
    // Update the texture in the first shader
    if (self.programs.count > 0) {
        XBGLProgram *firstProgram = self.programs[0];
        [firstProgram bindSamplerNamed:@"s_texture" toXBTexture:self.mainTexture unit:0];
        
        if ([self.delegate respondsToSelector:@selector(filteredView:didChangeMainTexture:)]) {
            [self.delegate filteredView:self didChangeMainTexture:self.mainTexture];
        }
    }
}

- (void)_updateTextureWithData:(GLvoid *)textureData
{
    [self.mainTexture updateWithData:textureData];
}

- (void)_setTextureDataWithTextureCache:(CVOpenGLESTextureCacheRef)textureCache texture:(CVOpenGLESTextureRef *)texture imageBuffer:(CVImageBufferRef)imageBuffer
{
    // Compensate for padding. A small black line will be visible on the right. Also adjust the texture coordinate transform to fix this.
    size_t width = CVPixelBufferGetBytesPerRow(imageBuffer)/4;
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    
    CVReturn ret = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, textureCache, imageBuffer, NULL, GL_TEXTURE_2D, GL_RGBA, width, height, GL_BGRA, GL_UNSIGNED_BYTE, 0, texture);
    if (ret != kCVReturnSuccess) {
        NSLog(@"Error at CVOpenGLESTextureCacheCreateTextureFromImage: %d", ret);
    }
    
    glBindTexture(CVOpenGLESTextureGetTarget(*texture), CVOpenGLESTextureGetName(*texture));
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    if (width != self.mainTexture.width || height != self.mainTexture.height) {
        [self destroyEvenOddPasses];
        
        // Resize the even and odd textures because their size have to match that of the mainTexture
        if (self.programs.count >= 2) {
            [self setupEvenPass];
        }
        
        if (self.programs.count > 2) {
            [self setupOddPass];
        }
        
        // Force an update on the contentTransform since it depends on the textureWidth and textureHeight
        [self refreshContentTransform];
    }
    
    // Update the texture in the first shader
    if (self.programs.count > 0 && CVOpenGLESTextureGetName(*texture) != self.mainTexture.name) {
        GLuint name = CVOpenGLESTextureGetName(*texture);
        self.mainTexture = [[XBGLTexture alloc] initWithExistingTextureNamed:name width:self.mainTexture.width height:self.mainTexture.height];
        [self.mainTexture setSafeTextureParameters];
        XBGLProgram *firstProgram = self.programs[0];
        [firstProgram bindSamplerNamed:@"s_texture" toTextureNamed:self.mainTexture.name unit:0];
        
        if ([self.delegate respondsToSelector:@selector(filteredView:didChangeMainTexture:)]) {
            [self.delegate filteredView:self didChangeMainTexture:self.mainTexture];
        }
    }
}

- (UIImage *)_filteredImageWithTextureCache:(CVOpenGLESTextureCacheRef)textureCache imageBuffer:(CVImageBufferRef)imageBuffer targetWidth:(GLint)targetWidth targetHeight:(GLint)targetHeight contentTransform:(GLKMatrix4)contentTransform
{
    size_t textureWidth = CVPixelBufferGetBytesPerRow(imageBuffer)/4;
    size_t textureHeight = CVPixelBufferGetHeight(imageBuffer);
    
    float ratio = (float)CVPixelBufferGetWidth(imageBuffer)/textureWidth;
    GLKMatrix2 texCoordTransform = (GLKMatrix2){ratio, 0, 0, 1};
    
    CVOpenGLESTextureRef texture;
    CVReturn ret = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, textureCache, imageBuffer, NULL, GL_TEXTURE_2D, GL_RGBA, textureWidth, textureHeight, GL_BGRA, GL_UNSIGNED_BYTE, 0, &texture);
    if (ret != kCVReturnSuccess) {
        NSLog(@"Error at CVOpenGLESTextureCacheCreateTextureFromImage: %d", ret);
    }
    
    glBindTexture(CVOpenGLESTextureGetTarget(texture), CVOpenGLESTextureGetName(texture));
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    GLuint mainTexture = CVOpenGLESTextureGetName(texture);
    
    return [self _filteredImageWithTexture:mainTexture textureWidth:textureWidth textureHeight:textureHeight targetWidth:targetWidth targetHeight:targetHeight contentTransform:contentTransform texCoordTransform:texCoordTransform textureReleaseBlock:^{
        CFRelease(texture);
        CVOpenGLESTextureCacheFlush(textureCache, 0);
    }];
}

- (UIImage *)_filteredImageWithData:(GLvoid *)data textureWidth:(GLint)textureWidth textureHeight:(GLint)textureHeight targetWidth:(GLint)targetWidth targetHeight:(GLint)targetHeight contentTransform:(GLKMatrix4)contentTransform
{
    __block XBGLTexture *mainTexture = [[XBGLTexture alloc] initWithWidth:textureWidth height:textureHeight data:data];
    
    return [self _filteredImageWithTexture:mainTexture.name textureWidth:textureWidth textureHeight:textureHeight targetWidth:targetWidth targetHeight:targetHeight contentTransform:contentTransform texCoordTransform:GLKMatrix2Identity textureReleaseBlock:^{
        mainTexture = nil;
    }];
}

- (UIImage *)_filteredImageWithTexture:(GLuint)texture textureWidth:(GLint)textureWidth textureHeight:(GLint)textureHeight targetWidth:(GLint)targetWidth targetHeight:(GLint)targetHeight contentTransform:(GLKMatrix4)contentTransform texCoordTransform:(GLKMatrix2)texCoordTransform textureReleaseBlock:(void (^)(void))textureRelease
{
    GLKMatrix2 oldTexCoordTransform = self.texCoordTransform;
    self.texCoordTransform = texCoordTransform;
    GLKMatrix4 oldContentTransform = self.contentTransform;
    self.contentTransform = contentTransform;
    UIViewContentMode oldContentMode = self.contentMode;
    self.contentMode = UIViewContentModeScaleToFill;
    
    XBGLTexture *evenPassTexture = [[XBGLTexture alloc] initWithWidth:targetWidth height:targetHeight data:NULL];
    XBGLFramebuffer *evenPassFramebuffer = [[XBGLFramebuffer alloc] initWithTexture:evenPassTexture];
    XBGLTexture *oddPassTexture = nil;
    XBGLFramebuffer *oddPassFramebuffer = nil;
    
    if (self.programs.count > 1) {
        oddPassTexture = [[XBGLTexture alloc] initWithWidth:targetWidth height:targetHeight data:NULL];
        oddPassFramebuffer = [[XBGLFramebuffer alloc] initWithTexture:evenPassTexture];
    }
    
    XBGLFramebuffer *lastFramebuffer = 0;
    
    [XBGLEngine sharedEngine].viewportRect = CGRectMake(0, 0, targetWidth, targetHeight);
    
    for (int pass = 0; pass < self.programs.count; ++pass) {
        XBGLProgram *program = self.programs[pass];
        
        if (pass%2 == 0) {
            [[XBGLEngine sharedEngine] bindFramebuffer:evenPassFramebuffer.name];
            lastFramebuffer = evenPassFramebuffer;
        }
        else {
            [[XBGLEngine sharedEngine] bindFramebuffer:oddPassFramebuffer.name];
            lastFramebuffer = oddPassFramebuffer;
        }
        
        // Change the source texture for each pass
        GLuint sourceTexture = 0;
        
        if (pass == 0) { // First pass always uses the original image
            sourceTexture = texture;
        }
        else if (pass%2 == 1) { // Second pass uses the result of the first, and the first is 0, hence even
            sourceTexture = evenPassTexture.name;
        }
        else { // Third pass uses the result of the second, which is number 1, then it's odd
            sourceTexture = oddPassTexture.name;
        }
        
        [program bindSamplerNamed:@"s_texture" toTextureNamed:sourceTexture unit:0];
        
        [XBGLEngine sharedEngine].clearColor = self.backgroundColor;
        glClear(GL_COLOR_BUFFER_BIT);
        
        [program prepareToDraw];
        
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
        
        // If it is not the last pass, discard the framebuffer contents
        if (pass != self.programs.count - 1) {
            const GLenum discards[] = {GL_COLOR_ATTACHMENT0};
            glDiscardFramebufferEXT(GL_FRAMEBUFFER, 1, discards);
        }
    }
    
    glFlush();
    
    // Delete all this unnecessary stuff before _imageFromFramebuffer which is resource hungry.
    if (textureRelease != nil) {
        textureRelease();
    }
    
    if (lastFramebuffer == evenPassFramebuffer) {
        oddPassTexture = nil;
        oddPassFramebuffer = nil;
    }
    else if (lastFramebuffer == oddPassFramebuffer) {
        evenPassTexture = nil;
        evenPassFramebuffer = nil;
    }
    
    UIImage *image = [self _imageFromFramebuffer:lastFramebuffer.name width:targetWidth height:targetHeight orientation:UIImageOrientationUp];
    
    oddPassTexture = evenPassTexture = nil;
    oddPassFramebuffer = evenPassFramebuffer = nil;
    
    // Reset texture bindings
    for (int pass = 0; pass < self.programs.count; ++pass) {
        XBGLProgram *program = self.programs[pass];
        GLuint sourceTexture = 0;
        
        if (pass == 0) { // First pass always uses the original image
            sourceTexture = self.mainTexture.name;
        }
        else if (pass%2 == 1) { // Second pass uses the result of the first, and the first is 0, hence even
            sourceTexture = self.evenPassTexture.name;
        }
        else { // Third pass uses the result of the second, which is number 1, then it's odd
            sourceTexture = self.oddPassTexture.name;
        }
        
        [program bindSamplerNamed:@"s_texture" toTextureNamed:sourceTexture unit:0];
    }
    
    [XBGLEngine sharedEngine].viewportRect = CGRectMake(0, 0, self.renderbuffer.size.width, self.renderbuffer.size.height);
    [[XBGLEngine sharedEngine] bindFramebuffer:self.framebuffer.name];
    self.texCoordTransform = oldTexCoordTransform;
    self.contentTransform = oldContentTransform;
    self.contentMode = oldContentMode;
    
#ifdef DEBUG
    GLenum error = glGetError();
    if (error != GL_NO_ERROR) {
        NSLog(@"%d", error);
    }
#endif
    
    return image;
}

- (UIImage *)_imageFromFramebuffer:(GLuint)framebuffer width:(GLint)width height:(GLint)height orientation:(UIImageOrientation)orientation
{
    GLvoid *pixels = [[XBGLEngine sharedEngine] dataFromFramebuffer:framebuffer width:width height:height];
    return [self _imageWithData:pixels width:width height:height orientation:orientation ownsData:YES];
}

- (UIImage *)_imageWithData:(void *)data width:(GLint)width height:(GLint)height orientation:(UIImageOrientation)orientation ownsData:(BOOL)ownsData
{
    size_t size = width * height * 4;
    size_t bitsPerComponent = 8;
    size_t bitsPerPixel = 32;
    size_t bytesPerRow = width * bitsPerPixel / bitsPerComponent;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault;
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, data, size, ownsData? ImageProviderReleaseData: NULL);
    CGImageRef cgImage = CGImageCreate(width, height, bitsPerComponent, bitsPerPixel, bytesPerRow, colorSpace, bitmapInfo, provider, NULL, FALSE, kCGRenderingIntentDefault);
    CGDataProviderRelease(provider);
    
    UIImage *image = [UIImage imageWithCGImage:cgImage scale:self.contentScaleFactor orientation:orientation];
    CGImageRelease(cgImage);
    CGColorSpaceRelease(colorSpace);
    
    return image;
}

- (void)_deleteMainTexture
{
    self.mainTexture = nil;
}

#pragma mark - Public Methods

- (BOOL)setFilterFragmentShaderFromFile:(NSString *)path error:(NSError *__autoreleasing *)error
{
    NSArray *paths = [[NSArray alloc] initWithObjects:path, nil];
    return [self setFilterFragmentShadersFromFiles:paths error:error];
}

- (BOOL)setFilterFragmentShadersFromFiles:(NSArray *)paths error:(NSError *__autoreleasing *)error
{
    return [self setFilterFragmentShaderPaths:paths error:error];
}

- (BOOL)setFilterFragmentShaderPath:(NSString *)fsPath error:(NSError *__autoreleasing *)error
{
    NSString *fsSource = [[NSString alloc] initWithContentsOfFile:fsPath encoding:NSUTF8StringEncoding error:error];
    if (fsSource == nil) {
        return NO;
    }
    
    return [self setFilterFragmentShaderSource:fsSource error:error];
}

- (BOOL)setFilterFragmentShaderPaths:(NSArray *)fsPaths error:(NSError *__autoreleasing *)error
{
    NSMutableArray *fsSources = [[NSMutableArray alloc] initWithCapacity:fsPaths.count];
    for (NSString *fsPath in fsPaths) {
        NSString *fsSource = [[NSString alloc] initWithContentsOfFile:fsPath encoding:NSUTF8StringEncoding error:error];
        if (fsSource == nil) {
            return NO;
        }
        [fsSources addObject:fsSource];
    }
    
    return [self setFilterFragmentShaderSources:fsSources error:error];
}

- (BOOL)setFilterFragmentShaderSource:(NSString *)fsSource error:(NSError *__autoreleasing *)error
{
    return [self setFilterFragmentShaderSources:@[fsSource] error:error];
}

- (BOOL)setFilterFragmentShaderSources:(NSArray *)fsSources error:(NSError *__autoreleasing *)error
{
    NSString *defaultVertexShaderPath = [[NSBundle mainBundle] pathForResource:@"Default" ofType:@"vsh"];
    NSString *defaultVertexShaderSource = [[NSString alloc] initWithContentsOfFile:defaultVertexShaderPath encoding:NSUTF8StringEncoding error:error];
    if (defaultVertexShaderSource == nil) {
        return NO;
    }
    
    NSMutableArray *vsSources = [[NSMutableArray alloc] initWithCapacity:fsSources.count];
    for (int i = 0; i < fsSources.count; ++i) {
        [vsSources addObject:defaultVertexShaderSource];
    }
    
    return [self setFilterFragmentShaderSources:fsSources vertexShaderSources:vsSources error:error];
}

- (BOOL)setFilterFragmentShaderPath:(NSString *)fsPath vertexShaderPath:(NSString *)vsPath error:(NSError *__autoreleasing *)error
{
    return [self setFilterFragmentShaderPaths:@[fsPath] vertexShaderPaths:@[vsPath] error:error];
}

- (BOOL)setFilterFragmentShaderPaths:(NSArray *)fsPaths vertexShaderPaths:(NSArray *)vsPaths error:(NSError *__autoreleasing *)error
{
    NSMutableArray *fsSources = [[NSMutableArray alloc] initWithCapacity:fsPaths.count];
    NSMutableArray *vsSources = [[NSMutableArray alloc] initWithCapacity:vsPaths.count];
    for (int i = 0; i < fsPaths.count; ++i) {
        NSString *fsSource = [[NSString alloc] initWithContentsOfFile:fsPaths[i] encoding:NSUTF8StringEncoding error:error];
        NSString *vsSource = [[NSString alloc] initWithContentsOfFile:vsPaths[i] encoding:NSUTF8StringEncoding error:error];
        if (fsSource == nil || vsSource == nil) {
            return NO;
        }
        [fsSources addObject:fsSource];
        [vsSources addObject:vsSource];
    }
    
    return [self setFilterFragmentShaderSources:fsSources vertexShaderSources:vsSources error:error];
}

- (BOOL)setFilterFragmentShaderSource:(NSString *)fsSource vertexShaderSource:(NSString *)vsSource error:(NSError *__autoreleasing *)error
{
    return [self setFilterFragmentShaderSources:@[fsSource] vertexShaderSources:@[vsSource] error:error];
}

- (BOOL)setFilterFragmentShaderSources:(NSArray *)fsSources vertexShaderSources:(NSArray *)vsSources error:(NSError *__autoreleasing *)error
{
    NSMutableArray *programs = [[NSMutableArray alloc] initWithCapacity:fsSources.count];
    for (int i = 0; i < fsSources.count; ++i) {
        NSString *fsSource = fsSources[i];
        NSString *vsSource = vsSources[i];
        XBGLProgram *program = [[XBGLProgram alloc] initWithVertexShaderSource:vsSource fragmentShaderSource:fsSource error:error];
        if (program == nil) {
            return NO;
        }
        [programs addObject:program];
    }
    
    self.programs = programs;
    
    return YES;
}

- (XBGLTexture *)createTargetTextureForPass:(NSUInteger)pass
{
    XBGLTexture *texture = [[XBGLTexture alloc] initWithWidth:self.renderbuffer.size.width height:self.renderbuffer.size.height data:NULL];
    [texture setSafeTextureParameters];
    
    XBGLFramebuffer *framebuffer = [[XBGLFramebuffer alloc] initWithTexture:texture];
    self.passTargetTextures[@(pass)] = texture;
    self.passTargetFramebuffers[@(pass)] = framebuffer;
    
    XBGLProgram *program = self.programs[pass + 1];
    [program bindSamplerNamed:@"s_texture" toXBTexture:texture unit:0];
    
    return texture;
}

- (void)destroyTargetTextureForPass:(NSUInteger)pass
{
    [self.passTargetTextures removeObjectForKey:@(pass)];
    [self.passTargetFramebuffers removeObjectForKey:@(pass)];
}

- (void)setDefaultFilter
{
    self.programs = @[[XBGLProgram defaultProgram]];
}

- (UIImage *)takeScreenshot
{
    return [self takeScreenshotWithImageOrientation:UIImageOrientationDownMirrored];
}

- (UIImage *)takeScreenshotWithImageOrientation:(UIImageOrientation)orientation
{
    int width = (int)(self.bounds.size.width * self.contentScaleFactor);
    int height = (int)(self.bounds.size.height * self.contentScaleFactor);
    return [self _imageFromFramebuffer:self.framebuffer.name width:width height:height orientation:orientation];
}

- (UIImage *)filteredImage
{
    GLKMatrix4 contentTransform = GLKMatrix4MakeScale(1, -1, 1);
    return [self _filteredImageWithTexture:self.mainTexture.name textureWidth:self.renderbuffer.size.width textureHeight:self.renderbuffer.size.height targetWidth:self.renderbuffer.size.width targetHeight:self.renderbuffer.size.height contentTransform:contentTransform texCoordTransform:GLKMatrix2Identity textureReleaseBlock:nil];
}

- (void)display
{
    [self displayWithFramebuffer:self.framebuffer.name width:self.renderbuffer.size.width height:self.renderbuffer.size.height present:YES];
}

- (void)displayWithFramebuffer:(GLuint)framebuffer width:(GLsizei)width height:(GLsizei)height present:(BOOL)present
{
    for (NSUInteger pass = 0; pass < self.programs.count; ++pass) {
        XBGLProgram *program = self.programs[pass];
        
        if (self.programs.count > 1) {
            if (pass == self.programs.count - 1) { // Last pass, bind screen framebuffer
                [XBGLEngine sharedEngine].viewportRect = CGRectMake(0, 0, width, height);
                [[XBGLEngine sharedEngine] bindFramebuffer:framebuffer];
            }
            else if (self.passTargetFramebuffers[@(pass)] != nil) {
                [XBGLEngine sharedEngine].viewportRect = CGRectMake(0, 0, self.mainTexture.width, self.mainTexture.height);
                XBGLFramebuffer *passFramebuffer = self.passTargetFramebuffers[@(pass)];
                [[XBGLEngine sharedEngine] bindFramebuffer:passFramebuffer.name];
            }
            else if (pass%2 == 0) {
                [XBGLEngine sharedEngine].viewportRect = CGRectMake(0, 0, self.mainTexture.width, self.mainTexture.height);
                [[XBGLEngine sharedEngine] bindFramebuffer:self.evenPassFrambuffer.name];
            }
            else {
                [XBGLEngine sharedEngine].viewportRect = CGRectMake(0, 0, self.mainTexture.width, self.mainTexture.height);
                [[XBGLEngine sharedEngine] bindFramebuffer:self.oddPassFramebuffer.name];
            }
        }
        else {
            [XBGLEngine sharedEngine].viewportRect = CGRectMake(0, 0, width, height);
            [[XBGLEngine sharedEngine] bindFramebuffer:framebuffer];
        }
        
        [XBGLEngine sharedEngine].clearColor = self.backgroundColor;
        glClear(GL_COLOR_BUFFER_BIT);
        
        [program prepareToDraw];
        
        glBindBuffer(GL_ARRAY_BUFFER, self.imageQuadVertexBuffer);
        XBGLShaderAttribute *positionAttribute = program.attributes[@"a_position"];
        glVertexAttribPointer(positionAttribute.location, 4, GL_FLOAT, GL_FALSE, sizeof(Vertex), (GLvoid *)offsetof(Vertex, position));
        glEnableVertexAttribArray(positionAttribute.location);
        
        XBGLShaderAttribute *texCoordAttribute = program.attributes[@"a_texCoord"];
        glVertexAttribPointer(texCoordAttribute.location, 2, GL_FLOAT, GL_FALSE, sizeof(Vertex), (GLvoid *)offsetof(Vertex, texCoord));
        glEnableVertexAttribArray(texCoordAttribute.location);
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
        /*
        // If it is not the last pass, discard the framebuffer contents
        if (pass != self.programs.count - 1) {
            const GLenum discards[] = {GL_COLOR_ATTACHMENT0};
            glDiscardFramebufferEXT(GL_FRAMEBUFFER, 1, discards);
        }*/
    }
    
    if (present) {
        [XBGLEngine.sharedEngine.context presentRenderbuffer:GL_RENDERBUFFER];
    }
    
#ifdef DEBUG
    GLenum error = glGetError();
    if (error != GL_NO_ERROR) {
        NSLog(@"OpenGL error: 0x%x", error);
    }
#endif
}

#pragma mark - Private Methods

- (void)setupGL
{
    [XBGLEngine sharedEngine].depthTestEnabled = NO;
    
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
    [self setDefaultFilter];
    
    // Initialize transform to the most basic projection, and set others to identity
    self.contentModeTransform = GLKMatrix4MakeOrtho(-1.f, 1.f, -1.f, 1.f, -1.f, 1.f);
    self.contentTransform = GLKMatrix4Identity;
    self.texCoordTransform = GLKMatrix2Identity;
    
    glActiveTexture(GL_TEXTURE0);
}

- (void)setupEvenPass
{
    self.evenPassTexture = [[XBGLTexture alloc] initWithWidth:self.mainTexture.width height:self.mainTexture.height data:NULL];
    [self.evenPassTexture setSafeTextureParameters];
    self.evenPassFrambuffer = [[XBGLFramebuffer alloc] initWithTexture:self.evenPassTexture];
}

- (void)setupOddPass
{
    self.oddPassTexture = [[XBGLTexture alloc] initWithWidth:self.mainTexture.width height:self.mainTexture.height data:NULL];
    [self.oddPassTexture setSafeTextureParameters];
    self.oddPassFramebuffer = [[XBGLFramebuffer alloc] initWithTexture:self.oddPassTexture];
}

- (void)destroyEvenOddPasses
{
    self.evenPassTexture = nil;
    self.evenPassFrambuffer = nil;
    self.oddPassTexture = nil;
    self.oddPassFramebuffer = nil;
}

- (void)refreshContentTransform
{
    GLKMatrix4 composedTransform = GLKMatrix4Multiply(self.contentTransform, self.contentModeTransform);
    
    // The contentTransform is only applied on the last program otherwise it would be reapplied in each filter. Also, the contentTransform's
    // purpose is to adjust the final image on the framebuffer/screen. That is why it is applied only in the end.
    XBGLProgram *lastProgram = [self.programs lastObject];
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
    self.renderbuffer = [[XBGLRenderbuffer alloc] init];
    [self.renderbuffer storageFromGLLayer:(CAEAGLLayer *)self.layer];
    self.framebuffer = [[XBGLFramebuffer alloc] initWithRenderbuffer:self.renderbuffer];
    
    XBGLFramebufferStatus status = self.framebuffer.status;
    if (status != XBGLFramebufferStatusComplete) {
        NSLog(@"Failed to create framebuffer: %@", NSStringFromFramebufferStatus(status));
        return NO;
    }
    
    [XBGLEngine sharedEngine].viewportRect = CGRectMake(0, 0, self.renderbuffer.size.width, self.renderbuffer.size.height);
    
    return YES;
}

- (void)refreshContentModeTransform
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
}

@end

void ImageProviderReleaseData(void *info, const void *data, size_t size)
{
    free((void *)data);
}
