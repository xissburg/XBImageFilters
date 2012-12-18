//
//  UIImage+Lut.h
//  SubtleWebView
//
//  Created by Dirk-Willem van Gulik on 27-03-12.
//  Copyright (c) 2012 webWeaving.org. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (UIImagePlusXBImageFilters)

- (UIImage *)imageByApplyingShaders:(NSArray *)paths;
- (UIImage *)imageByApplyingShaders:(NSArray *)paths error:(NSError **)error;

@end
