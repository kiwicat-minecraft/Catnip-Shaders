#version 330 compatibility

uniform sampler2D gtexture;

in vec2 texcoord;
in vec4 glcolor;

layout(location = 0) out vec4 color;

void main() {
    color = texture(gtexture, texcoord);
    vec2 lmcoord;
    float ao;
    vec4 overlayColor;

    clrwl_computeFragment(color, color, lmcoord, ao, overlayColor);
}