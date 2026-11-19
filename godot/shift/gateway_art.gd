extends Node2D

# Pixel coordinates share a 360 x 154 composition. The sides extend on wider screens.
const INK := Color("#182430")
const DEEP := Color("#202d39")
const SLATE := Color("#33434b")
const IRON := Color("#53636a")
const STEEL := Color("#87908d")
const SAGE := Color("#527a76")
const LIGHT := Color("#d1bd93")
const GILT := Color("#bc8857")
const GLOW := Color("#f4ca80")
const PAPER := Color("#e3d6ad")
const CLAY := Color("#a75b4a")

var profile := 0
var camera_x := 0.0
var walk_x := -35.0
var facing := 1
var walking := false
var time := 0.0
var aperture := 0.0
var page_taken := false
var photo_open := false
var glance_until := 0.0

func _process(delta: float) -> void:
	time += delta
	queue_redraw()

func rect(x: float,y: float,w: float,h: float,c: Color) -> void:
	draw_rect(Rect2(roundf(x),roundf(y),roundf(w),roundf(h)),c)

func stroke(x1: float,y1: float,x2: float,y2: float,c: Color,width := 1) -> void:
	draw_line(Vector2(roundf(x1),roundf(y1)),Vector2(roundf(x2),roundf(y2)),c,width,false)

func polygon(points: Array, fill: Color) -> void:
	var vertices := PackedVector2Array()
	for i in range(0,points.size(),2):
		vertices.append(Vector2(roundf(points[i]),roundf(points[i+1])))
	draw_colored_polygon(vertices,fill)

func _draw() -> void:
	var view := get_viewport_rect().size
	var zoom := view.y/154.0
	var width := ceilf(view.x/zoom)
	draw_set_transform(Vector2(view.x*.5,0),0,Vector2.ONE*zoom)
	if photo_open:
		draw_photo(view,zoom,width)
		return
	rect(-width*.5,0,width,154,DEEP)
	var left := -width*.5
	for i in range(floori((left+camera_x*.4)/64)-1,ceili((-left+camera_x*.4)/64)+1):
		var x := i*64-camera_x*.4
		rect(x,11,58,83,SLATE)
		for row in 4:
			rect(x+2,17+row*20,54,1,DEEP)
	for i in range(floori((left+camera_x)/60)-1,ceili((-left+camera_x)/60)+1):
		var x := i*60-camera_x
		rect(x,3,3,109,IRON)
		rect(x-2,6,7,5,STEEL)
		rect(x+1,29,2,78,SLATE)
		if i%3 == 0:
			rect(x+8,14,30,6,INK)
			rect(x+10,15,26,2,GLOW)
	for y in [9,22]:
		rect(left,y,width,3,INK)
		rect(left,y,width,1,IRON)
	rect(left,109,width,34,SLATE)
	rect(left,110,width,2,STEEL)
	for i in range(floori((left+camera_x)/34)-1,ceili((-left+camera_x)/34)+2):
		var x := i*34-camera_x
		stroke(x,112,x-13,143,DEEP)
	for y in [117,128,142]: rect(left,y,width,1,IRON)
	rect(left,143,width,11,INK)
	for i in range(4):
		var x := 166*i-camera_x
		if absf(x)>width/2+90:
			continue
		match i:
			0,1: desk(x,i==1)
			2: courier(x)
			3: gateway(x)
	person(walk_x-camera_x,133,walking,facing,profile)

func draw_photo(view: Vector2, zoom: float, width: float) -> void:
	rect(-width*.5,0,width,154,INK)
	# The camera printer repeats the same framing and freezes the sitter mid-keystroke.
	rect(-83,8,169,144,DEEP)
	rect(-86,4,169,144,PAPER)
	rect(-81,9,159,119,SLATE)
	polygon([-86,4,-54,4,-59,10,-86,13],LIGHT)
	draw_set_transform(Vector2(view.x*.5-1*zoom,-23*zoom),0,Vector2.ONE*zoom*1.31)
	desk(0,true,true)
	draw_set_transform(Vector2(view.x*.5,0),0,Vector2.ONE*zoom)
	draw_string(ThemeDB.fallback_font,Vector2(-77,141),"THU 17  /  16:00",HORIZONTAL_ALIGNMENT_LEFT,-1,10,INK)
	draw_string(ThemeDB.fallback_font,Vector2(56,141),"12",HORIZONTAL_ALIGNMENT_LEFT,-1,10,CLAY)

