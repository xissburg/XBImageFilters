//
//  XBGLFramebuffer.m
//  XBImageFilters
//
//  Created by xissburg on 11/5/12.
//
//

#import "XBGLFramebuffer.h"
#import "XBGLEngine.h"

@implementation XBGLFramebuffer

- (id)init
{
    self = [super init];
    if (self) {
        _name = [[XBGLEngine sharedInstance] createFramebuffer];
    }
    return self;
}

- (void)dealloc
{
    [[XBGLEngine sharedInstance] deleteFramebuffer:self.name];
}

#pragma mark - Methods

- (void)attachRenderbuffer:(XBGLRenderbuffer *)renderbuffer
{
    [[XBGLEngine sharedInstance] attachRenderbuffer:renderbuffer.name toFramebuffer:self.name attachment:XBGLAttachmentColor0];
    _attachment = renderbuffer;
}

- (void)attachTexture:(XBGLTexture *)texture
{
    [[XBGLEngine sharedInstance] attachTexture:texture.name toFramebuffer:self.name attachment:XBGLAttachmentColor0];
    _attachment = texture;
}

- (XBGLFramebufferStatus)status
{
    return [[XBGLEngine sharedInstance] statusForFramebuffer:self.name];
}

@end
