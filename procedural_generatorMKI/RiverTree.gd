class_name RiverTree

var head: NodeTree
var available_nodes: Array = []
var positions: Array = []

func _init(position, flow):
	self.head = NodeTree.new(position, flow)
	self.available_nodes.append(self.head)
	self.positions.append(position)

#se aplica cuando solo existe head en el árbol
func expand(min_l: int, max_l: int, flow_variation: int, expansion: int, image: Array, random_gen: RandomNumberGenerator):
	var current_node: NodeTree = head
	var availability_mat: Array
	var posible_list: Array
	var next_index: int
	var next_x: int
	var next_y: int
	var next_point: Vector2
	var next_flow: int
	var next_path: Array = []
	var cur_x: int
	var cur_y: int
	var cur_point: Vector2
	var next_child: NodeTree
	for i in expansion:
		availability_mat = generate_availability_map_point(current_node.position, min_l, max_l, image)
		posible_list = get_availability_lis(availability_mat)
		if not posible_list.empty():
			next_index = random_gen.randi_range(0, posible_list.size() - 1)
			next_x = posible_list[next_index].x
			next_y = posible_list[next_index].y
			next_point = Vector2(next_x, next_y)
			next_flow = current_node.get_flow() + flow_variation
			next_path.clear()
			cur_x = current_node.position.x
			cur_y = current_node.position.y
			cur_point = Vector2(cur_x, cur_y)
			print("next point: ", next_point)
			while not (cur_x == next_x and cur_y == next_y):
				#print("current: ", Vector2(cur_x, cur_y))
				cur_point = get_next_path(cur_point, current_node.position, next_point, next_path, max_l, image)
				cur_x = cur_point.x
				cur_y = cur_point.y
				next_path.append(cur_point)
			print("river final size: ", next_path.size())
			next_child = NodeTree.new(next_point, next_flow)
			current_node.add_child(next_path, next_child)
			available_nodes.append(next_child)
			positions.append(next_point)
			if  image[current_node.position.y][current_node.position.x] >= image[next_child.position.y][next_child.position.x]:
				if not current_node.may_breed():
					available_nodes.erase(current_node)
				current_node = pick_next_node(image)
			elif not current_node.may_breed():
				available_nodes.erase(current_node)
				current_node = pick_next_node(image)
			print("next node: ", current_node.position)
		else:
			available_nodes.erase(current_node)
			if not available_nodes.empty():
				current_node = pick_next_node(image)
			else:
				print("unable to find new path in iteration ", i)
				break

func pick_next_node(slope_map: Array):
	var counter = 0
	var min_slope = 2
	var min_priority = 5000000
	for n in self.available_nodes.size():
		var position = self.available_nodes[n].position
		var priority = self.available_nodes[n].get_priority()
		var slope = slope_map[position.y][position.x]
		if slope < min_slope:
			min_slope = slope
			min_priority = priority
			counter = n
		elif slope == min_slope:
			if priority < min_priority:
				min_priority = priority
				counter = n
	return self.available_nodes[counter]

func get_next_path(point: Vector2, parent: Vector2, son: Vector2, cur_path: Array, max_l: int, heightImage: Array):
	var x = point.x
	var y = point.y
	var m_x = son.x
	var m_y = son.y
	var next_point: Vector2 = Vector2(x, y)
	var cur_score = -10000000000
	for i in MathUtils.fullNeighbourhood.size():
		var next_x = x + MathUtils.fullNeighbourhood[i].x
		var next_y = y + MathUtils.fullNeighbourhood[i].y
		#El vecindario debe quedar dentro de los constraints del mapa
		if next_x >= 0 and next_x < heightImage.size() and next_y >= 0 and next_y < heightImage[0].size():
			#print("candidate: ", Vector2(next_x, next_y))
			#el punto siguiente está dentro del area cercana al nodo padre del río
			if MathUtils.is_point_into_circle(parent.x, parent.y, max_l, next_x, next_y) and not cur_path.has(Vector2(next_x, next_y)) and not(next_x == x and next_y == y):
				var slope_i = heightImage[next_x][next_y]
				var score = -15000 * slope_i - MathUtils.sqr_dst(next_x, next_y, m_x, m_y)
				#print("slope: ", slope_i, ", sqr distance: ", MathUtils.sqr_dst(next_x, next_y, m_x, m_y))
				if score > cur_score:
					cur_score = score
					next_point = Vector2(next_x, next_y)
			
	return next_point

func is_point_too_close(x: int, y: int, min_l: int):
	for p in self.positions:
		if MathUtils.is_point_into_circle(p.x, p.y, min_l, x, y):
			return true
	return false
#genera una matriz booleana que indica si la casilla está fuera de los límites para crear el río
func generate_availability_map(min_l: int, image: Array):
	var mat: Array = MathUtils.create_boolean_matrix(image.size(), image[0].size())
	for y in mat.size():
		for x in mat[0].size():
			mat[y][x] = not is_point_too_close(x, y, min_l)
	return mat
#genera una matriz booleana que indica si la casilla está fuera de los límites para crear el río
func generate_availability_map_point(p: Vector2, min_l: int, max_l: int, image: Array):
	var mat: Array = MathUtils.create_boolean_matrix(image.size(), image[0].size())
	for y in mat.size():
		for x in mat[0].size():
			#el punto no está dentro del rango de los demás nodos, pero si está dentro del rango máximo respecto a su nodo padre
			mat[y][x] = (not is_point_too_close(x, y, min_l)) and  MathUtils.is_point_into_circle(p.x, p.y, max_l, x, y)
	return mat
#a partir de una matriz booleana retorna todas las pocisiones que tienen verdadero
func get_availability_lis(mat: Array):
	var list: Array = []
	for y in mat.size():
		for x in mat[0].size():
			if mat[y][x]:
				list.append(Vector2(x, y))
	return list
