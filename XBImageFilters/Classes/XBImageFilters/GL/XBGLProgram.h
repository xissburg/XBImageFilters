//
//  XBGLProgram.h
//  XBImageFilters
//
//  Created by xiss burg on 2/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XBGLShaderUniform.h"
#import "XBGLShaderAttribute.h"
#import "XBGLTexture.h"

/**
 * Encapsulates a GPU program.
 * Its interface is based on the GLKBaseEffect class.
 */
@interface XBGLProgram : NSObject

@property (readonly, nonatomic) NSDictionary *attributes;
@property (readonly, nonatomic) GLuint program;

- (id)initWithVertexShaderFromFile:(NSString *)vertexShaderPath fragmentShaderFromFile:(NSString *)fragmentShaderPath error:(NSError *__autoreleasing *)error;
- (id)initWithVertexShaderSource:(NSString *)vertexShaderSource fragmentShaderSource:(NSString *)fragmentShaderSource error:(NSError *__autoreleasing *)error;
- (void)setValue:(void *)value forUniformNamed:(NSString *)uniform;
- (void)bindSamplerNamed:(NSString *)samplerName toXBTexture:(XBGLTexture *)texture unit:(GLint)unit;
- (void)bindSamplerNamed:(NSString *)samplerName toTexture:(GLuint)texture unit:(GLint)unit;
- (void)prepareToDraw;

@end
