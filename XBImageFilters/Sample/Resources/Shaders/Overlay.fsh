//
//  Overlay.fsh
//  XBImageFilters
//
//  Created by xiss burg on 3/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//


precision mediump float;

uniform sampler2D s_texture;
uniform sampler2D s_overlay;

varying vec2 v_texCoord;
varying vec2 v_rawTexCoord;

void main()
{
    vec4 color = texture2D(s_texture, v_texCoord);
    vec4 overlay = texture2D(s_overlay, v_rawTexCoord);
    vec3 br = clamp(sign(color.rgb - vec3(0.5)), vec3(0.0), vec3(1.0));
    gl_FragColor = vec4(mix(2.0*color.rgb*overlay.rgb, vec3(1.0) - 2.0*(vec3(1.0)-color.rgb)*(vec3(1.0)-overlay.rgb), br), color.a);
}