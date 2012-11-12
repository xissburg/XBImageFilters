//
//  XBGLEngine.h
//  XBImageFilters
//
//  Created by xissburg on 11/2/12.
//
//

#import <Foundation/Foundation.h>
#import "XBGLShaderAttribute.h"
#import "XBGLShaderUniform.h"
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
- (void)deleteProgram:(GLuint)program;
- (void)useProgram:(GLuint)program;
- (NSDictionary *)uniformsForProgram:(GLuint)program;
- (NSDictionary *)attributesForProgram:(GLuint)program;
- (void)flushUniform:(XBGLShaderUniform *)uniform;
- (GLuint)createRenderbuffer;
- (void)deleteRenderbuffer:(GLuint)renderbuffer;
- (void)bindRenderbuffer:(GLuint)renderbuffer;
- (CGSize)storageForRenderbuffer:(GLuint)renderbuffer fromDrawable:(id<EAGLDrawable>)drawable;
- (GLuint)createFramebuffer;
- (void)deleteFramebuffer:(GLuint)framebuffer;
- (void)bindFramebuffer:(GLuint)framebuffer;
- (XBGLFramebufferStatus)statusForFramebuffer:(GLuint)framebuffer;
- (void)attachRenderbuffer:(GLuint)renderbuffer toFramebuffer:(GLuint)framebuffer attachment:(XBGLAttachment)attachment;
- (void)attachTexture:(GLuint)texture toFramebuffer:(GLuint)framebuffer attachment:(XBGLAttachment)attachment;

+ (XBGLEngine *)sharedInstance;

/*
 * Returns an string containing memory usage information.
 */
+ (NSString *)memoryStatus;

@end
