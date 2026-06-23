#version 330 compatibility

out vec2 lmcoord;
out vec2 texcoord;
out vec4 glcolor;

uniform int worldTime;

#define cloudWaviness 20 //[0.5 0.75 1 20 30 40 50 100 150 200]

out vec3 normal;

uniform mat4 gbufferModelViewInverse;

void main() {
	gl_Position = ftransform();
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	lmcoord = lmcoord / (30.0 / 32.0) - (1.0 / 32.0);
	glcolor = gl_Color;

	normal = gl_NormalMatrix * gl_Normal; // this gives us the normal in view space
	normal = mat3(gbufferModelViewInverse) * normal; // this converts the normal to world/player space

    vec4 worldPos = gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex;

    float t = float(worldTime) * 0.025;

    vec3 p = gl_Vertex.xyz;

    float wave =
        sin(p.x * 0.1 + t) * 0.12 +
        cos(p.z * 0.1 + t * 1.2) * 0.12;

    worldPos.y += wave * cloudWaviness;

    gl_Position = gl_ProjectionMatrix * gl_ModelViewMatrix * worldPos;
}