func desk(x: float, duplicate: bool, print_view := false) -> void:
	var accent := CLAY if duplicate else SAGE
	rect(x-51,31,103,76,INK)
	rect(x-49,33,99,72,SLATE)
	rect(x-42,39,30,61,IRON)
	for j in range(5):
		rect(x-41,41+j*11,28,9,SLATE)
		rect(x-31,43+j*11,9,2,LIGHT)
	rect(x-3,40,45,27,accent)
	rect(x+1,43,37,21,INK)
	rect(x+5,46,29,2,GLOW)
	rect(x+5,51,19,1,STEEL)
	rect(x+5,55,24,1,STEEL)
	if duplicate:
		var reading := not print_view and (time < glance_until or fmod(time,7.2)>5.8)
		seated_double(x-17,reading,print_view)
	rect(x+1,92,51,18,DEEP)
	rect(x-20,90,78,4,GILT)
	rect(x-18,94,3,18,IRON)
	rect(x+52,94,3,18,IRON)
	# A cup, a broken ring in the varnish and the bent drawer label identify the copy.
	rect(x+17,81,7,8,LIGHT)
	rect(x+23,82,3,1,LIGHT)
	rect(x+25,83,1,3,LIGHT)
	rect(x+23,86,3,1,LIGHT)
	rect(x+18,81,5,1,INK)
	rect(x+8,90,6,1,CLAY)
	rect(x+7,89,1,1,CLAY)
	rect(x-37,67,7,2,GILT)
	rect(x-4,65,31,24,LIGHT)
	rect(x-2,67,26,18,DEEP)
	for j in range(3):
		rect(x+1,70+j*4,12+j*2,1,SAGE)
	rect(x+5,89,14,1,STEEL)
	polygon([x-13,90,x-9,86,x+7,86,x+9,90],IRON)
	if duplicate and not page_taken:
		polygon([x+28,88,x+38,84,x+46,87,x+37,90],PAPER)
		stroke(x+34,88,x+38,86,CLAY)
	else:
		rect(x+31,85,9,4,CLAY)
	rect(x-40,27,20,9,accent)
	rect(x-36,30,6,1,PAPER)
	if duplicate:
		rect(x-27,30,3,1,PAPER)
		# Transfer slip, still clipped to the board after its release was cancelled.
		rect(x+30,63,10,14,PAPER)
		rect(x+33,62,4,2,IRON)
		rect(x+31,67,8,2,CLAY)
		rect(x+32,72,5,1,SLATE)

func seated_double(x: float, glancing: bool, frozen: bool) -> void:
	# Weight shifts onto the chair back, then the sitter looks over a shoulder.
	var glance := 0.0
	if glancing:
		var remaining := glance_until-time
		var cycle := fmod(time,7.2)
		if remaining>0.0:
			glance = smoothstep(0.0,.43,3.2-remaining)*smoothstep(0.0,.35,remaining)
		else:
			glance = smoothstep(5.8,6.2,cycle)*smoothstep(0.0,.3,7.2-cycle)
	var keypress := roundf(sin(time*8.0)) if not frozen and not glancing else 0.0
	var shoulder_x := x+3.0-3.0*glance
	var shoulder_y := 76.0-3.0*glance
	rect(x-11,80,2,26,IRON)
	rect(x-11,95,16,2,STEEL)
	polygon([x-5,89,x+3,88,x+11,94,x+11,104,x+8,104,x+6,97,x-3,96],INK)
	rect(x+8,103,8,3,IRON)
	jacket(shoulder_x,shoulder_y,1,profile,17)
	var cuff := Vector2(x+5+glance*3,85+keypress)
	arm(Vector2(shoulder_x-3,shoulder_y+2),Vector2(x-5,88),cuff,profile)
	stroke(cuff.x,cuff.y,cuff.x+4,cuff.y+1,SKINS[profile],2)
	var head_x := shoulder_x+1-glance*3
	portrait(head_x,shoulder_y+1+keypress*(1-glance),-1 if glance>.5 else 1,profile,glance>.25 and glance<.72)

