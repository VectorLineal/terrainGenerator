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
		if event.scancode == KEY_W:
			#var mov_x = sin(self.rotation.y) #* cos(self.rotation.z)
			#var mov_y = sin(self.rotation.x) #* sin(self.rotation.z)
			#var mov_z = cos(self.rotation.x) * cos(self.rotation.y)
			#print("W was pressed", self.rotation_degrees, "is unit: ", pow(mov_x, 2) + pow(mov_y, 2) + pow(mov_z, 2))
			#print("moves in x: ", mov_x, ", in y: ", mov_y,  ", in z: ", mov_z)
			self.translate(Vector3(0, 0, -speed))
			#self.translate(Vector3(-speed * mov_x, speed * mov_y, -speed * mov_z))
		if event.scancode == KEY_A:
			self.translate(Vector3(-speed, 0, 0))
		if event.scancode == KEY_S:
			self.translate(Vector3(0, 0, speed))
			#self.translate(Vector3(0, -speed * sin(self.rot_x), speed * cos(self.rot_x)))
			#self.translate(Vector3(speed * sin(self.rot_y), 0, speed * cos(self.rot_y)))
		if event.scancode == KEY_D:
			self.translate(Vector3(speed, 0, 0))

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
