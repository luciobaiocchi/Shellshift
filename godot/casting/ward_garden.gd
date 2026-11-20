extends Node3D
## Two silver birches and the old ward across the visitors' courtyard.
const BARK := Color("#978f7c")
const CREAM := Color("#c7c1ac")
const WOOD := Color("#635d4d")
const RIM := Color("#aaa18c")
const SOIL := Color("#504b40")
const FOLIAGE := [Color("#778164"),Color("#8a916d"),Color("#a2a17b"),Color("#747e62"),Color("#aca37a"),Color("#7f865f")]
var solids := SurfaceTool.new()
var leaves := SurfaceTool.new()
var random := RandomNumberGenerator.new()

func build(_stage) -> void:
	solids.begin(Mesh.PRIMITIVE_TRIANGLES)
	leaves.begin(Mesh.PRIMITIVE_TRIANGLES)
	random.seed = 12519
	_ward_wing()
	_planter(Vector3(-3.81,0,-.96),1.50)
	_planter(Vector3(3.75,0,-1.12),1.56)
	_birch(Vector3(-3.83,.32,-1.02),3.03,.073,.36)
	_birch(Vector3(-4.10,.32,-1.20),2.38,.044,-.80)
	_birch(Vector3(3.61,.32,-1.18),3.33,.063,-.84)
	_birch(Vector3(3.88,.32,-1.35),2.48,.048,1.41)
	var masonry := StandardMaterial3D.new()
	masonry.vertex_color_use_as_albedo = true
	masonry.vertex_color_is_srgb = true
	masonry.roughness = .96
	masonry.cull_mode = BaseMaterial3D.CULL_DISABLED
	var woodwork := MeshInstance3D.new()
	woodwork.name = "PlantersBarkAndWard"
	woodwork.mesh = solids.commit()
	woodwork.material_override = masonry
	add_child(woodwork)
	var leaf_shader := Shader.new()
	leaf_shader.code = """
shader_type spatial;
render_mode cull_disabled;
varying vec3 pigment;
void vertex() {
	float flutter = sin(TIME*.76 + VERTEX.z*1.9 + VERTEX.x*.82);
	VERTEX.x += .008*COLOR.a*flutter;
	VERTEX.z += .003*COLOR.a*sin(TIME*.83 + VERTEX.x);
	pigment = COLOR.rgb;
}
void fragment() {
	ALBEDO = OUTPUT_IS_SRGB ? pigment : pow(pigment, vec3(2.2));
	ROUGHNESS = .97;
	SPECULAR = .10;
}"""
	var coating := ShaderMaterial.new()
	coating.shader = leaf_shader
	var crown := MeshInstance3D.new()
	crown.name = "BirchLeaves"
	crown.mesh = leaves.commit()
	crown.material_override = coating
	# The wooden limbs cast the patterned shade. One double-sided pass draws all leaves.
	crown.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(crown)
	solids.clear()
	leaves.clear()

func _triangle(surface: SurfaceTool, a: Vector3,b: Vector3,c: Vector3, tone: Color) -> void:
	var n := (c-a).cross(b-a).normalized()
	for point in [a,b,c]:
		surface.set_normal(n)
		surface.set_color(tone)
		surface.add_vertex(point)

func _box(center: Vector3, dims: Vector3, color: Color) -> void:
	var h := dims*.5
	var v := PackedVector3Array()
	for i in 8:
		v.append(center+Vector3(h.x if i&1 else -h.x,h.y if i&2 else -h.y,h.z if i&4 else -h.z))
	for face in [[0,1,3,2],[6,7,5,4],[4,5,1,0],[2,3,7,6],[4,0,2,6],[1,5,7,3]]:
		_triangle(solids,v[face[0]],v[face[1]],v[face[2]],color)
		_triangle(solids,v[face[0]],v[face[2]],v[face[3]],color)

func _limb(a: Vector3,b: Vector3,ra: float,rb: float,tone: Color,sides := 6) -> void:
	var direction := (b-a).normalized()
	var u := direction.cross(Vector3.FORWARD).normalized()
	var v := direction.cross(u)
	for j in sides:
		var angle := TAU*j/sides
		var next := TAU*(j+1)/sides
		var r1 := u*cos(angle)+v*sin(angle)
		var r2 := u*cos(next)+v*sin(next)
		var color := tone.lerp(Color("#7e7764"),.055*(j%3))
		_triangle(solids,a+ra*r1,b+rb*r2,a+ra*r2,color)
		_triangle(solids,a+ra*r1,b+rb*r1,b+rb*r2,color)

func _planter(origin: Vector3, width: float) -> void:
	_box(origin+Vector3(0,.152,0),Vector3(width,.285,.86),Color("#969382"))
	_box(origin+Vector3(0,.25,0),Vector3(width+.036,.082,.91),RIM)
	_box(origin+Vector3(0,.304,0),Vector3(width+.078,.043,.95),Color("#b1ab95"))
	_box(origin+Vector3(0,.327,0),Vector3(width-.084,.011,.777),SOIL)
	for i in 46:
		var base := origin + Vector3(random.randf_range(-.62,.62),.335,random.randf_range(-.35,.35))
		var rise := random.randf_range(.056,.17)
		for side in [-1,1]:
			_triangle(solids,base+Vector3(-.012,0,0),base+Vector3(side*.051,rise,random.randf_range(-.031,.031)),base+Vector3(.012,0,0),FOLIAGE[i%4].darkened(.18))

