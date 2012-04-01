//
//  UIImage+Lut.m
//  SubtleWebView
//
//  Created by Dirk-Willem van Gulik on 27-03-12.
//  Copyright (c) 2012 webWeaving.org. All rights reserved.
//

#import "UIImage+XBImageFilters.h"

#import "XBFilteredImageView.h"
#import "GLKProgram.h"

@implementation UIImage (UIImagePlusXBImageFilters)

-(UIImage *)imageByApplyingShaders:(NSArray *)paths
{
    NSError * error;
    UIImage * img = [self imageByApplyingShaders:paths error:&error];
    
    if (error) {
        NSLog(@"Shader compile of %@ failed with error: %@", paths, error);
        return nil;
    };
    
    return img;
}

-(UIImage *)imageByApplyingShaders:(NSArray *)paths error:(NSError **)errorPtr
{
    int pixelsWide = self.size.width;
	int pixelsHigh = self.size.height;

    XBFilteredImageView *filteredImageView = [[XBFilteredImageView alloc] initWithFrame:CGRectMake(0,0,pixelsWide, pixelsHigh)];
    [filteredImageView setContentSize:CGSizeMake(pixelsWide, pixelsHigh)];
    
    [filteredImageView setFilterFragmentShadersFromFiles:paths error:errorPtr];
    
    filteredImageView.image = self;
    [filteredImageView forceDisplay];

    return [filteredImageView takeScreenshotWithImageOrientation:UIImageOrientationDownMirrored];
}
@end
