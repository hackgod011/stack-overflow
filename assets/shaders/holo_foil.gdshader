shader_type canvas_item;

// Holographic foil shimmer for RARE cards.
// Applied to the card Background ColorRect — generates rainbow waves from UV + TIME.

void fragment() {
	vec2 uv = UV;
	float t = TIME;

	// Diagonal shimmer bands
	float wave_a = sin(uv.x * 7.0 - uv.y * 4.0 + t * 1.8) * 0.5 + 0.5;
	float wave_b = sin(uv.y * 5.0 + uv.x * 2.0 + t * 1.2) * 0.5 + 0.5;
	float shimmer = wave_a * wave_b;
	shimmer = smoothstep(0.2, 0.9, shimmer);

	// Rainbow hue cycling
	float hue = fract(uv.x * 0.35 + uv.y * 0.25 + t * 0.12);
	float h6 = hue * 6.0;
	float f = fract(h6);
	float q = 1.0 - f;
	vec3 rainbow;
	if (h6 < 1.0)      rainbow = vec3(1.0, f,   0.0);
	else if (h6 < 2.0) rainbow = vec3(q,   1.0, 0.0);
	else if (h6 < 3.0) rainbow = vec3(0.0, 1.0, f);
	else if (h6 < 4.0) rainbow = vec3(0.0, q,   1.0);
	else if (h6 < 5.0) rainbow = vec3(f,   0.0, 1.0);
	else               rainbow = vec3(1.0, 0.0, q);

	// Dark purple base for RARE cards
	vec3 base = vec3(0.12, 0.05, 0.22);

	// Blend: base darkens toward edges, rainbow shimmer in the bright bands
	float edge_vignette = smoothstep(0.0, 0.3, uv.x) * smoothstep(1.0, 0.7, uv.x)
						* smoothstep(0.0, 0.2, uv.y) * smoothstep(1.0, 0.8, uv.y);

	vec3 final_color = mix(base, rainbow, shimmer * 0.55 * edge_vignette);
	// Add a subtle gold sheen on bright areas
	final_color += vec3(0.08, 0.06, 0.0) * shimmer * edge_vignette;

	COLOR = vec4(final_color, 1.0);
}
