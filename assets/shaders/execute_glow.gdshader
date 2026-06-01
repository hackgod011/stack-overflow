shader_type canvas_item;

// Pulsing glow for the Execute Stack button.
// glow_intensity = 0.0 when stack is empty, 1.0 when ready.

uniform float glow_intensity : hint_range(0.0, 1.0) = 0.0;
uniform vec4 glow_color : source_color = vec4(0.2, 0.9, 0.4, 1.0);

void fragment() {
	vec4 base = texture(TEXTURE, UV);

	// Compute proximity to edges (0 at center, 1 at border)
	vec2 border = min(UV, vec2(1.0) - UV);
	float edge_factor = 1.0 - smoothstep(0.0, 0.25, min(border.x, border.y));

	float pulse = sin(TIME * 3.5) * 0.4 + 0.6;
	float glow = edge_factor * pulse * glow_intensity;

	vec4 result = base;
	// Add glow tint on top of base color
	result.rgb = mix(result.rgb, glow_color.rgb, glow * 0.6);
	// Extra brightness boost at peak
	result.rgb += glow_color.rgb * glow * 0.25;

	COLOR = result;
}
