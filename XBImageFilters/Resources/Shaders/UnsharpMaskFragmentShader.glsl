//
//  BlurFragmentShader.glsl
//  XBImageFilters
//
//  Created by xiss burg on 7/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

precision highp float;

uniform sampler2D s_texture;
uniform sampler2D s_mainTexture;

varying vec2 v_texCoord;
varying vec2 v_blurTexCoords[6];
varying vec2 v_rawTexCoord;

void main()
{
    vec4 mask = vec4(0.0);
    mask += texture2D(s_texture, v_blurTexCoords[0])*0.10;
    mask += texture2D(s_texture, v_blurTexCoords[1])*0.14;
    mask += texture2D(s_texture, v_blurTexCoords[2])*0.17;
    mask += texture2D(s_texture, v_texCoord        )*0.18;
    mask += texture2D(s_texture, v_blurTexCoords[3])*0.17;
    mask += texture2D(s_texture, v_blurTexCoords[4])*0.14;
    mask += texture2D(s_texture, v_blurTexCoords[5])*0.10;
    vec4 color = texture2D(s_mainTexture, v_rawTexCoord);
    gl_FragColor = color*2.0 - mask;
}