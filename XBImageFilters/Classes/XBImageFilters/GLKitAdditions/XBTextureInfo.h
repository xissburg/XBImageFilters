//
//  XBTextureInfo.h
//  XBImageFilters
//
//  Created by xiss burg on 7/18/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <GLKit/GLKit.h>

@interface XBTextureInfo : GLKTextureInfo

@property (assign) GLuint                     name;
@property (assign) GLenum                     target;
@property (assign) GLuint                     width;
@property (assign) GLuint                     height;
@property (assign) GLKTextureInfoAlphaState   alphaState;
@property (assign) GLKTextureInfoOrigin       textureOrigin;
@property (assign) BOOL                       containsMipmaps;

- (id)initWithName:(GLuint)name target:(GLenum)target width:(GLuint)width height:(GLuint)height;

@end
