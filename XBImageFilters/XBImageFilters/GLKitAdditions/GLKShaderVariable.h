//
//  GLKShaderVariable.h
//  XBImageFilters
//
//  Created by xiss burg on 2/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * OpenGL data type sizes
 */
#define GL_FLOAT_SIZE           sizeof(GLfloat)
#define GL_FLOAT_VEC2_SIZE      2*sizeof(GLfloat)
#define GL_FLOAT_VEC3_SIZE      3*sizeof(GLfloat)
#define GL_FLOAT_VEC4_SIZE      4*sizeof(GLfloat)
#define GL_INT_SIZE             sizeof(GLint)
#define GL_INT_VEC2_SIZE        2*sizeof(GLint)
#define GL_INT_VEC3_SIZE        3*sizeof(GLint)
#define GL_INT_VEC4_SIZE        4*sizeof(GLint)
#define GL_BOOL_SIZE        	sizeof(GLint)
#define GL_BOOL_VEC2_SIZE   	2*sizeof(GLint)
#define GL_BOOL_VEC3_SIZE       3*sizeof(GLint)
#define GL_BOOL_VEC4_SIZE       4*sizeof(GLint)
#define GL_FLOAT_MAT2_SIZE      4*sizeof(GLfloat)
#define GL_FLOAT_MAT3_SIZE      9*sizeof(GLfloat)
#define GL_FLOAT_MAT4_SIZE      16*sizeof(GLfloat)
#define GL_SAMPLER_2D_SIZE      sizeof(GLint)
#define GL_SAMPLER_CUBE_SIZE    sizeof(GLint)

@interface GLKShaderVariable : NSObject

@property (readonly, copy, nonatomic) NSString *name;
@property (readonly, nonatomic) GLint location;
@property (readonly, nonatomic) GLint size;
@property (readonly, nonatomic) GLenum type;
@property (readonly, nonatomic) GLint typeSize;

- (id)initWithName:(NSString *)name location:(GLint)location size:(GLint)size type:(GLenum)type;

@end

size_t TypeSizeForType(GLenum type);
