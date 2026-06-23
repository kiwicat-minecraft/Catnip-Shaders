#version 330 compatibility

out vec2 lmcoord;
out vec2 texcoord;
out vec4 glcolor;

in vec2 mc_Entity;

uniform float viewWidth;
uniform float viewHeight;
uniform sampler2D noisetex;
uniform int worldTime;

#define waveStrength 0.5 //[0.1 0.2 0.3 0.4 0.5 0.75 1 20 200]

out float blockId;
out float fluidId;

out vec3 normal;

#define Water		10008.0

uniform mat4 gbufferModelViewInverse;

vec4 getNoise(vec2 coord){
  ivec2 screenCoord = ivec2(coord * vec2(viewWidth, viewHeight)); // exact pixel coordinate onscreen
  ivec2 noiseCoord = screenCoord % 64; // wrap to range of noiseTextureResolution
  return texelFetch(noisetex, noiseCoord, 0);
}

void main() {
	gl_Position = ftransform();
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	lmcoord = lmcoord / (30.0 / 32.0) - (1.0 / 32.0);
	glcolor = gl_Color;

	normal = gl_NormalMatrix * gl_Normal; // this gives us the normal in view space
	normal = mat3(gbufferModelViewInverse) * normal; // this converts the normal to world/player space

    blockId = mc_Entity.x;
    fluidId = mc_Entity.y;

    
    vec4 worldPos = gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex;

    if (mc_Entity.y == 1.0) {

        float t = float(worldTime) * 0.025;

        vec3 p = gl_Vertex.xyz;

        float wave =
            sin(p.x * 0.1 + t) * 0.12 +
            cos(p.z * 0.1 + t * 1.2) * 0.12;

        worldPos.y += wave * waveStrength;
    }

    gl_Position = gl_ProjectionMatrix * gl_ModelViewMatrix * worldPos;
}

