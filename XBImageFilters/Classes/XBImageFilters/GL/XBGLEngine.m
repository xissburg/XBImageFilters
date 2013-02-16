//
//  XBGLEngine.m
//  XBImageFilters
//
//  Created by xissburg on 11/2/12.
//
//

#import "XBGLEngine.h"
#import <mach/host_info.h>
#import <mach/mach.h>

#define kTextureUnits 32

typedef struct {
    GLKVector3 position;
    GLKVector2 texCoord;
} Vertex;

const GLKMatrix2 GLKMatrix2Identity = {1, 0, 0, 1};
GLKMatrix2 GLKMatrix2Multiply(GLKMatrix2 m0, GLKMatrix2 m1);
//void ImageProviderReleaseData(void *info, const void *data, size_t size);
float pagesToMB(int pages);


@implementation XBGLEngine {
    GLuint boundTextures[kTextureUnits];
    GLuint boundProgram;
    GLuint activeTextureUnit;
    GLuint boundRenderbuffer;
    GLuint boundFramebuffer;
}

@synthesize maxTextureSize = _maxTextureSize;
@synthesize clearColor = _clearColor;

- (id)init
{
    self = [super init];
    if (self) {
        _context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        if (!self.context || ![EAGLContext setCurrentContext:self.context]) {
            return nil;
        }
    }
    return self;
}

- (void)dealloc
{
    [EAGLContext setCurrentContext:self.context];
    _context = nil;
    [EAGLContext setCurrentContext:nil];
}

#pragma mark - Properties

- (GLint)maxTextureSize
{
    if (_maxTextureSize == 0) {
        glGetIntegerv(GL_MAX_TEXTURE_SIZE, &_maxTextureSize);
    }
    return _maxTextureSize;
}

- (UIColor *)clearColor
{
    if (_clearColor == nil) {
        GLfloat color[4];
        glGetFloatv(GL_COLOR_CLEAR_VALUE, color);
        _clearColor = [[UIColor alloc] initWithRed:color[0] green:color[1] blue:color[2] alpha:color[3]];
    }
    return _clearColor;
}

- (void)setClearColor:(UIColor *)clearColor
{
    if ([_clearColor isEqual:clearColor]) {
        return;
    }
    _clearColor = [clearColor copy];
    CGFloat r, g, b, a;
    [_clearColor getRed:&r green:&g blue:&b alpha:&a];
    glClearColor(r, g, b, a);
}

- (void)setViewportRect:(CGRect)viewportRect
{
    if (CGRectEqualToRect(viewportRect, _viewportRect)) {
        return;
    }
    
    _viewportRect = viewportRect;
    glViewport(_viewportRect.origin.x, _viewportRect.origin.y, _viewportRect.size.width, _viewportRect.size.height);
}

- (void)setDepthTestEnabled:(BOOL)depthTestEnabled
{
    if (_depthTestEnabled == depthTestEnabled) {
        return;
    }

    _depthTestEnabled = depthTestEnabled;
    if (_depthTestEnabled) {
        glEnable(GL_DEPTH_TEST);
    }
    else {
        glDisable(GL_DEPTH_TEST);
    }
}

#pragma mark - Methods

- (GLuint)createTextureWithWidth:(GLsizei)width height:(GLsizei)height data:(GLvoid *)data
{
    GLuint texture;
    glGenTextures(1, &texture);
    glBindTexture(GL_TEXTURE_2D, texture);
    boundTextures[activeTextureUnit] = texture;
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_BGRA, GL_UNSIGNED_BYTE, data);
    return texture;
}

- (void)deleteTexture:(GLuint)texture
{
    for (int i = 0; i < kTextureUnits; ++i) {
        if (boundTextures[i] == texture) {
            boundTextures[i] = 0;
        }
    }
    glDeleteTextures(1, &texture);
}

- (void)setActiveTextureUnit:(GLint)unit
{
    if (activeTextureUnit != unit) {
        glActiveTexture(GL_TEXTURE0 + unit);
        activeTextureUnit = unit;
    }
}

- (void)bindTexture:(GLuint)texture
{
    if (boundTextures[activeTextureUnit] != texture) {
        glBindTexture(GL_TEXTURE_2D, texture);
        boundTextures[activeTextureUnit] = texture;
    }
}

