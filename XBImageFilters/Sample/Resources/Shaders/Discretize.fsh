//
//  Discretize.fsh
//  XBImageFilters
//
//  Created by xiss burg on 4/11/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

precision mediump float;

uniform sampler2D s_texture;

varying vec2 v_texCoord;

float discretize(float f, float d)
{
    return floor(f*d + 0.5)/d;
}

vec4 discretize(vec4 v, float d)
{
    return vec4(discretize(v.x, d), discretize(v.y, d), discretize(v.z, d), discretize(v.w, d));
}

void main()
{
    vec4 color = texture2D(s_texture, v_texCoord);
    gl_FragColor = discretize(color, 4.0);
}