func _birch(root: Vector3,height: float, radius: float,phase: float) -> void:
	var trunk: Array[Vector3] = []
	for i in 9:
		var u := i/8.0
		var p := root+Vector3(sin(u*2.2+phase)*u*.22,height*u,cos(u*2.7+phase)*u*.15)
		trunk.append(p)
		if i>0:
			_limb(trunk[i-1],p,radius*pow(1-(i-1)/8.2,.74),radius*pow(1-i/8.2,.74),BARK.lerp(CREAM,.37+u*.41),9)
	for j in 39:
		var k := random.randf_range(.01,6.9)
		var h := floori(k)
		var base := trunk[h].lerp(trunk[h+1],fmod(k,1))
		var rad := radius*pow(1-k/8.2,.74)*1.025
		var angle := random.randf()*TAU
		var length := random.randf_range(.26,1.30)
		var thickness := random.randf_range(.005,.015)
		var strip := Color("#736f60") if j%5 else Color("#e0d6bb")
		var p := base+Vector3(cos(angle)*rad,0,sin(angle)*rad)
		for q in 4:
			var a := angle+length*(q+1)/4
			var n := base+Vector3(cos(a)*rad,.005*sin(q),sin(a)*rad)
			_triangle(solids,p,n,p+Vector3.UP*thickness,strip)
			_triangle(solids,n,n+Vector3.UP*thickness*.84,p+Vector3.UP*thickness,strip)
			p=n
	for j in 23:
		var tier := 2+j%6
		var departure: Vector3 = trunk[tier].lerp(trunk[tier+1],random.randf())
		var u := (departure.y-root.y)/height
		var angle := j*2.39996+phase
		var outward := Vector3(cos(angle),0,sin(angle))
		var breadth := (pow(1.0-u,.46)*.82+.19)*(height/3.0)
		var elbow := departure+outward*breadth*.49+Vector3.UP*(.23+.15*(1-u))
		var tip := elbow+outward*breadth*.51+Vector3.UP*random.randf_range(-.04,.15)
		_limb(departure,elbow,radius*(.23+.10*(1-u)),.009,WOOD.lerp(BARK,.5))
		_limb(elbow,tip,.010,.0028,WOOD,5)
		for twig in 4:
			var sweep := (twig-1.5)*.38
			var side := outward.rotated(Vector3.UP,sweep)
			var start := elbow.lerp(tip,twig*.19)
			var mid := start+side*random.randf_range(.115,.21)+Vector3.UP*random.randf_range(.045,.12)
			var end := mid+side*random.randf_range(.07,.16)-Vector3.UP*random.randf_range(.10,.23)
			_limb(start,mid,.0058,.0036,WOOD,4)
			_limb(mid,end,.0034,.0011,WOOD,4)
			for k in 7:
				var attach := mid.lerp(end,(k+.2)/7.)
				var axis := side.rotated(Vector3.UP,(-1 if k%2 else 1)*random.randf_range(.72,1.48))
				_leaf(attach,axis,FOLIAGE[random.randi()%FOLIAGE.size()])

func _leaf(stem: Vector3,out: Vector3,color: Color) -> void:
	var span := random.randf_range(.061,.118)
	var axis := (out*random.randf_range(.54,.86)+Vector3.UP*random.randf_range(-.83,.19)).normalized()
	var wide := axis.cross(Vector3.UP).rotated(axis,random.randf_range(-1.1,.98)).normalized()*span*.275
	var base := stem
	var ridge := base+axis*span*.40+Vector3.UP*span*.065
	var edge := base+axis*span*.42
	var tip := base+axis*span
	# Each diamond has a folded midrib. Alpha is the flexibility of its tip.
	for tri in [[base,edge+wide,ridge],[ridge,edge+wide,tip],[base,ridge,edge-wide],[ridge,tip,edge-wide]]:
		var a: Vector3 = tri[0]
		var b: Vector3 = tri[1]
		var c: Vector3 = tri[2]
		var normal := (c-a).cross(b-a).normalized()
		if normal.y<0: normal = -normal
		for v: Vector3 in tri:
			var pigment := color
			pigment.a = clampf((v-base).length()/span,0,1)
			leaves.set_color(pigment)
			leaves.set_normal(normal)
			leaves.add_vertex(v)

func _ward_wing() -> void:
	for side in [-1,1]:
		var origin := Vector3(side*8.0,0,-7.8)
		_box(origin+Vector3(0,1.81,0),Vector3(8.7,3.62,1.20),Color("#96998d"))
		_box(origin+Vector3(0,3.64,0),Vector3(8.82,.10,1.27),Color("#778079"))
		_box(origin+Vector3(0,.48,.63),Vector3(8.7,.96,.06),Color("#818779"))
		for bay in 7:
			var p := origin+Vector3((bay-3)*1.22,2.06,.64)
			_box(p,Vector3(.88,1.19,.04),Color("#666f68"))
			_box(p+Vector3(0,0,.026),Vector3(.78,1.07,.025),Color("#83938a"))
			_box(p+Vector3(0,.17,.046),Vector3(.79,.044,.025),Color("#727a6d"))
			_box(p+Vector3(0,-.60,.055),Vector3(.96,.053,.13),RIM)
