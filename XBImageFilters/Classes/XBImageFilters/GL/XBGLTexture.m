//
//  XBGLTexture.m
//  XBImageFilters
//
//  Created by xiss burg on 7/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XBGLTexture.h"

@implementation XBGLTexture

- (id)initWithTextureInfo:(GLKTextureInfo *)textureInfo
{
    self = [super init];
    if (self) {
        _name = textureInfo.name;
        _width = textureInfo.width;
        _height = textureInfo.height;
        _wrapSMode = XBGLTextureWrapModeRepeat;
        _wrapTMode = XBGLTextureWrapModeRepeat;
        _minFilter = XBGLTextureMinFilterNearestMipmapLinear;
        _magFilter = XBGLTextureMagFilterLinear;
    }
    return self;
}

- (id)initWithContentsOfFile:(NSString *)path options:(NSDictionary *)options error:(NSError *__autoreleasing *)error
{
    GLKTextureInfo *textureInfo = [GLKTextureLoader textureWithContentsOfFile:path options:options error:error];
    if (textureInfo == nil) {
        self = nil;
        return nil;
    }
    
    return [self initWithTextureInfo:textureInfo];
}

- (id)initWithWidth:(GLsizei)width height:(GLsizei)height data:(GLvoid *)data
{
    self = [super init];
    if (self) {
        _name = [[XBGLEngine sharedEngine] createTextureWithWidth:width height:height data:data];
        _width = width;
        _height = height;
        _wrapSMode = XBGLTextureWrapModeRepeat;
        _wrapTMode = XBGLTextureWrapModeRepeat;
        _minFilter = XBGLTextureMinFilterNearestMipmapLinear;
        _magFilter = XBGLTextureMagFilterLinear;
    }
    return self;
}

- (void)dealloc
{
    [[XBGLEngine sharedEngine] deleteTexture:self.name];
}

#pragma mark - Properties

- (void)setWrapSMode:(XBGLTextureWrapMode)wrapSMode
{
    if (wrapSMode == _wrapSMode) {
        return;
    }
    
    _wrapSMode = wrapSMode;
    [[XBGLEngine sharedEngine] setWrapSMode:self.wrapSMode texture:self.name];
}

- (void)setWrapTMode:(XBGLTextureWrapMode)wrapTMode
{
    if (wrapTMode == _wrapTMode) {
        return;
    }
    
    _wrapTMode = wrapTMode;
    [[XBGLEngine sharedEngine] setWrapTMode:self.wrapTMode texture:self.name];
}

- (void)setMinFilter:(XBGLTextureMinFilter)minFilter
{
    if (minFilter == _minFilter) {
        return;
    }
    
    _minFilter = minFilter;
    [[XBGLEngine sharedEngine] setMinFilter:self.minFilter texture:self.name];
}

- (void)setMagFilter:(XBGLTextureMagFilter)magFilter
{
    if (magFilter == _magFilter) {
        return;
    }
    
    _magFilter = magFilter;
    [[XBGLEngine sharedEngine] setMagFilter:self.magFilter texture:self.name];
}

@end
