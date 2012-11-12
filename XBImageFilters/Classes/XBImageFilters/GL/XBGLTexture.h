//
//  XBGLTexture.h
//  XBImageFilters
//
//  Created by xiss burg on 7/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <GLKit/GLKit.h>
#import "XBGLEngine.h"

@interface XBGLTexture : NSObject

@property (nonatomic, readonly) GLuint name;
@property (nonatomic, readonly) GLuint width;
@property (nonatomic, readonly) GLuint height;
@property (nonatomic, assign) XBGLTextureWrapMode wrapSMode;
@property (nonatomic, assign) XBGLTextureWrapMode wrapTMode;
@property (nonatomic, assign) XBGLTextureMinFilter minFilter;
@property (nonatomic, assign) XBGLTextureMagFilter magFilter;

- (id)initWithTextureInfo:(GLKTextureInfo *)textureInfo;
- (id)initWithContentsOfFile:(NSString *)path options:(NSDictionary *)options error:(NSError **)error;
- (id)initWithWidth:(GLsizei)width height:(GLsizei)height data:(GLvoid *)data;

@end
