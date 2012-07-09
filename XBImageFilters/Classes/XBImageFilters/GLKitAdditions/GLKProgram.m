//
//  GLKProgram.m
//  XBImageFilters
//
//  Created by xiss burg on 2/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "GLKProgram.h"

NSString *const GLKProgramErrorDomain = @"GLKProgramErrorDomain";

@interface GLKProgram ()

@property (readonly, copy, nonatomic) NSDictionary *uniforms;
@property (strong, nonatomic) NSMutableDictionary *dirtyUniforms;
@property (strong, nonatomic) NSMutableDictionary *samplerBindings;
@property (strong, nonatomic) NSMutableDictionary *samplerXBBindings;

- (GLuint)createShaderWithSource:(NSString *)sourceCode type:(GLenum)type error:(NSError *__autoreleasing *)error;
- (GLuint)createProgramWithVertexShaderSource:(NSString *)vertexShaderSource fragmentShaderSource:(NSString *)fragmentShaderSource error:(NSError *__autoreleasing *)error;
- (NSMutableDictionary *)uniformsForProgram:(GLuint)program;
- (NSMutableDictionary *)attributesForProgram:(GLuint)program;

- (void)flushUniform:(GLKUniform *)uniform;

@end

@implementation GLKProgram

@synthesize uniforms = _uniforms;
@synthesize attributes = _attributes;
@synthesize dirtyUniforms = _dirtyUniforms;
@synthesize program = _program;
@synthesize samplerBindings = _samplerBindings;
@synthesize samplerXBBindings = _samplerXBBindings;

- (id)initWithVertexShaderFromFile:(NSString *)vertexShaderPath fragmentShaderFromFile:(NSString *)fragmentShaderPath error:(NSError *__autoreleasing *)error
{
    NSString *vertexShaderSource = [[NSString alloc] initWithContentsOfFile:vertexShaderPath encoding:NSUTF8StringEncoding error:error];
    
    if (vertexShaderSource == nil) {
        return nil;
    }
    
    NSString *fragmentShaderSource = [[NSString alloc] initWithContentsOfFile:fragmentShaderPath encoding:NSUTF8StringEncoding error:error];
    
    if (fragmentShaderSource == nil) {
        return nil;
    }
    
    return [self initWithVertexShaderSource:vertexShaderSource fragmentShaderSource:fragmentShaderSource error:error];
}

