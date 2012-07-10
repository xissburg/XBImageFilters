//
//  HBlurVertexShader.glsl
//  XBImageFilters
//
//  Created by xiss burg on 7/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

attribute vec4 a_position;
attribute vec2 a_texCoord;

uniform mat4 u_contentTransform;
uniform mat2 u_texCoordTransform;
uniform mat2 u_rawTexCoordTransform;

varying vec2 v_texCoord;
varying vec2 v_blurTexCoords[6];
varying vec2 v_rawTexCoord;

void main()
{
    gl_Position = u_contentTransform * a_position;
    v_texCoord = u_texCoordTransform * a_texCoord;
    v_blurTexCoords[0] = v_texCoord + vec2(-0.009, 0.0);
    v_blurTexCoords[1] = v_texCoord + vec2(-0.006, 0.0);
    v_blurTexCoords[2] = v_texCoord + vec2(-0.003, 0.0);
    v_blurTexCoords[3] = v_texCoord + vec2( 0.003, 0.0);
    v_blurTexCoords[4] = v_texCoord + vec2( 0.006, 0.0);
    v_blurTexCoords[5] = v_texCoord + vec2( 0.009, 0.0);
    v_rawTexCoord = u_rawTexCoordTransform * gl_Position.xy * 0.5 + vec2(0.5);
}