func courier(x: float) -> void:
	rect(x-41,31,87,75,INK)
	rect(x-39,33,83,71,SLATE)
	for j in 7:
		rect(x-35+j*11,39,9,19,IRON)
		rect(x-34+j*11,42,7,2,INK)
		rect(x-33+j*11,52,4,2,LIGHT)
	rect(x-40,63,82,3,GILT)
	var y := roundf(sin(time*2.8))
	rect(x-15,82+y,32,21,SAGE)
	rect(x-17,83+y,36,3,GILT)
	rect(x-11,103+y,5,7,INK)
	rect(x+9,103+y,5,7,INK)
	rect(x-2,76+y,4,6,STEEL)
	rect(x-12,64+y,23,13,LIGHT)
	rect(x-11,68+y,20,4,INK)
	rect(x-6,69+y,3,2,GLOW)
	rect(x+2,69+y,3,2,GLOW)
	rect(x+11,62+y,1,7,IRON)
	rect(x+10,60+y,3,3,CLAY)
	rect(x-9,89+y,17,9,DEEP)
	rect(x-6,91+y,11,3,PAPER)
	rect(x-8,93+y,15,2,IRON)
	stroke(x+15,88+y,x+21,91+y,STEEL,3)
	stroke(x-14,87+y,x-22,83+y,STEEL,3)

func gateway(x: float) -> void:
	rect(x-31,29,66,81,INK)
	rect(x-35,27,73,8,IRON)
	rect(x-32,35,6,75,STEEL)
	rect(x+27,35,6,75,IRON)
	for j in 8:
		var y := 37+j*9-aperture*78
		if y<36: continue
		rect(x-25,y,51,8,SLATE)
		rect(x-25,y+1,51,1,IRON)
	for j in 3:
		rect(x-9+7*j,30,4,2,GLOW)
	rect(x+39,58,15,22,IRON)
	rect(x+41,61,11,10,INK)
	rect(x+43,66,6,1,GLOW)
	rect(x+43,74,3,2,CLAY)

# Each sprite shares a joint scale. The inked silhouettes stay separate from the
# steel fixtures even when the portrait is reproduced on the contact print.
const COATS := [Color("#9c5846"),Color("#68877b"),Color("#555669")]
const COAT_SHADOW := [Color("#633f3e"),Color("#3b5756"),Color("#353a48")]
const SKINS := [Color("#be8666"),Color("#d2a387"),Color("#b88973")]
const MIDS := [Color("#9b6857"),Color("#a97a64"),Color("#916a60")]
const LIT := [Color("#d5a17b"),Color("#e2bc96"),Color("#d1a485")]
const NAPE := [Color("#392f36"),Color("#51403c"),Color("#38353e")]
const CHEEK := [
	"  hhhhhh    ",
	" hhhhhhhh   ",
	"hhhhhhmmmm  ",
	"hhhhhmmlll  ",
	"hhhhmsstsl  ",
	" hhmmssekl  ",
	" hhmsssssll ",
	" hmmmmsmsll ",
	"  hmmsmsms  ",
	"  hmmmsskk  ",
	"   mmmsssl  ",
	"   mmmssl   ",
	"   mmss     "
]
const TURNING := [
	"  hhhhhhh   ",
	" hhhhhhhhh  ",
	"hhhmmmsllhh ",
	"hhmmsssssll ",
	" hmtkssstk  ",
	" hmekslsel  ",
	" hmsmslmssl ",
	"  mssmmsms  ",
	"  mmssslss  ",
	"   msnkkls  ",
	"   mmsssl   ",
	"    mssl    ",
	"    mss     "
]

