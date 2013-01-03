//
//  XBGLRenderbuffer.m
//  XBImageFilters
//
//  Created by xissburg on 11/5/12.
//
//

#import "XBGLRenderbuffer.h"
#import "XBGLEngine.h"
#import <QuartzCore/QuartzCore.h>

@implementation XBGLRenderbuffer

- (id)init
{
    self = [super init];
    if (self) {
        _name = [[XBGLEngine sharedEngine] createRenderbuffer];
    }
    return self;
}

- (void)dealloc
{
    [[XBGLEngine sharedEngine] deleteRenderbuffer:self.name];
}

#pragma mark - Methods

- (void)storageFromGLLayer:(CAEAGLLayer *)layer
{
    _size = [[XBGLEngine sharedEngine] storageForRenderbuffer:self.name fromDrawable:layer];
}

@end
