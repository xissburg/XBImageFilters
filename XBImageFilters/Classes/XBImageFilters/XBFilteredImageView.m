//
//  XBFilteredImageView.m
//  XBImageFilters
//
//  Created by xiss burg on 2/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XBFilteredImageView.h"

@interface XBFilteredImageView ()

@property (strong, nonatomic) EAGLContext *context;
@property (strong, nonatomic) GLKView *glkView;

@end

@implementation XBFilteredImageView

@synthesize context = _context;
@synthesize glkView = _glkView;

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

#pragma mark - GLKViewDelegate

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    [EAGLContext setCurrentContext:self.context];
    
    glClearColor(0.5, 0, 0.5, 1);
    glClear(GL_COLOR_BUFFER_BIT);
}

@end
