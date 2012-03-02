//
//  XBFilteredImageView.m
//  XBImageFilters
//
//  Created by xiss burg on 2/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XBFilteredImageView.h"

@interface XBFilteredImageView ()


@end

@implementation XBFilteredImageView

@synthesize image = _image;

#pragma mark - Properties

- (void)setImage:(UIImage *)image
{
    _image = image;
    
    if (_image == nil) {
        [self _deleteMainTexture];
        return;
    }
    
    int width = CGImageGetWidth(image.CGImage);
    int height = CGImageGetHeight(image.CGImage);
    
    CGSize imageSize = CGSizeMake(width/self.contentScaleFactor, height/self.contentScaleFactor);
    UIGraphicsBeginImageContextWithOptions(imageSize, NO, self.contentScaleFactor);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextScaleCTM(context, 1.f/self.contentScaleFactor, 1.f/self.contentScaleFactor);
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), image.CGImage);
    GLubyte *textureData = (GLubyte *)CGBitmapContextGetData(context);
    
    [self _setTextureData:textureData width:width height:height];
    
    UIGraphicsEndImageContext();
}

@end
