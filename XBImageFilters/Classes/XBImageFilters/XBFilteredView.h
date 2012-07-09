//
//  XBFilteredView.h
//  XBImageFilters
//
//  Created by xiss burg on 3/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>
#import "GLKProgram.h"

@interface XBFilteredView : UIView

@property (readonly, nonatomic) NSArray *programs;
@property (assign, nonatomic) GLKMatrix4 contentTransform;
@property (assign, nonatomic) CGSize contentSize; // Content size used to compute the contentMode transform. By default it can be the texture size.
@property (assign, nonatomic) GLKMatrix2 texCoordTransform;
@property (assign, nonatomic) GLKMatrix2 rawTexCoordTransform;
@property (readonly, nonatomic) GLint maxTextureSize; // Maximum texture width and height
@property (readonly, nonatomic) EAGLContext *context;

- (BOOL)setFilterFragmentShaderFromFile:(NSString *)path error:(NSError *__autoreleasing *)error DEPRECATED_ATTRIBUTE;
- (BOOL)setFilterFragmentShadersFromFiles:(NSArray *)paths error:(NSError *__autoreleasing *)error DEPRECATED_ATTRIBUTE;

- (BOOL)setFilterFragmentShaderSource:(NSString *)fsSource error:(NSError *__autoreleasing *)error;
- (BOOL)setFilterFragmentShaderSources:(NSArray *)fsSources error:(NSError *__autoreleasing *)error;
- (BOOL)setFilterFragmentShaderPath:(NSString *)fsPath error:(NSError *__autoreleasing *)error;
- (BOOL)setFilterFragmentShaderPaths:(NSArray *)fsPaths error:(NSError *__autoreleasing *)error;
- (BOOL)setFilterFragmentShaderSource:(NSString *)fsSource vertexShaderSource:(NSString *)vsSource error:(NSError *__autoreleasing *)error;
- (BOOL)setFilterFragmentShaderSources:(NSArray *)fsSources vertexShaderSources:(NSArray *)vsSources error:(NSError *__autoreleasing *)error;
- (BOOL)setFilterFragmentShaderPath:(NSString *)fsPath vertexShaderPath:(NSString *)vsPath error:(NSError *__autoreleasing *)error;
- (BOOL)setFilterFragmentShaderPaths:(NSArray *)fsPaths vertexShaderPaths:(NSArray *)vsPaths error:(NSError *__autoreleasing *)error;


/* 
 * Returns an image with the contents of the framebuffer. 
 */
- (UIImage *)takeScreenshot;
- (UIImage *)takeScreenshotWithImageOrientation:(UIImageOrientation)orientation;

/*
 * Draws the OpenGL contents immediately.
 */
- (void)display;

/*
 * Returns an string containing memory usage information.
 */
- (NSString *)memoryStatus;

/* These methods are conceptually protected and should not be called directly. They are intended to be called by subclasses. */
- (void)_setTextureData:(GLvoid *)textureData width:(GLint)width height:(GLint)height;
- (void)_updateTextureWithData:(GLvoid *)textureData;
- (void)_setTextureDataWithTextureCache:(CVOpenGLESTextureCacheRef)textureCache texture:(CVOpenGLESTextureRef *)texture imageBuffer:(CVImageBufferRef)imageBuffer;
- (void)_deleteMainTexture;
- (UIImage *)_filteredImageWithData:(GLvoid *)data textureWidth:(GLint)textureWidth textureHeight:(GLint)textureHeight targetWidth:(GLint)targetWidth targetHeight:(GLint)targetHeight contentTransform:(GLKMatrix4)contentTransform;
- (UIImage *)_filteredImageWithData:(GLvoid *)data textureWidth:(GLint)textureWidth textureHeight:(GLint)textureHeight targetWidth:(GLint)targetWidth targetHeight:(GLint)targetHeight contentTransform:(GLKMatrix4)contentTransform rawTexCoordTransform:(GLKMatrix2)rawTexCoordTransform;
- (UIImage *)_filteredImageWithTextureCache:(CVOpenGLESTextureCacheRef)textureCache imageBuffer:(CVImageBufferRef)imageBuffer targetWidth:(GLint)targetWidth targetHeight:(GLint)targetHeight contentTransform:(GLKMatrix4)contentTransform;
- (UIImage *)_filteredImageWithTextureCache:(CVOpenGLESTextureCacheRef)textureCache imageBuffer:(CVImageBufferRef)imageBuffer targetWidth:(GLint)targetWidth targetHeight:(GLint)targetHeight contentTransform:(GLKMatrix4)contentTransform rawTexCoordTransform:(GLKMatrix2)rawTexCoordTransform;
- (UIImage *)_imageFromFramebuffer:(GLuint)framebuffer width:(GLint)width height:(GLint)height orientation:(UIImageOrientation)orientation;
- (UIImage *)_imageWithData:(void *)data width:(GLint)width height:(GLint)height orientation:(UIImageOrientation)orientation ownsData:(BOOL)ownsData; // ownsData YES means the data buffer will be free()'d when the image is freed.

@end

extern const GLKMatrix2 GLKMatrix2Identity;