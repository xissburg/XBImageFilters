//
//  FragmentShader.glsl
//  XBImageFilters
//
//  Created by xiss burg on 2/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

precision mediump float;

uniform sampler2D s_texture;

varying vec2 v_texCoord;

void main()
{
    gl_FragColor = texture2D(s_texture, v_texCoord);
}