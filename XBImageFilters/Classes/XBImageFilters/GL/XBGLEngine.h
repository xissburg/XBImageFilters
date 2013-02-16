//
//  XBGLEngine.h
//  XBImageFilters
//
//  Created by xissburg on 11/2/12.
//
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#import <QuartzCore/QuartzCore.h>

typedef enum {
    XBGLTextureWrapModeClamp,
    XBGLTextureWrapModeRepeat,
    XBGLTextureWrapModeMirroredRepeat
} XBGLTextureWrapMode;

typedef enum {
    XBGLTextureMinFilterNearest,
    XBGLTextureMinFilterLinear,
    XBGLTextureMinFilterNearestMipmapNearest,
    XBGLTextureMinFilterLinearMipmapNearest,
    XBGLTextureMinFilterNearestMipmapLinear,
    XBGLTextureMinFilterLinearMipmapLinear
} XBGLTextureMinFilter;

typedef enum {
    XBGLTextureMagFilterNearest,
    XBGLTextureMagFilterLinear
} XBGLTextureMagFilter;

typedef enum {
    XBGLAttachmentColor0,
    XBGLAttachmentDepth,
    XBGLAttachmentStencil
} XBGLAttachment;

typedef enum {
    XBGLFramebufferStatusComplete,
    XBGLFramebufferStatusIncompleteAttachment,
    XBGLFramebufferStatusIncompleteDimensions,
    XBGLFramebufferStatusIncompleteMissingAttachment,
    XBGLFramebufferStatusUnsupported,
    XBGLFramebufferStatusUnknown
} XBGLFramebufferStatus;

typedef enum {
    XBGLProgramErrorFailedToCreateShader = 0,
    XBGLProgramErrorCompilationFailed = 1,
    XBGLProgramErrorLinkFailed = 2
} XBGLProgramError;

NSString *NSStringFromFramebufferStatus(XBGLFramebufferStatus status);

extern NSString *const XBGLProgramErrorDomain;

@interface XBGLEngine : NSObject

@property (readonly, nonatomic) EAGLContext *context;
@property (readonly, nonatomic) GLint maxTextureSize; // Maximum value for texture width and height
@property (copy, nonatomic) UIColor *clearColor;
@property (assign, nonatomic) CGRect viewportRect;
@property (assign, nonatomic) BOOL depthTestEnabled;

- (GLuint)createTextureWithWidth:(GLsizei)width height:(GLsizei)height data:(GLvoid *)data;
- (void)deleteTexture:(GLuint)texture;
- (void)setActiveTextureUnit:(GLint)unit;
- (void)bindTexture:(GLuint)texture;
- (void)bindTexture:(GLuint)texture unit:(GLint)unit;
- (void)setWrapSMode:(XBGLTextureWrapMode)wrapMode texture:(GLuint)texture;
- (void)setWrapTMode:(XBGLTextureWrapMode)wrapMode texture:(GLuint)texture;
- (void)setMagFilter:(XBGLTextureMagFilter)filter texture:(GLuint)texture;
- (void)setMinFilter:(XBGLTextureMinFilter)filter texture:(GLuint)texture;
- (GLuint)createShaderWithSource:(NSString *)sourceCode type:(GLenum)type error:(NSError *__autoreleasing *)error;
- (GLuint)createProgramWithVertexShaderSource:(NSString *)vertexShaderSource fragmentShaderSource:(NSString *)fragmentShaderSource error:(NSError *__autoreleasing *)error;
- (void)useProgram:(GLuint)program;
- (void)deleteProgram:(GLuint)program;
- (void)enumerateUniformsForProgram:(GLuint)program usingBlock:(void (^)(NSString *name, GLint location, GLint size, GLenum type))block;
- (void)enumerateAttributesForProgram:(GLuint)program usingBlock:(void (^)(NSString *name, GLint location, GLint size, GLenum type))block;
- (void)flushUniformWithLocation:(GLint)location size:(GLint)size type:(GLenum)type value:(void *)value;
- (GLuint)createRenderbuffer;
- (void)deleteRenderbuffer:(GLuint)renderbuffer;
- (void)bindRenderbuffer:(GLuint)renderbuffer;
- (BOOL)storageForRenderbuffer:(GLuint)renderbuffer fromDrawable:(id<EAGLDrawable>)drawable;
- (CGSize)sizeForRenderbuffer:(GLuint)renderbuffer;
- (GLuint)createFramebuffer;
- (void)deleteFramebuffer:(GLuint)framebuffer;
- (void)bindFramebuffer:(GLuint)framebuffer;
- (XBGLFramebufferStatus)statusForFramebuffer:(GLuint)framebuffer;
- (void)attachRenderbuffer:(GLuint)renderbuffer toFramebuffer:(GLuint)framebuffer attachment:(XBGLAttachment)attachment;
- (void)attachTexture:(GLuint)texture toFramebuffer:(GLuint)framebuffer attachment:(XBGLAttachment)attachment;

+ (XBGLEngine *)sharedEngine;

/*
 * Returns an string containing memory usage information.
 */
+ (NSString *)memoryStatus;

@end
