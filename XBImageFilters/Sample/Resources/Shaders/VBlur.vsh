//
//  VBlur.vsh
//  XBImageFilters
//
//  Created by xiss burg on 7/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

attribute vec4 a_position;
attribute vec2 a_texCoord;

uniform mat4 u_contentTransform;
uniform mat2 u_texCoordTransform;
uniform float u_radius;

varying vec2 v_texCoord;
varying vec2 v_blurTexCoords[14];

void main()
{
    gl_Position = u_contentTransform * a_position;
    v_texCoord = u_texCoordTransform * a_texCoord;
    
    for (int i = 0; i < 7; ++i) {
        vec2 c = vec2(0.0, u_radius/7.0*(7.0 - float(i)));
        v_blurTexCoords[i] = v_texCoord - c;
        v_blurTexCoords[13-i] = v_texCoord + c;
    }
}