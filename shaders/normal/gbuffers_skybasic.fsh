#version 330 compatibility

uniform sampler2D gtexture;

uniform float alphaTestRef = 0.1;

in vec2 lmcoord;
in vec2 texcoord;
in vec4 glcolor;
in vec3 normal;

/* RENDERTARGETS: 0,1,2 */
layout(location = 0) out vec4 color;
layout(location = 1) out vec4 lightmapData;
layout(location = 2) out vec4 encodedNormal;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

void main() {

    
    vec3 viewDir = normalize(normal);
    float up = clamp(viewDir.y * 0.5 + 0.5, 0.0, 1.0);

    
    vec3 horizonColor = vec3(1.0, 0.65, 0.35);
    vec3 zenithColor  = vec3(0.12, 0.35, 0.95);

    vec3 sky = mix(horizonColor, zenithColor, pow(up, 0.4));

    
    float atmosphere = 1.0 - pow(up, 2.5);
    sky += vec3(0.45, 0.55, 0.8) * atmosphere * 0.35;

    
    

    
    vec3 sunDir = normalize(vec3(0.0, 0.7, 1.0));

    float sun =
        pow(max(dot(viewDir, sunDir), 0.0), 1024.0);

    float sunGlow =
        pow(max(dot(viewDir, sunDir), 0.0), 32.0);

    sky += vec3(1.0, 0.95, 0.8) * sun;
    sky += vec3(1.0, 0.7, 0.3) * sunGlow * 0.4;

    
    vec2 starUV = texcoord * 1500.0;

    float starNoise =
        hash(floor(starUV));

    float stars =
        step(0.9985, starNoise);

    sky += vec3(stars);

    color = vec4(sky, 1.0);

    lightmapData = vec4(lmcoord, 0.0, 1.0);
    encodedNormal = vec4(normal * 0.5 + 0.5, 1.0);
}