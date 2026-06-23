#version 330 compatibility

uniform sampler2D gtexture;

uniform float alphaTestRef = 0.1;
in float blockId;
in float fluidId;

in vec2 lmcoord;
in vec2 texcoord;
in vec4 glcolor;

in vec3 normal;

#define Water		10008.0


/* RENDERTARGETS: 0,1,2 */
layout(location = 0) out vec4 color;
layout(location = 1) out vec4 lightmapData;
layout(location = 2) out vec4 encodedNormal;

void main() {
	color = texture(gtexture, texcoord) * glcolor; // biome tint
	if (color.a < alphaTestRef) { // alpha test
		discard; // don't bother writing
	}

	lightmapData = vec4(lmcoord, 0.0, 1.0);
	encodedNormal = vec4(normal * 0.5 + 0.5, 1.0);
	//encodedNormal = vec4(1.0, 0.0, 1.0, 1.0);

    if(fluidId == 1.0) color.b += 0.1; // water

    //color.rgb = vec3(255);
    
}