- (void)bindTexture:(GLuint)texture unit:(GLint)unit
{
    [self setActiveTextureUnit:unit];
    [self bindTexture:texture];
}

- (void)setWrapSMode:(XBGLTextureWrapMode)wrapMode texture:(GLuint)texture
{
    [self bindTexture:texture];
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, [self convertWrapMode:wrapMode]);
}

- (void)setWrapTMode:(XBGLTextureWrapMode)wrapMode texture:(GLuint)texture
{
    [self bindTexture:texture];
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, [self convertWrapMode:wrapMode]);
}

- (void)setMagFilter:(XBGLTextureMagFilter)filter texture:(GLuint)texture
{
    [self bindTexture:texture];
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, [self convertMagFilter:filter]);
}

- (void)setMinFilter:(XBGLTextureMinFilter)filter texture:(GLuint)texture
{
    [self bindTexture:texture];
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, [self convertMinFilter:filter]);
}

- (GLuint)createShaderWithSource:(NSString *)sourceCode type:(GLenum)type error:(NSError *__autoreleasing *)error
{
    GLuint shader = glCreateShader(type);
    
    if (shader == 0) {
        if (error != NULL) {
            NSDictionary *userInfo = [[NSDictionary alloc] initWithObjectsAndKeys:@"glCreateShader failed.", NSLocalizedDescriptionKey, nil];
            *error = [[NSError alloc] initWithDomain:XBGLProgramErrorDomain code:XBGLProgramErrorFailedToCreateShader userInfo:userInfo];
        }
        return 0;
    }
    
    const GLchar *shaderSource = [sourceCode cStringUsingEncoding:NSUTF8StringEncoding];
    
    glShaderSource(shader, 1, &shaderSource, NULL);
    glCompileShader(shader);
    
    GLint success = 0;
    glGetShaderiv(shader, GL_COMPILE_STATUS, &success);
    
    if (success == 0) {
        if (error != NULL) {
            char errorMsg[2048];
            glGetShaderInfoLog(shader, sizeof(errorMsg), NULL, errorMsg);
            NSString *errorString = [NSString stringWithCString:errorMsg encoding:NSUTF8StringEncoding];
            NSDictionary *userInfo = [[NSDictionary alloc] initWithObjectsAndKeys:errorString, NSLocalizedDescriptionKey, nil];
            *error = [[NSError alloc] initWithDomain:XBGLProgramErrorDomain code:XBGLProgramErrorCompilationFailed userInfo:userInfo];
        }
        glDeleteShader(shader);
        return 0;
    }
    
    return shader;
}

- (GLuint)createProgramWithVertexShaderSource:(NSString *)vertexShaderSource fragmentShaderSource:(NSString *)fragmentShaderSource error:(NSError *__autoreleasing *)error
{
    GLuint vertexShader = [self createShaderWithSource:vertexShaderSource type:GL_VERTEX_SHADER error:error];
    if (vertexShader == 0) {
        return 0;
    }
    
    GLuint fragmentShader = [self createShaderWithSource:fragmentShaderSource type:GL_FRAGMENT_SHADER error:error];
    if (fragmentShader == 0) {
        return 0;
    }
    
    GLuint program = glCreateProgram();
    glAttachShader(program, vertexShader);
    glAttachShader(program, fragmentShader);
    glLinkProgram(program);
    
    glDeleteShader(vertexShader);
    glDeleteShader(fragmentShader);
    
    GLint linked = 0;
    glGetProgramiv(program, GL_LINK_STATUS, &linked);
    if (linked == 0) {
        if (error != NULL) {
            char errorMsg[2048];
            glGetProgramInfoLog(program, sizeof(errorMsg), NULL, errorMsg);
            NSString *errorString = [NSString stringWithCString:errorMsg encoding:NSUTF8StringEncoding];
            NSDictionary *userInfo = [[NSDictionary alloc] initWithObjectsAndKeys:errorString, NSLocalizedDescriptionKey, nil];
            *error = [[NSError alloc] initWithDomain:XBGLProgramErrorDomain code:XBGLProgramErrorLinkFailed userInfo:userInfo];
        }
        glDeleteProgram(program);
        return 0;
    }
    
    return program;
}

