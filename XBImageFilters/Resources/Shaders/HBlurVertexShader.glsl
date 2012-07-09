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

varying vec2 v_texCoord;
varying vec2 v_blurTexCoords[6];

void main()
{
    gl_Position = u_contentTransform * a_position;
    v_texCoord = u_texCoordTransform * a_texCoord;
    v_blurTexCoords[0] = v_texCoord + vec2(-0.012, 0.0);
    v_blurTexCoords[1] = v_texCoord + vec2(-0.008, 0.0);
    v_blurTexCoords[2] = v_texCoord + vec2(-0.004, 0.0);
    v_blurTexCoords[3] = v_texCoord + vec2( 0.004, 0.0);
    v_blurTexCoords[4] = v_texCoord + vec2( 0.008, 0.0);
    v_blurTexCoords[5] = v_texCoord + vec2( 0.012, 0.0);
}