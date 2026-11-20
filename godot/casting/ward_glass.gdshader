shader_type spatial;
varying vec3 point;
void vertex(){
	point = (MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
}
float hash(vec2 p){
	return fract(sin(dot(p,vec2(17.38,113.82)))*43261.3);
}
float fog(vec2 p){
	vec2 f = fract(p);
	vec2 i = floor(p);
	f = f*f*(3.0-2.0*f);
	return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1)),f.x),f.y);
}
uniform vec4 deep : source_color = vec4(.20,.29,.30,1.0);
uniform vec4 sky : source_color = vec4(.54,.62,.61,1.0);
void fragment(){
	// Trees and the covered walkway across the courtyard reflected in frosted glass.
	vec2 p = point.xy;
	float canopy = .98+.52*fog(vec2(p.x*1.35,.5))+.24*fog(vec2(p.x*3.65,.1));
	float edge = smoothstep(-.11,.14,p.y-canopy);
	float density = .15*fog(p*4.5)+.045*fog(p*70.0);
	float beam = (1.0-smoothstep(.0,.035,abs(fract(p.x*.63+.13)-.50)))*.28;
	float rail = (1.0-smoothstep(.0,.018,abs(p.y-(1.87+.07*p.x))))*.17;
	float value = clamp(.09+.65*edge+density-beam-rail,0.,1.);
	ALBEDO = mix(deep.rgb,sky.rgb,value);
	ROUGHNESS = .81;
	SPECULAR = .09;
}
