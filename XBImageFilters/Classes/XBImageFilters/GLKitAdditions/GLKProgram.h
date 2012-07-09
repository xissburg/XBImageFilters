//
//  GLKProgram.h
//  XBImageFilters
//
//  Created by xiss burg on 2/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GLKUniform.h"
#import "GLKAttribute.h"
#import "XBTexture.h"

/**
 * Error domain.
 */
extern NSString *const GLKProgramErrorDomain;

/**
 * Error codes.
 */
enum {
    GLKProgramErrorFailedToCreateShader = 0,
    GLKProgramErrorCompilationFailed = 1,
    GLKProgramErrorLinkFailed = 2
};

/**
 * The class that is missing in GLKit.
 * Encapsulates a GPU program.
 * Its interface is based on the GLKBaseEffect class.
 */
@interface GLKProgram : NSObject

@property (readonly, copy, nonatomic) NSDictionary *attributes;
@property (readonly, nonatomic) GLuint program;

- (id)initWithVertexShaderFromFile:(NSString *)vertexShaderPath fragmentShaderFromFile:(NSString *)fragmentShaderPath error:(NSError *__autoreleasing *)error;
- (id)initWithVertexShaderSource:(NSString *)vertexShaderSource fragmentShaderSource:(NSString *)fragmentShaderSource error:(NSError *__autoreleasing *)error;
- (void)setValue:(void *)value forUniformNamed:(NSString *)uniform;
- (void)bindSamplerNamed:(NSString *)samplerName toXBTexture:(XBTexture *)texture unit:(GLint)unit;
- (void)bindSamplerNamed:(NSString *)samplerName toTexture:(GLuint)texture unit:(GLint)unit;
- (void)prepareToDraw;

@end
