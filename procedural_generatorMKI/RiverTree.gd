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
			next_flow = current_node.get_flow() + random_gen.randf_range(- flow_variation / 2.0, flow_variation)
			var next_path: Array = []
			cur_x = current_node.position.x
			cur_y = current_node.position.y
			cur_point = Vector2(cur_x, cur_y)
			var rejection_list: Array = []
			print("next point: ", next_point)
			while not (cur_x == next_x and cur_y == next_y):
				#print("current: ", Vector2(cur_x, cur_y))
				cur_point = get_next_path(cur_point, current_node.position, next_point, next_path, rejection_list, max_l, image)
				cur_x = cur_point.x
				cur_y = cur_point.y
				if not next_path.has(cur_point):
					next_path.append(cur_point)
			#print("river final size: ", next_path.size())
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

func draw(heightImage: Image, image: Image, rng: RandomNumberGenerator):
	draw_tree(self.head, heightImage, image, rng)

func draw_tree(current_node: NodeTree, heightImage: Image, image: Image, rng: RandomNumberGenerator):
	print("drawing node: ", current_node.position, " with flux: ", current_node.flow)
	if current_node.has_left():
		var mean_flow = (current_node.get_flow() + current_node.son_left.get_flow()) / 2.0
		create_river_in_nodes(mean_flow, current_node.path_l, heightImage, image, rng)
		print("created river to: ", current_node.son_left.position, " with flux: ", mean_flow)
		draw_tree(current_node.son_left, heightImage, image, rng)
	if current_node.has_right():
		var mean_flow = (current_node.get_flow() + current_node.son_right.get_flow()) / 2.0
		create_river_in_nodes(mean_flow, current_node.path_r, heightImage, image, rng)
		print("created river to: ", current_node.son_right.position, " with flux: ", mean_flow)
		draw_tree(current_node.son_right, heightImage, image, rng)

func create_river_in_nodes(flow: float, path: Array, heightImage: Image, image: Image, rng: RandomNumberGenerator):
	#esta variable crece a medida que el río deciende de la montaña
	var type: float = rng.randf() * 0.1
	var width: float = flow * (1.0 - type)
	#var width: float = flow
	var next_slope: float = 0.05 * flow * type
	var slope_degradation = flow * type * 0.0001
	for j in range(path.size() - 1, -1, -1):
		#si se llega a un punto que ya es un río se detiene el agente, así quedan ríos afluentes
		var next_direction: Array = [0, 0]
		if j < path.size() - 1:
			next_direction[0] = int(path[j].x - path[j + 1].x)
			next_direction[1] = int(path[j].y - path[j + 1].y)
		else:
			next_direction[0] = int(path[j].x - path[j - 1].x)
			next_direction[1] = int(path[j].y - path[j - 1].y)
		#se crea el area de río luego se aumenta su ancho a medida que baja de la montaña
		make_river(path[j], next_direction, int(width), next_slope, heightImage, image)
		next_slope += rng.randf_range(slope_degradation / 4.0, slope_degradation)
		width += 0.2 * slope_degradation

#esta función aplana los puntos perpendiculares al punto creando un area hundida
func make_river(cur_point: Vector2, next_direction: Array, width: int, next_slope: float, heightImage: Image, image: Image):
	var perpendicular_directions = MathUtils.get_perpendicular_grids(next_direction)
	var elevation: float = next_slope
	#se obtiene la altura actual y se asegura que no rebase 1
	heightImage.lock()
	var height = heightImage.get_pixel(cur_point.x, cur_point.y).r
	heightImage.unlock()
	var next_height: float = height - next_slope
	#no se peden tener alturas negativas
	if next_height < 0.0:
		#print("too low")
		next_height = 0.0
	heightImage.lock()
	heightImage.set_pixel(cur_point.x, cur_point.y, Color(next_height, next_height, next_height, 1))
	heightImage.unlock()
	#se marca como río en mapa de biomas
	MathUtils.paint_river(cur_point.x, cur_point.y, image)
	for j in width:
		var left_x = cur_point.x + perpendicular_directions[0][0] * (1 + j)
		var left_y = cur_point.y + perpendicular_directions[0][1] * (1 + j)
				
		var right_x = cur_point.x + perpendicular_directions[1][0] * (1 + j)
		var right_y = cur_point.y + perpendicular_directions[1][1] * (1 + j)
		#print("next left: ", left_x, ", ", left_y, "; right: ", right_x, ", ", right_y)
		#se asegura que las nuevas coordenadas estén dentro del mapa además debe haber elevación o el proceso no tendría sentido
		if left_x >= 0 and left_x < heightImage.get_width() and left_y >= 0 and left_y < heightImage.get_height():
			#se pone la nueva altura
			heightImage.lock()
			heightImage.set_pixel(left_x, left_y, Color(next_height, next_height, next_height, 1))
			heightImage.unlock()
			MathUtils.paint_river(left_x, left_y, image)
			#se aplana
			MathUtils.flatten_basic(Vector2(left_x, left_y), heightImage)
		if right_x >= 0 and right_x < heightImage.get_width() and right_y >= 0 and right_y < heightImage.get_height():
			#se pone la nueva altura
			heightImage.lock()
			heightImage.set_pixel(right_x, right_y, Color(next_height, next_height, next_height, 1))
			heightImage.unlock()
			MathUtils.paint_river(right_x, right_y, image)
			#se aplana
			MathUtils.flatten_basic(Vector2(right_x, right_y), heightImage)
	#se aplana la nueva altura
	MathUtils.flatten_basic(cur_point, heightImage)
	MathUtils.flatten_around_basic(cur_point, heightImage)

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

func get_next_path(point: Vector2, parent: Vector2, son: Vector2, cur_path: Array, reject_l: Array, max_l: int, heightImage: Array):
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
		if next_x >= 0 and next_x < heightImage[0].size() and next_y >= 0 and next_y < heightImage.size():
			#print("candidate: ", Vector2(next_x, next_y))
			#el punto siguiente está dentro del area cercana al nodo padre del río
			if (MathUtils.is_point_into_circle(son.x, son.y, max_l, next_x, next_y) or MathUtils.is_point_into_circle(parent.x, parent.y, max_l, next_x, next_y)) and not cur_path.has(Vector2(next_x, next_y)) and not reject_l.has(Vector2(next_x, next_y)):
				var slope_i = heightImage[next_x][next_y]
				var score = -15000 * slope_i - MathUtils.sqr_dst(next_x, next_y, m_x, m_y)
				#print("slope: ", slope_i, ", sqr distance: ", MathUtils.sqr_dst(next_x, next_y, m_x, m_y))
				if score > cur_score:
					cur_score = score
					next_point = Vector2(next_x, next_y)
	#en caso que no se pueda tomar un punto nuevo, se retrocede y se marca el punto tomado para que no se pueda volver a usar
	if next_point == point:
		#print("no hay candidatos")
		reject_l.append(point)
		if cur_path.has(point):
			cur_path.erase(point)
		#se toma el punto anterior como punto actual
		next_point = cur_path[cur_path.size() - 1]
		print("no candidates with current: ",  point, " and next: ", next_point)
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
