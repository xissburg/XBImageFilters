//
//  BlurFragmentShader.glsl
//  XBImageFilters
//
//  Created by xiss burg on 7/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

precision mediump float;

uniform sampler2D s_texture;

varying vec2 v_texCoord;
varying vec2 v_blurTexCoords[6];

void main()
{
    gl_FragColor = vec4(0.0);
    gl_FragColor += texture2D(s_texture, v_blurTexCoords[0])*0.10;
    gl_FragColor += texture2D(s_texture, v_blurTexCoords[1])*0.14;
    gl_FragColor += texture2D(s_texture, v_blurTexCoords[2])*0.17;
    gl_FragColor += texture2D(s_texture, v_texCoord        )*0.18;
    gl_FragColor += texture2D(s_texture, v_blurTexCoords[3])*0.17;
    gl_FragColor += texture2D(s_texture, v_blurTexCoords[4])*0.14;
    gl_FragColor += texture2D(s_texture, v_blurTexCoords[5])*0.10;
}