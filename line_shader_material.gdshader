shader_type canvas_item;
render_mode blend_mix;

void vertex() {
	VERTEX;
}

void fragment() {
	float norm = UV.y * 2.0 - 1.0;
	// 1 - norm^n where n is even gives increasingly steep dropoff towards the edges
	// which approximates anti-aliasing
	float alpha = 1.0 - pow(norm, 6);
	COLOR = vec4(1.0, 1.0-UV.x, UV.x, alpha);
}
