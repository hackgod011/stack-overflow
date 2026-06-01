shader_type canvas_item;

// Damage flash for enemy ColorRect.
// flash_amount tweened from 1.0 → 0.0 over 0.15s on each hit.

uniform float flash_amount : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	// Blend the base vertex color toward white based on flash_amount
	vec4 base = COLOR;
	COLOR = mix(base, vec4(1.0, 1.0, 1.0, base.a), flash_amount);
}
