shader_type spatial;

uniform vec4 paint : source_color = vec4(0.62,0.62,0.57,1.0);
uniform bool tile = false;
varying vec3 world_point;

void vertex(){
	world_point = (MODEL_MATRIX * vec4(VERTEX,1.0)).xyz;
}

float hash(vec2 p){
	return fract(sin(dot(p,vec2(127.13,371.71)))*4375.5453);
}

float dust(vec2 p){
	vec2 f = fract(p);
	vec2 i = floor(p);
	f = f*f*(3.0-2.0*f);
	return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1)),f.x),f.y);
}

void fragment(){
	vec2 p = world_point.xy;
	float pigment = 0.95+.045*dust(p*55.0)+.034*dust(p*6.0);
	if (tile){
		vec2 grid = p/vec2(.38,.19);
		grid.x += mod(floor(grid.y),2.0)*.5;
		vec2 dist = min(fract(grid),1.0-fract(grid));
		float inset = smoothstep(.0,.023,min(dist.x*2.0,dist.y));
		pigment *= mix(.74, .94 + .085*hash(floor(grid)),inset);
	}
	ALBEDO = paint.rgb * pigment;
	ROUGHNESS = tile ? .74 : .83;
	SPECULAR = .16;
}
