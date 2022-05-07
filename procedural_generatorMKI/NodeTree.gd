class_name NodeTree

var position: Vector2
var type: int
var flow
var son_left: NodeTree
var path_l: Array = []
var son_right: NodeTree
var path_r: Array = []

func _init(pos: Vector2, f = 0, t: int = 0):
	position = pos
	type = t
	flow = f
	
func get_priority():
	var size_l = 1
	var size_r = 1
	if has_left():
		size_l += son_left.get_priority()
	if has_right():
		size_r += son_right.get_priority()
	return max(size_l, size_r)

func get_flow():
	return flow

func has_left():
	return son_left != null

func has_right():
	return son_right != null

func may_breed():
	return son_left == null or son_right == null

func add_child(path: Array, son: NodeTree):
	if not has_left():
		self.path_l = path
		self.son_left = son
	elif not has_right():
		self.path_r = path
		self.son_right = son
	else:
		print("Node is full")
