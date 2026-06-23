#version 330 compatibility

uniform sampler2D colortex0;

#include "/lib/distort.glsl"

// defines the total radius in which we sample (in pixels)
#define SHADOW_RADIUS 1 // [1 2 3]
// controls how many samples we take for every pixel we sample
#define SHADOW_RANGE 4 // [1 2 3 4]

in vec2 texcoord;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

#define shadwoMapRes 2048 //[1024 2048 3072 4098]

const int shadowMapResolution = shadwoMapRes;
const float shadowDistanceRenderMul = 1.0;

const bool shadowtex0Nearest = true;
const bool shadowtex1Nearest = true;
const bool shadowcolor0Nearest = true;

uniform int heldBlockLightValue;
uniform int heldBlockLightValue2; // Offhand
uniform vec3 cameraPosition;


uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform vec3 shadowLightPosition;
uniform mat4 gbufferModelViewInverse;
uniform sampler2D depthtex0;
uniform sampler2D noisetex;

uniform int worldTime;

uniform float viewWidth;
uniform float viewHeight;


uniform mat4 gbufferProjectionInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;

const vec3 blocklightColor = vec3(1.0, 0.5, 0.08);
const vec3 skylightColor = vec3(0.05, 0.15, 0.3);
//const vec3 sunlightColor = vec3(1.0);
const vec3 ambientColor = vec3(0.1);

vec3 projectAndDivide(mat4 projectionMatrix, vec3 position){
  vec4 homPos = projectionMatrix * vec4(position, 1.0);
  return homPos.xyz / homPos.w;
}



vec4 getNoise(vec2 coord){
  ivec2 screenCoord = ivec2(coord * vec2(viewWidth, viewHeight)); // exact pixel coordinate onscreen
  ivec2 noiseCoord = screenCoord % 64; // wrap to range of noiseTextureResolution
  return texelFetch(noisetex, noiseCoord, 0);
}





void main() {

	

	color = texture(colortex0, texcoord);
	color.rgb = pow(color.rgb, vec3(2.2));

	

	vec2 lightmap = texture(colortex1, texcoord).rg; // we only need the r and g components
  vec3 encodedNormal = texture(colortex2, texcoord).rgb;
  vec3 normal = normalize((encodedNormal - 0.5) * 2.0); // we normalize to make sure it is of unit length

	float depth = texture(depthtex0, texcoord).r;
	if (depth == 1.0) {
		return;
	}

    vec3 blocklight = lightmap.r * blocklightColor;
	vec3 skylight = lightmap.g * skylightColor;

	vec3 ambient = ambientColor * (lightmap.g - 0.2);

	vec3 lightVector = normalize(shadowLightPosition);
	vec3 worldLightVector = mat3(gbufferModelViewInverse) * lightVector;

	//vec3 sunlight = sunlightColor * clamp(dot(worldLightVector, normal), 0.0, 1.0) * lightmap.g;

	
	//color.rgb = texture(shadowtex0, texcoord).rgb;

	vec3 NDCPos = vec3(texcoord.xy, depth) * 2.0 - 1.0;
	vec3 viewPos = projectAndDivide(gbufferProjectionInverse, NDCPos);
	vec3 feetPlayerPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;

  
  vec3 worldPos = feetPlayerPos + cameraPosition;

  
  float torchDist = length(feetPlayerPos);

  
  float heldLight =
      heldBlockLightValue / 8 *
      max(0.0, 1.0 - torchDist / 18.0);

  
  heldLight *= heldLight;

  
  vec3 torchLight = blocklightColor * heldLight * 1.5;

  


  vec3 sunlightColor = vec3(1.0);

  if (worldTime < 23215 && worldTime > 12785){  // Day and Night handling
    sunlightColor = vec3(0.05);
    skylight /= 2;
    ambient /= 2;
  } 
  

  else sunlightColor = vec3(1.0);

  


	

	
	

	vec3 sunlight = sunlightColor * clamp(dot(worldLightVector, normal), 0.0, 1.0);

  //if(sunlight.r < 10) sunlight.r = -0.1;

	color.rgb *= blocklight + skylight + ambient + sunlight + torchLight;

  float sat = 1.1;

  float gray = dot(color.rgb, vec3(0.3333));
  color.rgb = gray + (color.rgb - gray) * sat;
    
	//color.rgb = texture(shadowtex0, texcoord).rgb;
	//color = getNoise(texcoord);

  

  //color.rg = lightmap;
  //color.rgb = normal * 0.5 + 0.5;
  
}