- (void)useProgram:(GLuint)program
{
    if (boundProgram != program) {
        glUseProgram(program);
        boundProgram = program;
    }
}

- (void)deleteProgram:(GLuint)program
{
    if (boundProgram == program) {
        boundProgram = 0;
    }
    glDeleteProgram(program);
}

- (void)enumerateUniformsForProgram:(GLuint)program usingBlock:(void (^)(NSString *name, GLint location, GLint size, GLenum type))block
{
    GLint count;
    glGetProgramiv(program, GL_ACTIVE_UNIFORMS, &count);
    GLint maxLength;
    glGetProgramiv(program, GL_ACTIVE_UNIFORM_MAX_LENGTH, &maxLength);
    GLchar *nameBuffer = (GLchar *)malloc(maxLength * sizeof(GLchar));
    
    for (int i = 0; i < count; ++i) {
        GLint size;
        GLenum type;
        glGetActiveUniform(program, i, maxLength, NULL, &size, &type, nameBuffer);
        GLint location = glGetUniformLocation(program, nameBuffer);
        NSString *name = [[NSString alloc] initWithCString:nameBuffer encoding:NSUTF8StringEncoding];
        block(name, location, size, type);
    }
    
    free(nameBuffer);
}

- (void)enumerateAttributesForProgram:(GLuint)program usingBlock:(void (^)(NSString *name, GLint location, GLint size, GLenum type))block
{
    GLint count;
    glGetProgramiv(program, GL_ACTIVE_ATTRIBUTES, &count);
    GLint maxLength;
    glGetProgramiv(program, GL_ACTIVE_ATTRIBUTE_MAX_LENGTH, &maxLength);
    GLchar *nameBuffer = (GLchar *)malloc(maxLength * sizeof(GLchar));
    
    for (int i = 0; i < count; ++i) {
        GLint size;
        GLenum type;
        glGetActiveAttrib(program, i, maxLength, NULL, &size, &type, nameBuffer);
        GLint location = glGetAttribLocation(program, nameBuffer);
        NSString *name = [[NSString alloc] initWithCString:nameBuffer encoding:NSUTF8StringEncoding];
        block(name, location, size, type);
    }
    
    free(nameBuffer);
}

- (void)flushUniformWithLocation:(GLint)location size:(GLint)size type:(GLenum)type value:(void *)value
{
    switch (type) {
        case GL_FLOAT:
            glUniform1fv(location, size, value);
            break;
            
        case GL_FLOAT_VEC2:
            glUniform2fv(location, size, value);
            break;
            
        case GL_FLOAT_VEC3:
            glUniform3fv(location, size, value);
            break;
            
        case GL_FLOAT_VEC4:
            glUniform4fv(location, size, value);
            break;
            
        case GL_INT:
        case GL_BOOL:
            glUniform1iv(location, size, value);
            break;
            
        case GL_INT_VEC2:
        case GL_BOOL_VEC2:
            glUniform2iv(location, size, value);
            break;
            
        case GL_INT_VEC3:
        case GL_BOOL_VEC3:
            glUniform3iv(location, size, value);
            break;
            
        case GL_INT_VEC4:
        case GL_BOOL_VEC4:
            glUniform4iv(location, size, value);
            break;
            
        case GL_FLOAT_MAT2:
            glUniformMatrix2fv(location, size, GL_FALSE, value);
            break;
            
        case GL_FLOAT_MAT3:
            glUniformMatrix3fv(location, size, GL_FALSE, value);
            break;
            
        case GL_FLOAT_MAT4:
            glUniformMatrix4fv(location, size, GL_FALSE, value);
            break;
            
        case GL_SAMPLER_2D:
        case GL_SAMPLER_CUBE:
            glUniform1iv(location, size, value);
            break;
            
        default:
            break;
    }
}

- (GLuint)createRenderbuffer
{
    GLuint renderbuffer;
    glGenRenderbuffers(1, &renderbuffer);
    return renderbuffer;
}

