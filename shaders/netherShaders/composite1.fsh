#version 330 compatibility

uniform sampler2D colortex0;
uniform sampler2D depthtex0;

uniform mat4 gbufferProjectionInverse;

uniform vec3 fogColor;
uniform float far;

#define FOG_DENSITY 5.0

uniform float blindness;
uniform float darknessFactor;

uniform int isEyeInWater;

uniform int frameCounter;

in vec2 texcoord;

vec3 projectAndDivide(mat4 projectionMatrix, vec3 position){
  vec4 homPos = projectionMatrix * vec4(position, 1.0);
  return homPos.xyz / homPos.w;
}

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {
    color = texture(colortex0, texcoord);

    float depth = texture(depthtex0, texcoord).r;
    if(depth == 1.0){
        return;
    }

    vec3 NDCPos = vec3(texcoord.xy, depth) * 2.0 - 1.0;
    vec3 viewPos = projectAndDivide(gbufferProjectionInverse, NDCPos);

    float dist = length(viewPos) / far;

    float fogFactor = exp(-FOG_DENSITY * (1.0 - dist)) * 7;

    if(blindness != 0) fogFactor = exp(-FOG_DENSITY * (1.0 - dist)) * (blindness * 100);

    float pulse = 0.5 + 0.5 * sin(frameCounter * 0.05);

    if(darknessFactor > 0.0) {
        float darkness = darknessFactor * pulse + 0.1;
        color.rgb *= 1.0 - darkness;
    }

    if(isEyeInWater == 1) fogFactor = exp(-FOG_DENSITY * (1.0 - dist)) * 50;

    if(isEyeInWater == 2) fogFactor = exp(-FOG_DENSITY * (1.0 - dist)) * 70;



    color.rgb = mix(color.rgb, pow(fogColor, vec3(2.2)), clamp(fogFactor, 0.0, 1.0));

}

