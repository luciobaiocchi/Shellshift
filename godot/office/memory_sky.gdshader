shader_type spatial;
render_mode unshaded, cull_disabled, fog_disabled;
uniform float winter : hint_range(0.,1.) = 0.;
varying vec2 backdrop;

void vertex(){
	backdrop = VERTEX.xy;
}

float hash21(vec2 p){
	vec3 q = fract(vec3(p.xyx) * .1031);
	q += dot(q, q.yzx + 33.33);
	return fract((q.x + q.y) * q.z);
}
float cloud(vec2 p){
	vec2 n=floor(p);
	vec2 f=fract(p);
	f=f*f*(3.-2.*f);
	return mix(mix(hash21(n),hash21(n+vec2(1,0)),f.x),mix(hash21(n+vec2(0,1)),hash21(n+vec2(1)),f.x),f.y);
}
void fragment(){
	vec2 p=backdrop;
	float high=smoothstep(-5.,7.,p.y);
	vec3 sky=mix(vec3(.16,.19,.25),vec3(.044,.068,.139),high);
	float band=exp(-pow((p.y-.21*p.x-2.4)/1.6,2.));
	float dust=cloud(p*.70)*.5+cloud(p*2.2)*.30+cloud(p*5.7)*.20;
	sky+=vec3(.062,.065,.078)*band*dust;
	vec2 grid=p*14.;
	float intensity=hash21(floor(grid));
	vec2 center=vec2(hash21(floor(grid)+13.),hash21(floor(grid)+83.))*.7+.15;
	float radius=distance(fract(grid),center);
	float star=step(.947-band*.042,intensity)*(1.-smoothstep(.08,.23,radius));
	sky+=mix(vec3(.43,.48,.55),vec3(.64,.52,.37),hash21(floor(grid)+8.))*star;
	ALBEDO=sky*(1.0-.19*winter);
}
