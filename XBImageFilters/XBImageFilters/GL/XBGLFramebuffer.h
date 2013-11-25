//
//  XBGLFramebuffer.h
//  XBImageFilters
//
//  Created by xissburg on 11/5/12.
//
//

#import <Foundation/Foundation.h>
#import "XBGLRenderbuffer.h"
#import "XBGLTexture.h"

@interface XBGLFramebuffer : NSObject

@property (nonatomic, readonly) GLuint name;
@property (nonatomic, readonly) id attachment;
@property (nonatomic, readonly) XBGLFramebufferStatus status;

- (id)initWithTexture:(XBGLTexture *)texture;
- (id)initWithRenderbuffer:(XBGLRenderbuffer *)renderbuffer;
- (void)attachTexture:(XBGLTexture *)texture;
- (void)attachRenderbuffer:(XBGLRenderbuffer *)renderbuffer;

@end