- (void)deleteRenderbuffer:(GLuint)renderbuffer
{
    if (boundRenderbuffer == renderbuffer) {
        boundRenderbuffer = 0;
    }
    glDeleteRenderbuffers(1, &renderbuffer);
}

- (void)bindRenderbuffer:(GLuint)renderbuffer
{
    if (boundRenderbuffer != renderbuffer) {
        glBindRenderbuffer(GL_RENDERBUFFER, renderbuffer);
        boundRenderbuffer = renderbuffer;
    }
}

- (BOOL)storageForRenderbuffer:(GLuint)renderbuffer fromDrawable:(id<EAGLDrawable>)drawable
{
    [self bindRenderbuffer:renderbuffer];
    return [self.context renderbufferStorage:GL_RENDERBUFFER fromDrawable:drawable];
}

- (CGSize)sizeForRenderbuffer:(GLuint)renderbuffer
{
    [self bindRenderbuffer:renderbuffer];
    GLint width, height;
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &width);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &height);
    return CGSizeMake(width, height);
}

- (GLuint)createFramebuffer
{
    GLuint framebuffer;
    glGenFramebuffers(1, &framebuffer);
    return framebuffer;
}

- (void)deleteFramebuffer:(GLuint)framebuffer
{
    if (boundFramebuffer == framebuffer) {
        boundFramebuffer = 0;
    }
    glDeleteFramebuffers(1, &framebuffer);
}

- (void)bindFramebuffer:(GLuint)framebuffer
{
    if (boundFramebuffer != framebuffer) {
        glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
        boundFramebuffer = framebuffer;
    }
}

- (XBGLFramebufferStatus)statusForFramebuffer:(GLuint)framebuffer
{
    [self bindFramebuffer:framebuffer];
    return [self convertFramebufferStatus:glCheckFramebufferStatus(GL_FRAMEBUFFER)];
}

- (void)attachRenderbuffer:(GLuint)renderbuffer toFramebuffer:(GLuint)framebuffer attachment:(XBGLAttachment)attachment
{
    [self bindFramebuffer:framebuffer];
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, [self convertAttachment:attachment], GL_RENDERBUFFER, renderbuffer);
}

- (void)attachTexture:(GLuint)texture toFramebuffer:(GLuint)framebuffer attachment:(XBGLAttachment)attachment
{
    [self bindFramebuffer:framebuffer];
    glFramebufferTexture2D(GL_FRAMEBUFFER, [self convertAttachment:attachment], GL_TEXTURE_2D, texture, 0);
}

#pragma mark - Utility Methods

+ (NSString *)memoryStatus
{
    // Code by Noel Llopis
	vm_statistics_data_t vmStats;
	mach_msg_type_number_t infoCount = HOST_VM_INFO_COUNT;
	host_statistics(mach_host_self(), HOST_VM_INFO, (host_info_t)&vmStats, &infoCount);
    
	const int totalPages = vmStats.wire_count + vmStats.active_count + vmStats.inactive_count + vmStats.free_count;
	const int availablePages = vmStats.free_count;
	const int activePages = vmStats.active_count;
	const int wiredPages = vmStats.wire_count;
	const int purgeablePages = vmStats.purgeable_count;
    
	NSMutableString *txt = [[NSMutableString alloc] initWithCapacity:512];
	[txt appendFormat:@"\nTotal: %d (%.2fMB)", totalPages, pagesToMB(totalPages)];
	[txt appendFormat:@"\nAvailable: %d (%.2fMB)", availablePages, pagesToMB(availablePages)];
	[txt appendFormat:@"\nActive: %d (%.2fMB)", activePages, pagesToMB(activePages)];
	[txt appendFormat:@"\nWired: %d (%.2fMB)", wiredPages, pagesToMB(wiredPages)];
	[txt appendFormat:@"\nPurgeable: %d (%.2fMB)", purgeablePages, pagesToMB(purgeablePages)];
    
    return txt;
}

- (GLint)convertWrapMode:(XBGLTextureWrapMode)wrapMode
{
    switch (wrapMode) {
        case XBGLTextureWrapModeRepeat:
            return GL_REPEAT;
            
        case XBGLTextureWrapModeClamp:
            return GL_CLAMP_TO_EDGE;
            
        case XBGLTextureWrapModeMirroredRepeat:
            return GL_MIRRORED_REPEAT;
    }
}

