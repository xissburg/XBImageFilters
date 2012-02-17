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
    vec4 color = texture2D(s_texture, v_texCoord);
    float gray = color.r * 0.3 + color.g * 0.59 + color.b * 0.11;
    gl_FragColor = vec4(gray, gray, gray, color.a);
}