extends MeshInstance3D
## The hand-knit scarf Mara adjusts. Local +Z is the wearer's chest.

const OCHRE := Color("#cd9b52")
const PURL := Color("#ba894b")
const HEM := Color("#916942")
const STITCHES := 60

func _init() -> void:
	var cloth := SurfaceTool.new()
	cloth.begin(Mesh.PRIMITIVE_TRIANGLES)
	for step in STITCHES:
		var a := TAU * step / STITCHES
		var b := TAU * (step + 1) / STITCHES
		for row in 7:
			var tint := [PURL, OCHRE, OCHRE, PURL, OCHRE, OCHRE, PURL][row] as Color
			_quad(cloth, _loop(a,row), _loop(b,row), _loop(b,row+1), _loop(a,row+1), tint)
	# One end falls under the knot. The other has a short woven border and fringe.
	_tail(cloth, -.063, .248, -.025, .139)
	_tail(cloth, .012, .133, .030, .151)
	cloth.generate_normals()
	mesh = cloth.commit()
	var wool := ShaderMaterial.new()
	wool.shader = preload("res://casting/wool.gdshader")
	material_override = wool

func _loop(a: float, row: int) -> Vector3:
	var radii := [.100,.118,.123,.118,.120,.112,.104,.087]
	var heights := [-.060,-.055,-.043,-.031,-.019,-.007,.005,.010]
	var front := cos(a)
	var dip := maxf(0,front)
	var r: float = radii[row] + .004 * sin(3*a+row*.13)
	return Vector3(sin(a)*r, heights[row] - .044*dip + .012*sin(a), front*(r+.017*dip-.024*maxf(0,-front)))

func _tail_point(offset: float, length: float, slope: float, depth: float, u: float, v: float) -> Vector3:
	var width := lerpf(.036,.043,v)
	return Vector3(offset+u*width+slope*v+.008*sin(v*PI), -.055-length*v+.005*u, depth+.058*sin(.5*PI*v)+.008*cos(u*PI+.9*v))

func _tail(cloth: SurfaceTool, x: float, length: float, drift: float, z: float) -> void:
	var rows := [0.0,.22,.43,.64,.76,.79,.82,.87,.9,.93,1.0]
	for j in rows.size()-1:
		for i in 6:
			var a := (i-3.0)/3.0
			var b := (i-2.0)/3.0
			var tint := OCHRE
			if j in [5,8]: tint = HEM
			elif i in [0,4] or j == 9: tint = PURL
			_quad(cloth, _tail_point(x,length,drift,z,a,rows[j]), _tail_point(x,length,drift,z,b,rows[j]), _tail_point(x,length,drift,z,b,rows[j+1]), _tail_point(x,length,drift,z,a,rows[j+1]), tint)
	for i in 12:
		var u := (i-5.5)/6.0
		var tip := _tail_point(x,length,drift,z,u,1)
		var end := tip+Vector3(.002*sin(i),-.011-.003*cos(i),-.002)
		var width := Vector3(.0016,0,0)
		_quad(cloth,tip-width,tip+width,end+width,end-width,PURL)

func _quad(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, color: Color) -> void:
	surface.set_color(color)
	for vertex: Vector3 in [a,d,b,b,d,c]:
		surface.add_vertex(vertex)
