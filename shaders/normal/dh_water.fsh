#version 330 compatibility

#include "/lib/water.glsl"

uniform sampler2D lightmap;
uniform sampler2D texture;

varying vec2 lmcoord;
varying vec2 texcoord;
varying vec4 glcolor;

void main() {
	vec4 color = texture2D(texture, texcoord) * glcolor;
	color *= texture2D(lightmap, lmcoord);

	//float sat = 1.6;
  	//float gray = dot(color.rgb, vec3(0.3333));
  	//color.rgb = gray + (color.rgb - gray) * sat;

	color.b = color.b / 1.2;

	float light = lmcoord.x; 

	color.rgb *= light * 0.8 + 0.2;

	/* DRAWBUFFERS:056 */
	gl_FragData[0] = color; //gcolor
	gl_FragData[1] = vec4(vec3(gl_FragCoord.z), 1.0);

	
}