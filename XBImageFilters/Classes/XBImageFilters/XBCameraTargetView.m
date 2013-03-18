//
//  CameraTargetView.m
//  XBImageFilters
//
//  Created by xiss burg on 4/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XBCameraTargetView.h"
#import <QuartzCore/QuartzCore.h>

@implementation XBCameraTargetView

- (void)_CameraTargetViewCommonInit
{
    _visible = YES;
    self.clipsToBounds = NO;
    self.userInteractionEnabled = NO;
    self.backgroundColor = [UIColor clearColor];
    self.layer.shadowColor = [UIColor colorWithRed:0.04 green:0.21 blue:0.48 alpha:1].CGColor;
    self.layer.shadowOffset = CGSizeZero;
    self.layer.shadowOpacity = 1;
    self.layer.shadowRadius = 2;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self _CameraTargetViewCommonInit];
    }
    return self;
}

- (void)awakeFromNib
{
    [self _CameraTargetViewCommonInit];
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    
    CGContextSetStrokeColorWithColor(context, [UIColor whiteColor].CGColor);
    UIBezierPath *roundedRect = [UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:8];
    [roundedRect stroke];
    
    CGFloat innerLineLength = 6;
    
    CGContextMoveToPoint(context, rect.origin.x, rect.origin.y + rect.size.height/2);
    CGContextAddLineToPoint(context, rect.origin.x + innerLineLength, rect.origin.y + rect.size.height/2);
    
    CGContextMoveToPoint(context, rect.origin.x + rect.size.width, rect.origin.y + rect.size.height/2);
    CGContextAddLineToPoint(context, rect.origin.x + rect.size.width - innerLineLength, rect.origin.y + rect.size.height/2);
    
    CGContextMoveToPoint(context, rect.origin.x + rect.size.width/2, rect.origin.y);
    CGContextAddLineToPoint(context, rect.origin.x + rect.size.width/2, rect.origin.y + innerLineLength);
    
    CGContextMoveToPoint(context, rect.origin.x + rect.size.width/2, rect.origin.y + rect.size.height);
    CGContextAddLineToPoint(context, rect.origin.x + rect.size.width/2, rect.origin.y + rect.size.height - innerLineLength);
    
    CGContextStrokePath(context);

    CGContextRestoreGState(context);
}

- (void)setVisible:(BOOL)visible animated:(BOOL)animated;
{
    if (visible == _visible) {
        return;
    }
    
    _visible = visible;
    
    if (animated) {
        if (visible) {
            self.transform = CGAffineTransformMakeScale(2, 2);
            self.alpha = 0;
            [UIView animateWithDuration:0.3 animations:^{
                self.transform = CGAffineTransformMakeScale(1, 1);
                self.alpha = 1;
            }];
        }
        else {
            [UIView animateWithDuration:0.3 animations:^{
                self.alpha = 0;
            }];
        }
    }
    else {
        self.alpha = visible? 1: 0;
    }
}

@end