func portrait(x: float, neck_y: float, direction: int, outfit: int, turning := false) -> void:
	var sprite: Array = TURNING if turning else CHEEK
	var xx := roundf(x)
	var top := roundf(neck_y)-13
	var key := {"h":NAPE[outfit],"m":MIDS[outfit],"s":SKINS[outfit],"l":LIT[outfit],"t":NAPE[outfit],"e":PAPER,"k":INK,"n":MIDS[outfit]}
	for row in sprite.size():
		var line: String = sprite[row]
		for col in line.length():
			var mark := line.substr(col,1)
			if mark != " ":
				rect(xx+(col-5)*direction,top+row,1,1,key[mark])
	match outfit:
		0:
			polygon([xx-direction*3,top+2,xx-direction*6,top+1,xx-direction*8,top+3,xx-direction*8,top+6,xx-direction*5,top+8,xx-direction*3,top+7],NAPE[0])
			stroke(xx-direction*7,top+3,xx-direction*5,top+2,Color("#69483e"))
			rect(xx-direction*4,top+5,1,3,GILT)
		1:
			# Thin square lenses, with the bridge and temple visible in profile.
			stroke(xx-direction*3,top+5,xx+direction,top+5,IRON)
			stroke(xx+direction,top+5,xx+direction*5,top+5,INK)
			stroke(xx+direction*5,top+5,xx+direction*4,top+7,INK)
			stroke(xx+direction*4,top+7,xx+direction,top+7,IRON)
			rect(xx+direction*2,top+5,2,1,LIGHT)
			stroke(xx-direction*4,top+3,xx,top+1,Color("#796052"))
		2:
			# The silver part is oblique; the short tail rests against the collar.
			polygon([xx-direction*3,top+4,xx-direction*6,top+6,xx-direction*7,top+12,xx-direction*5,top+14,xx-direction*3,top+10],NAPE[2])
			stroke(xx-direction*4,top+5,xx-direction,top+1,STEEL)
			stroke(xx-direction,top+1,xx+direction*2,top+2,IRON)

func jacket(x: float,y: float, direction: int, outfit: int, length: float) -> void:
	var coat: Color = COATS[outfit]
	var shade: Color = COAT_SHADOW[outfit]
	polygon([x-4,y,x+3,y,x+6,y+2,x+5,y+8,x+4,y+length-3,x+6,y+length,x-6,y+length,x-5,y+8,x-7,y+3],coat)
	polygon([x-5*direction,y+3,x-3*direction,y+2,x-1*direction,y+8,x-3*direction,y+length-2,x-6*direction,y+length,x-4*direction,y+10],shade)
	stroke(x+direction*2,y+5,x+direction*2,y+length-2,shade)
	stroke(x-direction*4,y+length-1,x+direction*4,y+length-1,shade)
	match outfit:
		0:
			polygon([x-4,y-1,x+4,y,x+5,y+2,x+1,y+4,x-5,y+2],GILT)
			polygon([x-3*direction,y+2,x,y+3,x-direction*2,y+10,x-direction*4,y+12,x-direction*4,y+9],GLOW)
		1:
			polygon([x-3,y,x,y+3,x+3,y,x+2,y+6,x,y+5],LIGHT)
			rect(x+direction,y+9,3,3,shade)
			rect(x+direction,y+9,3,1,STEEL)
		2:
			stroke(x+3*direction,y+2,x-4*direction,y+12,LIGHT,2)
			rect(x+direction*2,y+4,2,2,GILT)
			rect(x-direction*5,y+12,5,4,shade)

func arm(shoulder: Vector2, elbow: Vector2, cuff: Vector2, outfit: int) -> void:
	stroke(shoulder.x,shoulder.y,elbow.x,elbow.y,COAT_SHADOW[outfit],4)
	stroke(elbow.x,elbow.y,cuff.x,cuff.y,COATS[outfit],3)
	stroke(cuff.x-1,cuff.y,cuff.x+1,cuff.y,COAT_SHADOW[outfit],2)

func person(x: float, y: float, is_moving: bool, direction: int, outfit: int) -> void:
	var pace := roundf(sin(time*8.5)*4) if is_moving else 0.0
	var rise := 1.0 if is_moving and absf(pace)>2 else 0.0
	var shoulder_y := y-32+rise
	rect(x-9,y,18,1,DEEP)
	for leg: int in [-1,1]:
		var knee := x+leg*3+pace*leg*.5
		var ankle := x+leg*3+pace*leg
		var trouser := INK if leg==-1 else Color("#424850")
		stroke(x+leg*2,shoulder_y+14,knee,y-9,trouser,4)
		stroke(knee,y-9,ankle,y-2,trouser,3)
		stroke(ankle-1*direction,y-1,ankle+4*direction,y-1,INK,2)
		rect(ankle+direction*2,y,3,1,STEEL)
	jacket(x,shoulder_y,direction,outfit,16)
	var cuff := Vector2(x+3*direction-pace*.9,shoulder_y+13)
	arm(Vector2(x+2*direction,shoulder_y+2),Vector2(x+1*direction-pace*.5,shoulder_y+8),cuff,outfit)
	rect(cuff.x-1,cuff.y+1,3,3,SKINS[outfit])
	portrait(x,shoulder_y+1,direction,outfit)
