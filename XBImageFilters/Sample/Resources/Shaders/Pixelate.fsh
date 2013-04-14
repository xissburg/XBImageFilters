//
//  Pixelate.fsh
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

vec2 discretize(vec2 v, float d)
{
    return vec2(discretize(v.x, d), discretize(v.y, d));
}

void main()
{
    vec2 texCoord = discretize(v_texCoord, 64.0);
    gl_FragColor = texture2D(s_texture, texCoord);
}