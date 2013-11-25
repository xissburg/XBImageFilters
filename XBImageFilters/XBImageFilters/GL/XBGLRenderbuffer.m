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
    [[XBGLEngine sharedEngine] storageForRenderbuffer:self.name fromDrawable:nil];
    [[XBGLEngine sharedEngine] deleteRenderbuffer:self.name];
}

#pragma mark - Methods

- (BOOL)storageFromGLLayer:(CAEAGLLayer *)layer
{
    if (![[XBGLEngine sharedEngine] storageForRenderbuffer:self.name fromDrawable:layer]) {
        return NO;
    }
    _size = [[XBGLEngine sharedEngine] sizeForRenderbuffer:self.name];
    return YES;
}

@end
