shader_type spatial;
render_mode diffuse_lambert, specular_disabled;

uniform vec4 base : source_color = vec4(0.52, 0.55, 0.47, 1.0);
uniform bool floor_tiles = false;
varying vec3 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

float grain(vec2 p) {
	vec3 q = fract(vec3(p.xyx) * 0.1031);
	q += dot(q, q.yzx + 33.33);
	return fract((q.x + q.y) * q.z);
}

void fragment() {
	vec2 p = floor_tiles ? world_position.xz : world_position.xy;
	vec2 cell = floor(p * 42.0);
	float stipple = (grain(cell) - 0.5) * 0.042;
	float brightness = 1.0;
	if (floor_tiles) {
		vec2 tile = p / 0.44;
		float checker = mod(floor(tile.x) + floor(tile.y), 2.0);
		float grout = float(min(fract(tile.x), fract(tile.y)) < 0.019);
		brightness += checker * 0.075 - grout * 0.22;
	} else {
		// Afternoon light from the side glazing grazes the painted wall.
		float beam = p.x + p.y * 0.51;
		float pane = smoothstep(1.21, 1.28, beam) * (1.0 - smoothstep(2.72, 2.79, beam));
		float mullion = smoothstep(0.02, 0.07, abs(beam - 2.12));
		float rail = smoothstep(0.017, 0.06, abs(p.y - p.x * 0.16 - 2.26));
		brightness += pane * mullion * rail * 0.20;
	}
	ALBEDO = base.rgb * (brightness + stipple);
	ROUGHNESS = 0.94;
}
