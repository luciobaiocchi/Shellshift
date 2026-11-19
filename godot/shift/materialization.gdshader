shader_type spatial;
render_mode unshaded, cull_disabled;

uniform float assembly : hint_range(0.0, 1.0) = 0.0;
uniform float arm_lift : hint_range(0.0, 1.0) = 0.0;
uniform vec4 dye : source_color = vec4(.39, .76, .73, 1.0);
varying float edge_band;
varying float height_id;

void vertex() {
	height_id = UV.x;
	float delay = UV.x * .29;
	float progress = smoothstep(delay, delay + .63, assembly);
	float drift = (1.0 - progress) * (1.0 - progress);
	float layer = floor(UV.x * 44.0);
	VERTEX.x += drift * (.16 * sin(1.74 * layer) + .07 * cos(.8 * layer));
	VERTEX.z += drift * .064 * cos(2.17 * layer);
	if (COLOR.r > .5) {
		float bend = arm_lift * 2.43 * (1.0 - smoothstep(.81,.88,VERTEX.y));
		vec2 elbow = vec2(.222,.841);
		mat2 turn = mat2(vec2(cos(bend),sin(bend)),vec2(-sin(bend),cos(bend)));
		VERTEX.xy = elbow + turn * (VERTEX.xy - elbow);
		NORMAL.xy = turn * NORMAL.xy;
	}
	edge_band = UV.y;
}

void fragment() {
	float side = .48 + .36 * max(0.0, dot(normalize(NORMAL), normalize(vec3(-.42,.57,.72))));
	float rim = pow(1.0 - abs(dot(normalize(NORMAL), normalize(VIEW))), 2.0);
	float edge = smoothstep(.77,.95,edge_band);
	float brightness = .34 + .54 * side + .25 * rim + .16 * edge;
	ALBEDO = dye.rgb * brightness;
}
