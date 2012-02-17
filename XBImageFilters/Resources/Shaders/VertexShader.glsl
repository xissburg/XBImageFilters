//
//  VertexShader.glsl
//  XBImageFilters
//
//  Created by xiss burg on 2/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

attribute vec4 a_position;
attribute vec2 a_texCoord;

uniform vec2 u_texCoordScale;

varying vec2 v_texCoord;

void main()
{
    v_texCoord = a_texCoord*u_texCoordScale;
    gl_Position = a_position;
}