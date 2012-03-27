//
//  XBFilteredView.h
//  XBImageFilters
//
//  Created by xiss burg on 3/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>

@interface XBFilteredView : UIView <GLKViewDelegate>

@property (strong, nonatomic) NSArray *programs;
@property (assign, nonatomic) GLKMatrix4 contentTransform;
@property (assign, nonatomic) CGSize contentSize; // Content size used to compute the contentMode transform. By default it can be the texture size.

- (BOOL)setFilterFragmentShaderFromFile:(NSString *)path error:(NSError *__autoreleasing *)error;
- (BOOL)setFilterFragmentShadersFromFiles:(NSArray *)paths error:(NSError *__autoreleasing *)error;
- (UIImage *)takeScreenshot;
- (UIImage *)takeScreenshotWithImageOrientation:(UIImageOrientation)orientation;

/*
 * Draws the OpenGL contents immediately.
 */
- (void)forceDisplay;

/* These methods are conceptually protected and should not be called directly. They are intended to be called by subclasses. */
- (void)_setTextureData:(GLvoid *)textureData width:(GLint)width height:(GLint)height;
- (void)_updateTextureWithData:(GLvoid *)textureData;
- (void)_deleteMainTexture;

@end
