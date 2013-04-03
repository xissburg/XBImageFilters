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
    
    // Create an RGBA bitmap context
    CGImageRef CGImage = image.CGImage;
    size_t width = CGImageGetWidth(CGImage);
    size_t height = CGImageGetHeight(CGImage);
    size_t bitsPerComponent = 8;
    size_t bytesPerRow = width * 4;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(NULL, width, height, bitsPerComponent, bytesPerRow, colorSpace, kCGImageAlphaPremultipliedFirst|kCGBitmapByteOrder32Little);
    // Invert vertically for OpenGL
    CGContextTranslateCTM(context, 0, height);
    CGContextScaleCTM(context, 1, -1); 
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), CGImage);
    GLubyte *textureData = (GLubyte *)CGBitmapContextGetData(context);
    
    [self setContentSize:CGSizeMake(width, height)];
    [self _setTextureData:textureData width:width height:height];
    
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
}

@end
