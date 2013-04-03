//
//  XBTexture.m
//  XBImageFilters
//
//  Created by xiss burg on 7/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XBTexture.h"
#import "XBTextureInfo.h"

@implementation XBTexture

@synthesize textureInfo = _textureInfo;
@synthesize wrapSMode = _wrapSMode;
@synthesize wrapTMode = _wrapTMode;
@synthesize minFilter = _minFilter;
@synthesize magFilter = _magFilter;

- (id)initWithTextureInfo:(GLKTextureInfo *)textureInfo
{
    self = [super init];
    if (self) {
        _textureInfo = [textureInfo copy];
        [self setDefaults];
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
        GLuint name;
        glGenTextures(1, &name);
        glBindTexture(GL_TEXTURE_2D, name);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_BGRA, GL_UNSIGNED_BYTE, data);
        _textureInfo = [[XBTextureInfo alloc] initWithName:name target:GL_TEXTURE_2D width:width height:height];
        [self setDefaults];
    }
    return self;
}

- (void)dealloc
{
    GLuint name = self.textureInfo.name;
    glDeleteTextures(1, &name);
}

#pragma mark - Properties

- (void)setWrapSMode:(XBTextureWrapMode)wrapSMode
{
    if (wrapSMode == _wrapSMode) {
        return;
    }
    
    _wrapSMode = wrapSMode;
    glBindTexture(self.textureInfo.target, self.textureInfo.name);
    glTexParameteri(self.textureInfo.target, GL_TEXTURE_WRAP_S, [self convertWrapMode:_wrapSMode]);
}

- (void)setWrapTMode:(XBTextureWrapMode)wrapTMode
{
    if (wrapTMode == _wrapTMode) {
        return;
    }
    
    _wrapTMode = wrapTMode;
    glBindTexture(self.textureInfo.target, self.textureInfo.name);
    glTexParameteri(self.textureInfo.target, GL_TEXTURE_WRAP_T, [self convertWrapMode:_wrapSMode]);
}

- (void)setMinFilter:(XBTextureMinFilter)minFilter
{
    if (minFilter == _minFilter) {
        return;
    }
    
    _minFilter = minFilter;
    glBindTexture(self.textureInfo.target, self.textureInfo.name);
    glTexParameteri(self.textureInfo.target, GL_TEXTURE_MIN_FILTER, [self convertMinFilter:_minFilter]);
}

- (void)setMagFilter:(XBTextureMagFilter)magFilter
{
    if (magFilter == _magFilter) {
        return;
    }
    
    _magFilter = magFilter;
    glBindTexture(self.textureInfo.target, self.textureInfo.name);
    glTexParameteri(self.textureInfo.target, GL_TEXTURE_MAG_FILTER, [self convertMagFilter:_magFilter]);
}

#pragma mark - Methods

- (GLint)convertWrapMode:(XBTextureWrapMode)wrapMode
{
    switch (wrapMode) {
        case XBTextureWrapModeRepeat:
            return GL_REPEAT;
            
        case XBTextureWrapModeClamp:
            return GL_CLAMP_TO_EDGE;
            
        case XBTextureWrapModeMirroredRepeat:
            return GL_MIRRORED_REPEAT;
    }
}

- (GLint)convertMinFilter:(XBTextureMinFilter)minFilter
{
    switch (minFilter) {
        case XBTextureMinFilterLinear:
            return GL_LINEAR;
            
        case XBTextureMinFilterNearestMipmapLinear:
            return GL_NEAREST_MIPMAP_LINEAR;
            
        case XBTextureMinFilterNearest:
            return GL_NEAREST;
            
        case XBTextureMinFilterLinearMipmapLinear:
            return GL_LINEAR_MIPMAP_LINEAR;
            
        case XBTextureMinFilterLinearMipmapNearest:
            return GL_LINEAR_MIPMAP_NEAREST;
            
        case XBTextureMinFilterNearestMipmapNearest:
            return GL_NEAREST_MIPMAP_NEAREST;
    }
}

- (GLint)convertMagFilter:(XBTextureMagFilter)magFilter
{
    switch (magFilter) {
        case XBTextureMagFilterLinear:
            return GL_LINEAR;

        case XBTextureMagFilterNearest:
            return GL_NEAREST;
    }
}

- (void)setDefaults
{
    _wrapSMode = XBTextureWrapModeRepeat;
    _wrapTMode = XBTextureWrapModeRepeat;
    _minFilter = XBTextureMinFilterNearestMipmapLinear;
    _magFilter = XBTextureMagFilterLinear;
}

@end
