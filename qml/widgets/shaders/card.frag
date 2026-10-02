#version 440

// One carousel card: the picture cropped to fill, cut to a slanted shape with smooth edges, and dimmed.
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 size;
    float skew;
    float imageAspect;
    float ready;
    float dim;
    vec4 fill;
    vec4 shade;
};

layout(binding = 1) uniform sampler2D source;

void main() {
    vec2 uv = qt_TexCoord0;
    float itemAspect = size.x / max(size.y, 1.0);
    if (imageAspect > itemAspect)
        uv.x = 0.5 + (uv.x - 0.5) * itemAspect / imageAspect;
    else
        uv.y = 0.5 + (uv.y - 0.5) * imageAspect / itemAspect;

    vec3 color = mix(fill.rgb, texture(source, uv).rgb, ready);
    color = mix(color, shade.rgb, dim);

    // Distance in pixels from the two slanted edges, measured across them.
    vec2 p = qt_TexCoord0 * size;
    float across = size.y / length(vec2(size.y, skew));
    float left = (p.x - skew * (1.0 - qt_TexCoord0.y)) * across;
    float right = (size.x - skew * qt_TexCoord0.y - p.x) * across;
    float cover = clamp(left + 0.5, 0.0, 1.0) * clamp(right + 0.5, 0.0, 1.0);

    fragColor = vec4(color, 1.0) * cover * qt_Opacity;
}
