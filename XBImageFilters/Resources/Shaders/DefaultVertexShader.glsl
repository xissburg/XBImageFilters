//
//  VertexShader.glsl
//  XBImageFilters
//
//  Created by xiss burg on 2/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

attribute vec4 a_position;
attribute vec2 a_texCoord;

uniform mat4 u_contentTransform;
uniform mat2 u_texCoordTransform;

varying vec2 v_texCoord;

void main()
{
    v_texCoord = u_texCoordTransform * a_texCoord;
    gl_Position = u_contentTransform * a_position;
}