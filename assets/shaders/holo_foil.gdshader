shader_type canvas_item;

// Holographic foil shimmer overlay for RARE cards.
// Applied to a transparent ColorRect ON TOP of the card frame (not replacing it).
// Uses alpha so the pixel-art frame boundaries show through the transparent gaps.

void fragment() {
	vec2 uv = UV;
	float t = TIME;

	// Diagonal shimmer bands
	float wave_a = sin(uv.x * 7.0 - uv.y * 4.0 + t * 1.8) * 0.5 + 0.5;
	float wave_b = sin(uv.y * 5.0 + uv.x * 2.0 + t * 1.2) * 0.5 + 0.5;
	float shimmer = wave_a * wave_b;
	shimmer = smoothstep(0.25, 0.9, shimmer);

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

	// Vignette — shimmer is strongest in the card interior, not the very edge
	float vignette = smoothstep(0.0, 0.18, uv.x) * smoothstep(1.0, 0.82, uv.x)
				   * smoothstep(0.0, 0.12, uv.y) * smoothstep(1.0, 0.88, uv.y);

	// Alpha-based: transparent between shimmer bands so frame shows through
	float alpha = shimmer * vignette * 0.75;
	COLOR = vec4(rainbow * 1.15, alpha);
}
