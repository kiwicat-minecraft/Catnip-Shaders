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

uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;
uniform sampler2D shadowcolor0;

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

vec3 getShadow(vec3 shadowScreenPos){
  float transparentShadow = step(shadowScreenPos.z, texture(shadowtex0, shadowScreenPos.xy).r); // sample the shadow map containing everything

  /*
  note that a value of 1.0 means 100% of sunlight is getting through
  not that there is 100% shadowing
  */

  if(transparentShadow == 1.0){
    /*
    since this shadow map contains everything,
    there is no shadow at all, so we return full sunlight
    */
    return vec3(1.0);
  }

  float opaqueShadow = step(shadowScreenPos.z, texture(shadowtex1, shadowScreenPos.xy).r); // sample the shadow map containing only opaque stuff

  if(opaqueShadow == 0.0){
    // there is a shadow cast by something opaque, so we return no sunlight
    return vec3(0.0);
  }

  // contains the color and alpha (transparency) of the thing casting a shadow
  vec4 shadowColor = texture(shadowcolor0, shadowScreenPos.xy);


  /*
  we use 1 - the alpha to get how much light is let through
  and multiply that light by the color of the caster
  */
  return shadowColor.rgb * (1.0 - shadowColor.a);
}

vec4 getNoise(vec2 coord){
  ivec2 screenCoord = ivec2(coord * vec2(viewWidth, viewHeight)); // exact pixel coordinate onscreen
  ivec2 noiseCoord = screenCoord % 64; // wrap to range of noiseTextureResolution
  return texelFetch(noisetex, noiseCoord, 0);
}

vec3 getSoftShadow(vec4 shadowClipPos){
  float noise = getNoise(texcoord).r;

  float theta = noise * radians(360.0); // random angle using noise value
  float cosTheta = cos(theta);
  float sinTheta = sin(theta);

  mat2 rotation = mat2(cosTheta, -sinTheta, sinTheta, cosTheta); // matrix to rotate the offset around the original position by the angle



  vec3 shadowAccum = vec3(0.0); // sum of all shadow samples
  const int samples = SHADOW_RANGE * SHADOW_RANGE * 4; // we are taking 2 * SHADOW_RANGE * 2 * SHADOW_RANGE samples

  for(int x = -SHADOW_RANGE; x < SHADOW_RANGE; x++){
    for(int y = -SHADOW_RANGE; y < SHADOW_RANGE; y++){  
		vec2 offset = vec2(x, y) * SHADOW_RADIUS / float(SHADOW_RANGE);
  		offset = rotation * offset; // rotate the sampling kernel using the rotation matrix we constructed
  		offset /= shadowMapResolution; // offset in the rotated direction by the specified amount. We divide by the resolution so our offset is in terms of pixels
  		vec4 offsetShadowClipPos = shadowClipPos + vec4(offset, 0.0, 0.0); // add offset
      offsetShadowClipPos.z -= 0.001; // apply bias
      offsetShadowClipPos.xyz = distortShadowClipPos(offsetShadowClipPos.xyz); // apply distortion
      vec3 shadowNDCPos = offsetShadowClipPos.xyz / offsetShadowClipPos.w; // convert to NDC space
      vec3 shadowScreenPos = shadowNDCPos * 0.5 + 0.5; // convert to screen space
      shadowAccum += getShadow(shadowScreenPos); // take shadow sample
    }
  }

  return shadowAccum / float(samples); // divide sum by count, getting average shadow
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
      max(0.0, 1.0 - torchDist / 12.0);

  
  heldLight *= heldLight;

  
  vec3 torchLight = blocklightColor * heldLight * 1.5;

  

	vec3 shadowViewPos = (shadowModelView * vec4(feetPlayerPos, 1.0)).xyz;

  vec3 sunlightColor = vec3(1.0);

  if (worldTime < 23215 && worldTime > 12785){  // Day and Night handling
    sunlightColor = vec3(0.05);
    skylight /= 2;
    ambient /= 2;
  } 
  

  else sunlightColor = vec3(1.0);

  

	vec4 shadowClipPos = shadowProjection * vec4(shadowViewPos, 1.0);

	

	vec3 shadow = getSoftShadow(shadowClipPos);

  vec4 lmData = texture(colortex1, texcoord);

  
  float eyeFlag = lmData.a;

  if (eyeFlag < 0.1) {
    color = texture(colortex0, texcoord);
    return;
  }
	

	vec3 sunlight = sunlightColor * clamp(dot(worldLightVector, normal), 0.0, 1.0) * shadow;

  //if(sunlight.r < 10) sunlight.r = -0.1;

	color.rgb *= blocklight + skylight + ambient + sunlight + torchLight;

  float sat = 1.2;

  float gray = dot(color.rgb, vec3(0.3333));
  color.rgb = gray + (color.rgb - gray) * sat;
    
	//color.rgb = texture(shadowtex0, texcoord).rgb;
	//color = getNoise(texcoord);

  

  //color.rg = lightmap;
  //color.rgb = normal * 0.5 + 0.5;
  
}