- (id)initWithVertexShaderSource:(NSString *)vertexShaderSource fragmentShaderSource:(NSString *)fragmentShaderSource error:(NSError *__autoreleasing *)error
{
    self = [super init];
    if (self) {
        _program = [self createProgramWithVertexShaderSource:vertexShaderSource fragmentShaderSource:fragmentShaderSource error:error];
        
        if (self.program == 0) {
            return nil;
        }
        
        _uniforms = [[self uniformsForProgram:self.program] copy];
        _attributes = [[self attributesForProgram:self.program] copy];
        self.samplerBindings = [[NSMutableDictionary alloc] init];
        self.samplerXBBindings = [[NSMutableDictionary alloc] init];
        self.dirtyUniforms = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)dealloc
{
    glDeleteProgram(self.program);
}

#pragma mark - Methods

- (void)setValue:(void *)value forUniformNamed:(NSString *)uniformName
{
    GLKUniform *uniform = [self.uniforms objectForKey:uniformName];
    uniform.value = value;
    [self.dirtyUniforms setObject:uniform forKey:uniform.name];
}

- (void)bindSamplerNamed:(NSString *)samplerName toXBTexture:(XBTexture *)texture unit:(GLint)unit
{
    if ([self.uniforms objectForKey:samplerName] == nil) {
        return;
    }
    
    [self setValue:&unit forUniformNamed:samplerName];
    
    if (texture != nil) {
        [self.samplerXBBindings setObject:texture forKey:samplerName];
    }
    else {
        [self.samplerXBBindings removeObjectForKey:samplerName];
    }
}

- (void)bindSamplerNamed:(NSString *)samplerName toTexture:(GLuint)texture unit:(GLint)unit
{
    if ([self.uniforms objectForKey:samplerName] == nil) {
        return;
    }
    
    [self setValue:&unit forUniformNamed:samplerName];
    
    if (texture != 0) {
        [self.samplerBindings setObject:[NSNumber numberWithUnsignedInt:texture] forKey:samplerName];
    }
    else {
        [self.samplerBindings removeObjectForKey:samplerName];
    }
}

- (GLuint)createShaderWithSource:(NSString *)sourceCode type:(GLenum)type error:(NSError *__autoreleasing *)error
{
    GLuint shader = glCreateShader(type);
    
    if (shader == 0) {
        if (error != NULL) {
            NSDictionary *userInfo = [[NSDictionary alloc] initWithObjectsAndKeys:@"glCreateShader failed.", NSLocalizedDescriptionKey, nil];
            *error = [[NSError alloc] initWithDomain:GLKProgramErrorDomain code:GLKProgramErrorFailedToCreateShader userInfo:userInfo];
        }
        return 0;
    }
    
    const GLchar *shaderSource = [sourceCode cStringUsingEncoding:NSUTF8StringEncoding];
    
    glShaderSource(shader, 1, &shaderSource, NULL);
    glCompileShader(shader);
    
    GLint success = 0;
    glGetShaderiv(shader, GL_COMPILE_STATUS, &success);
    
    if (success == 0) {
        if (error != NULL) {
            char errorMsg[2048];
            glGetShaderInfoLog(shader, sizeof(errorMsg), NULL, errorMsg);
            NSString *errorString = [NSString stringWithCString:errorMsg encoding:NSUTF8StringEncoding];
            NSDictionary *userInfo = [[NSDictionary alloc] initWithObjectsAndKeys:errorString, NSLocalizedDescriptionKey, nil];
            *error = [[NSError alloc] initWithDomain:GLKProgramErrorDomain code:GLKProgramErrorCompilationFailed userInfo:userInfo];
        }
        glDeleteShader(shader);
        return 0;
    }
    
    return shader;
}

- (GLuint)createProgramWithVertexShaderSource:(NSString *)vertexShaderSource fragmentShaderSource:(NSString *)fragmentShaderSource error:(NSError *__autoreleasing *)error
{
    GLuint vertexShader = [self createShaderWithSource:vertexShaderSource type:GL_VERTEX_SHADER error:error];
    
    if (vertexShader == 0) {
        return 0;
    }
    
    GLuint fragmentShader = [self createShaderWithSource:fragmentShaderSource type:GL_FRAGMENT_SHADER error:error];
    
    if (fragmentShader == 0) {
        return 0;
    }
    
    GLuint program = glCreateProgram();
    glAttachShader(program, vertexShader);
    glAttachShader(program, fragmentShader);
    glLinkProgram(program);
    
    glDeleteShader(vertexShader);
    glDeleteShader(fragmentShader);
    
    GLint linked = 0;
    glGetProgramiv(program, GL_LINK_STATUS, &linked);
    if (linked == 0) {
        if (error != NULL) {
            char errorMsg[2048];
            glGetProgramInfoLog(program, sizeof(errorMsg), NULL, errorMsg);
            NSString *errorString = [NSString stringWithCString:errorMsg encoding:NSUTF8StringEncoding];
            NSDictionary *userInfo = [[NSDictionary alloc] initWithObjectsAndKeys:errorString, NSLocalizedDescriptionKey, nil];
            *error = [[NSError alloc] initWithDomain:GLKProgramErrorDomain code:GLKProgramErrorLinkFailed userInfo:userInfo];
        }
        glDeleteProgram(program);
        return 0;
    }
    
    return program;
}

- (NSMutableDictionary *)uniformsForProgram:(GLuint)program
{
    GLint count;
    glGetProgramiv(program, GL_ACTIVE_UNIFORMS, &count);
    GLint maxLength;
    glGetProgramiv(program, GL_ACTIVE_UNIFORM_MAX_LENGTH, &maxLength);
    GLchar *nameBuffer = (GLchar *)malloc(maxLength * sizeof(GLchar));
    NSMutableDictionary *uniforms = [[NSMutableDictionary alloc] initWithCapacity:count];
    
    for (int i = 0; i < count; ++i) {
        GLint size;
        GLenum type;
        glGetActiveUniform(program, i, maxLength, NULL, &size, &type, nameBuffer);
        GLint location = glGetUniformLocation(program, nameBuffer);
        NSString *name = [[NSString alloc] initWithCString:nameBuffer encoding:NSUTF8StringEncoding];
        GLKUniform *uniform = [[GLKUniform alloc] initWithName:name location:location size:size type:type];
        [uniforms setObject:uniform forKey:name];
    }
    
    free(nameBuffer);
    
    return uniforms;
}

- (NSMutableDictionary *)attributesForProgram:(GLuint)program
{
    GLint count;
    glGetProgramiv(program, GL_ACTIVE_ATTRIBUTES, &count);
    GLint maxLength;
    glGetProgramiv(program, GL_ACTIVE_ATTRIBUTE_MAX_LENGTH, &maxLength);
    GLchar *nameBuffer = (GLchar *)malloc(maxLength * sizeof(GLchar));
    NSMutableDictionary *attributes = [[NSMutableDictionary alloc] initWithCapacity:count];
    
    for (int i = 0; i < count; ++i) {
        GLint size;
        GLenum type;
        glGetActiveAttrib(program, i, maxLength, NULL, &size, &type, nameBuffer);
        GLint location = glGetAttribLocation(program, nameBuffer);
        NSString *name = [[NSString alloc] initWithCString:nameBuffer encoding:NSUTF8StringEncoding];
        GLKAttribute *attribute = [[GLKAttribute alloc] initWithName:name location:location size:size type:type];
        [attributes setObject:attribute forKey:name];
    }
    
    free(nameBuffer);
    
    return attributes;
}

- (void)flushUniform:(GLKUniform *)uniform
{
    switch (uniform.type) {
        case GL_FLOAT:
            glUniform1fv(uniform.location, uniform.size, uniform.value);
            break;
            
        case GL_FLOAT_VEC2:
            glUniform2fv(uniform.location, uniform.size, uniform.value);
            break;
            
        case GL_FLOAT_VEC3:
            glUniform3fv(uniform.location, uniform.size, uniform.value);
            break;
            
        case GL_FLOAT_VEC4:
            glUniform4fv(uniform.location, uniform.size, uniform.value);
            break;
            
        case GL_INT:
        case GL_BOOL:
            glUniform1iv(uniform.location, uniform.size, uniform.value);
            break;
            
        case GL_INT_VEC2:
        case GL_BOOL_VEC2:
            glUniform2iv(uniform.location, uniform.size, uniform.value);
            break;
            
        case GL_INT_VEC3:
        case GL_BOOL_VEC3:
            glUniform3iv(uniform.location, uniform.size, uniform.value);
            break;
            
        case GL_INT_VEC4:
        case GL_BOOL_VEC4:
            glUniform4iv(uniform.location, uniform.size, uniform.value);
            break;
            
        case GL_FLOAT_MAT2:
            glUniformMatrix2fv(uniform.location, uniform.size, GL_FALSE, uniform.value);
            break;
            
        case GL_FLOAT_MAT3:
            glUniformMatrix3fv(uniform.location, uniform.size, GL_FALSE, uniform.value);
            break;
            
        case GL_FLOAT_MAT4:
            glUniformMatrix4fv(uniform.location, uniform.size, GL_FALSE, uniform.value);
            break;
            
        case GL_SAMPLER_2D:
        case GL_SAMPLER_CUBE:
            glUniform1iv(uniform.location, uniform.size, uniform.value);
            break;
            
        default:
            break;
    }
}

- (void)prepareToDraw
{
    glUseProgram(self.program);
    
    // Flush dirty uniforms
    for (NSString *name in [self.dirtyUniforms allKeys]) {
        GLKUniform *uniform = [self.dirtyUniforms objectForKey:name];
        [self flushUniform:uniform];
    }
    
    [self.dirtyUniforms removeAllObjects];
    
    // Set textures
    for (NSString *name in [self.uniforms allKeys]) {
        GLKUniform *uniform = [self.uniforms objectForKey:name];
        
        if (uniform.type == GL_SAMPLER_2D || uniform.type == GL_SAMPLER_CUBE) {
            XBTexture *texture = [self.samplerXBBindings objectForKey:uniform.name];
            
            if (texture != nil) {
                glActiveTexture(GL_TEXTURE0 + *(GLint *)uniform.value);
                glBindTexture(GL_TEXTURE_2D, texture.textureInfo.name);
            }
            
            NSNumber *textureNumber = [self.samplerBindings objectForKey:uniform.name];
            
            if (textureNumber != nil) {
                glActiveTexture(GL_TEXTURE0 + *(GLint *)uniform.value);
                glBindTexture(GL_TEXTURE_2D, textureNumber.unsignedIntValue);
            }
        }
    }
}

@end
