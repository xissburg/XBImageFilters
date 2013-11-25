//
//  Suck.fsh
//  XBImageFilters
//
//  Created by xiss burg on 4/11/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

precision mediump float;

uniform sampler2D s_texture;

varying vec2 v_texCoord;

float PI = 3.14159265358979323846264;

void main()
{
    vec2 center = vec2(0.5, 0.5);
    vec2 v = v_texCoord - center;
    v.x = 0.5 + v.x*cos(v.x*PI/2.0);
    v.y = 0.5 + v.y*cos(v.y*PI/2.0);
    gl_FragColor = texture2D(s_texture, v);
}