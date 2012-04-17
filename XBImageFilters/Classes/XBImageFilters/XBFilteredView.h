//
//  XBFilteredView.h
//  XBImageFilters
//
//  Created by xiss burg on 3/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>

@interface XBFilteredView : UIView

@property (strong, nonatomic) NSArray *programs;
@property (assign, nonatomic) GLKMatrix4 contentTransform;
@property (assign, nonatomic) CGSize contentSize; // Content size used to compute the contentMode transform. By default it can be the texture size.
@property (assign, nonatomic) GLKMatrix2 texCoordTransform;
@property (readonly, nonatomic) GLint maxTextureSize; // Maximum texture width and height

- (BOOL)setFilterFragmentShaderFromFile:(NSString *)path error:(NSError *__autoreleasing *)error;
- (BOOL)setFilterFragmentShadersFromFiles:(NSArray *)paths error:(NSError *__autoreleasing *)error;

/* 
 * Returns an image with the contents of the framebuffer. 
 */
- (UIImage *)takeScreenshot;
- (UIImage *)takeScreenshotWithImageOrientation:(UIImageOrientation)orientation;

/*
 * Draws the OpenGL contents immediately.
 */
- (void)display;

/* These methods are conceptually protected and should not be called directly. They are intended to be called by subclasses. */
- (void)_setTextureData:(GLvoid *)textureData width:(GLint)width height:(GLint)height;
- (void)_updateTextureWithData:(GLvoid *)textureData;
- (void)_deleteMainTexture;
- (UIImage *)_filteredImageWithData:(GLvoid *)data textureWidth:(GLint)textureWidth textureHeight:(GLint)textureHeight targetWidth:(GLint)targetWidth targetHeight:(GLint)targetHeight contentTransform:(GLKMatrix4)contentTransform;
- (UIImage *)_imageFromFramebuffer:(GLuint)framebuffer width:(GLint)width height:(GLint)height orientation:(UIImageOrientation)orientation;
- (UIImage *)_imageWithData:(void *)data width:(GLint)width height:(GLint)height orientation:(UIImageOrientation)orientation ownsData:(BOOL)ownsData; // ownsData YES means the data buffer will be free()'d when the image is freed.

@end

extern const GLKMatrix2 GLKMatrix2Identity;