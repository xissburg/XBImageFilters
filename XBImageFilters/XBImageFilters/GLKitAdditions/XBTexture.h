//
//  XBTexture.h
//  XBImageFilters
//
//  Created by xiss burg on 7/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <GLKit/GLKit.h>

typedef enum {
    XBTextureWrapModeClamp,
    XBTextureWrapModeRepeat,
    XBTextureWrapModeMirroredRepeat
} XBTextureWrapMode;

typedef enum {
    XBTextureMinFilterNearest,
    XBTextureMinFilterLinear,
    XBTextureMinFilterNearestMipmapNearest,
    XBTextureMinFilterLinearMipmapNearest,
    XBTextureMinFilterNearestMipmapLinear,
    XBTextureMinFilterLinearMipmapLinear
} XBTextureMinFilter;

typedef enum {
    XBTextureMagFilterNearest,
    XBTextureMagFilterLinear
} XBTextureMagFilter;

@interface XBTexture : NSObject

@property (nonatomic, readonly) GLKTextureInfo *textureInfo;
@property (nonatomic, assign) XBTextureWrapMode wrapSMode;
@property (nonatomic, assign) XBTextureWrapMode wrapTMode;
@property (nonatomic, assign) XBTextureMinFilter minFilter;
@property (nonatomic, assign) XBTextureMagFilter magFilter;

- (id)initWithTextureInfo:(GLKTextureInfo *)textureInfo;
- (id)initWithContentsOfFile:(NSString *)path options:(NSDictionary *)options error:(NSError **)error; // samething as -[GLKTextureLoader initWithContentsOfFile:opetions:error:] or +[GLKTextureLoader textureWithContentsOfFile:opetions:error:]
- (id)initWithWidth:(GLsizei)width height:(GLsizei)height data:(GLvoid *)data;

@end