- (GLint)convertMinFilter:(XBGLTextureMinFilter)minFilter
{
    switch (minFilter) {
        case XBGLTextureMinFilterLinear:
            return GL_LINEAR;
            
        case XBGLTextureMinFilterNearestMipmapLinear:
            return GL_NEAREST_MIPMAP_LINEAR;
            
        case XBGLTextureMinFilterNearest:
            return GL_NEAREST;
            
        case XBGLTextureMinFilterLinearMipmapLinear:
            return GL_LINEAR_MIPMAP_LINEAR;
            
        case XBGLTextureMinFilterLinearMipmapNearest:
            return GL_LINEAR_MIPMAP_NEAREST;
            
        case XBGLTextureMinFilterNearestMipmapNearest:
            return GL_NEAREST_MIPMAP_NEAREST;
    }
}

- (GLint)convertMagFilter:(XBGLTextureMagFilter)magFilter
{
    switch (magFilter) {
        case XBGLTextureMagFilterLinear:
            return GL_LINEAR;
            
        case XBGLTextureMagFilterNearest:
            return GL_NEAREST;
    }
}

- (GLenum)convertAttachment:(XBGLAttachment)attachment
{
    switch (attachment) {
        case XBGLAttachmentColor0:
            return GL_COLOR_ATTACHMENT0;
            
        case XBGLAttachmentDepth:
            return GL_DEPTH_ATTACHMENT;

        case XBGLAttachmentStencil:
            return GL_STENCIL_ATTACHMENT;
    }
}

- (XBGLFramebufferStatus)convertFramebufferStatus:(GLenum)status
{
    switch (status) {
        case GL_FRAMEBUFFER_COMPLETE:
            return XBGLFramebufferStatusComplete;
            
        case GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT:
            return XBGLFramebufferStatusIncompleteAttachment;
            
        case GL_FRAMEBUFFER_INCOMPLETE_DIMENSIONS:
            return XBGLFramebufferStatusIncompleteDimensions;
            
        case GL_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT:
            return XBGLFramebufferStatusIncompleteMissingAttachment;
            
        case GL_FRAMEBUFFER_UNSUPPORTED:
            return XBGLFramebufferStatusUnsupported;
            
        default:
            return XBGLFramebufferStatusUnknown;
    }
}

#pragma mark - Singleton

+ (XBGLEngine *)sharedEngine
{
    static XBGLEngine *engine = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        engine = [[XBGLEngine alloc] init];
    });
    return engine;
}

@end

#pragma mark - Functions
/*
void ImageProviderReleaseData(void *info, const void *data, size_t size)
{
    free((void *)data);
}*/

float pagesToMB(int pages)
{
    return pages*PAGE_SIZE/1024.f/1024.f;
}

GLKMatrix2 GLKMatrix2Multiply(GLKMatrix2 m0, GLKMatrix2 m1)
{
    GLKMatrix2 m;
    m.m00 = m0.m00*m1.m00 + m0.m01*m1.m10;
    m.m01 = m0.m00*m1.m01 + m0.m01*m1.m11;
    m.m10 = m0.m10*m1.m00 + m0.m11*m1.m10;
    m.m11 = m0.m10*m1.m01 + m0.m11*m1.m11;
    return m;
}

NSString *NSStringFromFramebufferStatus(XBGLFramebufferStatus status)
{
    switch (status) {
        case XBGLFramebufferStatusComplete:
            return @"XBGLFramebufferStatusComplete";
            
        case XBGLFramebufferStatusIncompleteAttachment:
            return @"XBGLFramebufferStatusIncompleteAttachment";
            
        case XBGLFramebufferStatusIncompleteDimensions:
            return @"XBGLFramebufferStatusIncompleteDimensions";
            
        case XBGLFramebufferStatusIncompleteMissingAttachment:
            return @"XBGLFramebufferStatusIncompleteMissingAttachment";
            
        case XBGLFramebufferStatusUnsupported:
            return @"XBGLFramebufferStatusUnsupported";
            
        default:
            return @"XBGLFramebufferStatusUnknown";
    }
}
