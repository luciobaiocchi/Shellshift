shader_type spatial;
render_mode unshaded, fog_disabled, cull_disabled, depth_test_disabled, depth_draw_never, shadows_disabled;
uniform sampler2D screen : hint_screen_texture, repeat_disable, filter_linear;
uniform sampler2D depth : hint_depth_texture, repeat_disable, filter_nearest;
uniform float focus = 2.5;
void vertex(){
	POSITION = vec4(VERTEX.xy,1.0,1.0);
}
void fragment(){
	float z = texture(depth,SCREEN_UV).r;
	#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
	vec3 ndc = vec3(SCREEN_UV,z)*2.0-1.0;
	#else
	vec3 ndc = vec3(SCREEN_UV*2.0-1.0,z);
	#endif
	vec4 view = INV_PROJECTION_MATRIX*vec4(ndc,1.);
	float distance_m = -view.z/view.w;
	// Keep the cast in focus. Depth rejection preserves hair against the frosted doors.
	float coc = smoothstep(.30,1.60,distance_m-focus);
	float radius = coc*mix(6.5,2.5,smoothstep(1.55,3.15,focus));
	vec3 color = texture(screen,SCREEN_UV).rgb;
	if (radius>.2){
		vec2 step_uv = vec2(radius*VIEWPORT_SIZE.y/540.0)/VIEWPORT_SIZE;
		float weight = 1.0;
		for (int i=0;i<18;i++){
			float f = float(i)+.5;
			float angle = f*2.39996323;
			vec2 offset = vec2(cos(angle),sin(angle))*sqrt(f/18.0)*step_uv;
			vec2 p = SCREEN_UV+offset;
			float amount = 1.0-smoothstep(.001,.0045,texture(depth,p).r-z);
			color += texture(screen,p).rgb*amount;
			weight += amount;
		}
		color /= weight;
	}
	vec2 edge = (SCREEN_UV-.5)*vec2(1.06,.94);
	color *= 1.-.16*dot(edge,edge);
	color = mix(color, vec3(dot(color,vec3(.299,.587,.114))),.075);
	ALBEDO = color;
}
