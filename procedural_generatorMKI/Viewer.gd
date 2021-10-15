extends Camera

var rot_x = self.rotation.x
var rot_y = self.rotation.y
var LOOKAROUND_SPEED = 0.05
var speed = 0.05

func _input(event):
	#print(event.as_text())
	if event is InputEventMouseMotion and event.button_mask & 1:
		# modify accumulated mouse rotation
		rot_x += event.relative.x * LOOKAROUND_SPEED
		rot_y += event.relative.y * LOOKAROUND_SPEED
		transform.basis = Basis() # reset rotation
		rotate_object_local(Vector3(0, 1, 0), rot_x) # first rotate in Y
		rotate_object_local(Vector3(1, 0, 0), rot_y) # then rotate in X
	
	if event is InputEventKey and event.pressed:
		if event.scancode == KEY_W: #move forward
			self.translate(Vector3(0, 0, -speed))
		if event.scancode == KEY_A: #move left
			self.translate(Vector3(-speed, 0, 0))
		if event.scancode == KEY_S: #move backwards
			self.translate(Vector3(0, 0, speed))
		if event.scancode == KEY_D: #move right
			self.translate(Vector3(speed, 0, 0))

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
