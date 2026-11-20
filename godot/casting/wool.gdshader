shader_type spatial;
render_mode cull_disabled;
uniform float tuck = 0.0;
varying vec3 cloth_point;
void vertex(){
	cloth_point = VERTEX;
	// The small fold lifted by Mara's thumb settles slightly higher than before.
	vec3 patch = (VERTEX-vec3(-.078,-.064,.110))/vec3(.058,.073,.049);
	float weight = exp(-dot(patch,patch));
	VERTEX += vec3(.002,.013,-.003)*tuck*weight;
}
void fragment(){
	// At a distance, average the fine stitches before they begin to alias.
	float along = (cloth_point.y + .22*cloth_point.x)*1700.0;
	float across = (cloth_point.x - .6*cloth_point.z)*2000.0;
	float detail = 1.0-smoothstep(.8,3.0,max(fwidth(along),fwidth(across)));
	float thread = sin(along+.85*sin(across))*.5+.5;
	float seam = sin(190.0*cloth_point.y+26.0*cloth_point.x);
	ALBEDO = COLOR.rgb*(.74+.09*thread*detail+.033*seam);
	ROUGHNESS = 1.0;
	SPECULAR = .12;
}
