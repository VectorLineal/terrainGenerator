class_name MathUtils

static func int_pow(a, b: int):
	if b <= 0:
		return 1
	var r = 1
	for i in b:
		r *= a
	return r

#indica si el punto dado está dentro de la circunferencia
static func is_point_into_circle(c_x, c_y, radius, p_x, p_y):
	return int_pow(radius, 2) >= int_pow(p_x - c_x, 2) + int_pow(p_y - c_y, 2)

#modified Von Neumann neighbourhood
const neighbourhood = [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]
const fullNeighbourhood = [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1), Vector2(0, -1), Vector2(1, 0), Vector2(0, 1), Vector2(-1, 0)]

#genera un booleano aleatorio
static func random_bool(random_gen: RandomNumberGenerator):
	return random_gen.randi_range (0, 1) == 0

#genera -1 o 1 aleatoriamente
static func random_sign(random_gen: RandomNumberGenerator):
	if random_bool(random_gen):
		return 1
	else:
		return -1

#interpola el valor v de iMin, iMax en el dominio de oMin, oMax
static func remap(iMin, iMax, oMin, oMax, v):
	var t = inverse_lerp(iMin, iMax, v)
	return lerp(oMin, oMax, t)

#distancia cuadrada entre 2 puntos
static func sqr_dst(in_x, in_y, fin_x, fin_y):
	return pow(fin_x - in_x, 2) + pow(fin_y - in_y, 2)
	
#genera vector unitario aleatorio con componentes entre [-1, 1]
static func generate_random_normal(random_gen: RandomNumberGenerator):
	var v = Vector2(random_gen.randf_range(-1, 1), random_gen.randf_range(-1, 1))
	return v.normalized()

#calcula el punto del borde más cercano al punto dado
static func get_closest_border(point: Vector2, size: Vector2):
	var x_distance = min(point.x, size.x - 1 - point.x)
	var y_distance = min(point.y, size.y - 1 - point.y)
	var edge = Vector2(0, 0)
	if x_distance >= y_distance:
		edge.x = point.x
		if y_distance == point.y:
			edge.y = 0
		else:
			edge.y = size.y - 1
	else:
		edge.y = point.y
		if x_distance == point.x:
			edge.x = 0
		else:
			edge.x = size.x - 1
	#print("point: ", point, "distances x: ", x_distance, ", y: ", y_distance, ", edge: ", edge)
	return edge
	
#retorna el índice de un vector si se encuentra en el arreglo, de lo contrario retorna -1
static func get_element_index(v: Vector2, list: Array):
	for i in list.size():
		if list[i].x == v.x && list[i].y == v.y:
			return i
	return -1
	
#calcula las medidas estadísticas del mapa de inclinaciones, promedio, desviación estándar y puntaje de erosión.
static func calculate_scores(image: Image):
	var acumulator = 0
	image.lock()
	#Se revisa el mapa de inclinación, tercer componente del mapa de biomas
	for y in image.get_height():
		for x in image.get_width():
			acumulator += image.get_pixel(x, y).g
	var mean = acumulator / (image.get_height() * image.get_width())
	
	#se calcula la desviación estándar teniendo ya el promedio
	acumulator = 0
	for y in image.get_height():
		for x in image.get_width():
			acumulator += pow(image.get_pixel(x, y).g - mean, 2)
	var desviation = sqrt(acumulator / (image.get_height() * image.get_width()))
	#la media no puede ser 0 o generará indeterminación
	if mean == 0: mean += 0.00000000001
	#el puntaje de erosión se calcula con base en la propuesta de Olsen
	var score = desviation / mean
	image.unlock()
	return Vector3(mean, desviation, score)

#A partir de un vector, retorna una dirección en una cuadrícula
static func angle_to_grid(v: Vector2): #vector con componentes entre [-1, 1]
	var ang = v.angle()
	if ang >= -PI / 8 and ang < PI / 8:
		return [1, 0]
	elif ang >= PI / 8 and ang < 3 * PI / 8:
		return [1, 1]
	elif ang >= -3 * PI / 8 and ang < -PI / 8:
		return [1, -1]
	elif ang >= -5 * PI / 8 and ang < -3 * PI / 8:
		return [0, -1]
	elif ang >= -7 * PI / 8 and ang < -5 * PI / 8:
		return [-1, -1]
	elif ang >= 3 * PI / 8 and ang < 5 * PI / 8:
		return [0, 1]
	elif ang >= 5 * PI / 8 and ang < 7 * PI / 8:
		return [-1, 1]
	else:
		return [-1, 0]

#dada una dirección de cambio en una grilla, elige sus 2 direcciones perpendiculares
static func get_perpendicular_grids(direction: Array): #arreglo de 2 componentes
	if direction[0] == 0 and direction[1] == 0:
		return [[0, 0], [0, 0]]
	var results: Array = [[0, 0], [0, 0]]
	if direction[0] == 0:
		results[0] = [-1, 0]
		results[1] = [1, 0]
	elif direction[1] == 0:
		results[0] = [0, -1]
		results[1] = [0, 1]
	elif direction[0] == direction[1]:
		results[0] = [1, -1]
		results[1] = [-1, 1]
	else:
		results[0] = [1, 1]
		results[1] = [-1, -1]
	return results

#retorna la coordenada en el vecindario al rotar 45° por izquierda o derecha
static func rotate_45_grid(direction: Array, status: int):
	#status puede ser -1, 0, 1, status 0 implica ninguna rotación
	if status == 0:
		return direction
	elif status < -1:
		status = -1
	elif status > 1:
		status = 1
	
	var results: Array = [0, 0]
	if direction[0] == 0 && direction[1] == -1:
		results[0] = status
		results[1] = direction[1]
	elif direction[0] == 0 && direction[1] == 1:
		results[0] = -status
		results[1] = direction[1]
	elif direction[1] == 0 && direction[0] == 1:
		results[0] = direction[0]
		results[1] = status
	elif direction[1] == 0 && direction[0] == -1:
		results[0] = direction[0]
		results[1] = -status
	elif direction[0] == direction[1]:
		if status == -1:
			results[0] = direction[0]
			results[1] = 0
		else:
			results[0] = 0
			results[1] = direction[1]
	else:
		if status == -1:
			results[0] = 0
			results[1] = direction[1]
		else:
			results[0] = direction[0]
			results[1] = 0
	return results

static func vec_to_grid(origin: Vector2, v: Vector2, size: Vector2, maxRange: float): #vector v con componentes entre [-1, 1]
	#var ang = v.angle()
	#se calculan los equivalentes de los vectores en el mapa
	var deltaX = floor(lerp(0, (size.x - 1) * maxRange, abs(v.x)))
	var deltaY = floor(lerp(0, (size.y - 1) * maxRange, abs(v.y)))
	if v.x < 0:
		deltaX *= -1
	if v.y < 0:
		deltaY *= -1
	#se calculan las nuevas coordenadas donde apunta el vector
	var nextX = origin.x + deltaX
	var nextY = origin.y + deltaY
	#se asegura que los valores estén dentro de las coordenadas
	if nextX < 0:
		nextX = 0
	elif nextX >= size.x:
		nextX = size.x - 1
		
	if nextY < 0:
		nextY = 0
	elif nextY >= size.y:
		nextY = size.y - 1
	
	return [floor(nextX), floor(nextY)]

#genera un campo vectorial de vectores aleatorios R2 con componentes entre [-1, 1]
static func generate_vectorial_fractal_field(width: int, height: int, rng: RandomNumberGenerator):
	#En el peor de los casos, genera un valor máximo de 3, la suma de sus componentes de los vectores de los 4 extremos
	var field = []
	var inital_vecs = []
	var extremes = [Vector2(0,0), Vector2(0,height - 1), Vector2(width - 1,0), Vector2(width - 1,height - 1)]
	#máxima distancia de extremo a extremo de la cuadrícula
	var max_square_dist = sqr_dst(0, 0, width - 1, height - 1)
	#inicialmente se ponen vectores aleatorios para las 4 esquinas de la cuadrícula, el resto se inicia en 0,0 
	for x in 4:
		inital_vecs.append(Vector2(rng.randf_range(-1, 1), rng.randf_range(-1, 1)))
	#se agregan todos lo demás vectores
	var counter = 0
	for i in height:
		var row = []
		for j in width:
			var a = i == 0
			var b = j == 0
			var c = i == width - 1
			var d = j == height - 1
			#las esquinas se agregan puesto que se han generado anteriormente
			if((a and b) or (a and d) or (b and c) or (c and d)):
				row.append(inital_vecs[counter])
				counter += 1
			else:
				var cur_x = 0
				var cur_y = 0
				#los demás vectores se generan a partir de los 4 extremos y se agrega un valor ponderado de sus componentes dependiendo de la distancia
				for delta in extremes.size():
					var temp_x = extremes[delta].x
					var temp_y = extremes[delta].y
					var cur_dist = sqr_dst(temp_x, temp_y, j, i)
					cur_x += (inital_vecs[delta].x * (1 -(cur_dist / max_square_dist))) / 3.0
					cur_y += (inital_vecs[delta].y * (1 -(cur_dist / max_square_dist))) / 3.0
				row.append(Vector2(cur_x, cur_y))
		field.append(row)
	return field
#funciones que apoyan a los agentes
#pinta el punto en el mapa de bioma como río
static func paint_river(x: float, y: float, image: Image):
	image.lock()
	var color: Color = image.get_pixel(x, y)
	image.unlock()
	#el alfa representará si está debajo del nivel del mar o si es una playa
	color.a = 0.6
	image.lock()
	image.set_pixel(x, y, color)
	image.unlock()
	#print("painted: ", Vector2(x, y))

static func is_river(x: float, y: float, image: Image):
	image.lock()
	var color: Color = image.get_pixel(x, y)
	image.unlock()
	#el alfa representará si está debajo del nivel del mar o si es una playa
	if color.a < 1.0 and color.a > 0.5:
		return true
	else:
		return false

#ajusta lista dinámica de puntos encima del nivel del mar
static func fix_dynamic_list(point: Vector2, dynamic_list: Array, height: float, sea: float):
	var index = get_element_index(point, dynamic_list)
	if index >= 0:
		if height <= sea:
			dynamic_list.remove(index)
	else:
		if height > sea:
			dynamic_list.append(point)

#aplana el area al rededor de un punto que se usa en un árbol de ríos
static func flatten_basic(point: Vector2, heightImage: Image):
	if point.x < 0 || point.y < 0:
		print("fatal error at point:", point)
	heightImage.lock()
	var height = heightImage.get_pixel(point.x, point.y).r
	heightImage.unlock()
	var amount = 3 * height
	var counter = 3.0
	var visited_neighbours: Array = []
			
	for j in fullNeighbourhood.size():
		var next_x = point.x + fullNeighbourhood[j].x
		var next_y = point.y + fullNeighbourhood[j].y
		#El vecindario debe quedar dentro de los constraints del mapa de alturas
		if next_x >= 0 and next_x < heightImage.get_width() and next_y >= 0 and next_y < heightImage.get_height():
			heightImage.lock()
			var height_i = heightImage.get_pixel(next_x, next_y).r
			heightImage.unlock()
			amount += height_i
			counter += 1.0
			visited_neighbours.append(Vector2(next_x, next_y))
	height = amount / counter
	if height > 1:
		height = 1
	heightImage.lock()
	heightImage.set_pixel(point.x, point.y, Color(height, height, height, 1))
	heightImage.unlock()
	#retorna los puntos visitados para obtener un nuevo punto que visitar al asar
	return visited_neighbours

#funcíon que aplana el vecindario de dado puntp
static func flatten_around_basic(point: Vector2, heightImage: Image):
	var x = point.x
	var y = point.y
	for i in fullNeighbourhood.size():
		var next_x = x + fullNeighbourhood[i].x
		var next_y = y + fullNeighbourhood[i].y
		#El vecindario debe quedar dentro de los constraints del mapa de alturas
		if next_x >= 0 and next_x < heightImage.get_width() and next_y >= 0 and next_y < heightImage.get_height():
			flatten_basic(Vector2(next_x, next_y), heightImage)

#aplana el area al rededor de un punto
static func flatten(point: Vector2, sea: float, heightImage: Image, dynamic_list: Array):
	var visited_neighbours: Array = flatten_basic(point, heightImage)
	heightImage.lock()
	var height = heightImage.get_pixel(point.x, point.y).r
	heightImage.unlock()
	#para mantener el programa óptimo, si la nueva altura es menor al nivel del mar, se elimina de la lista, si era menor y se vuelve mayor, se añade
	fix_dynamic_list(point, dynamic_list, height, sea)
	#retorna los puntos visitados para obtener un nuevo punto que visitar al asar
	return visited_neighbours

#funcíon que aplana el vecindario de dado puntp
static func flatten_around(point: Vector2, list: Array, sea_level: float, heightImage: Image):
	var x = point.x
	var y = point.y
	for i in fullNeighbourhood.size():
		var next_x = x + fullNeighbourhood[i].x
		var next_y = y + fullNeighbourhood[i].y
		#El vecindario debe quedar dentro de los constraints del mapa de alturas
		if next_x >= 0 and next_x < heightImage.get_width() and next_y >= 0 and next_y < heightImage.get_height():
			flatten(Vector2(next_x, next_y), sea_level, heightImage, list)

static func create_floating_matrix(width: int, height: int, value: float = 0):
	var matrix=[]
	#crea una matriz float de las dimensiones dadas con todos los campos en value
	for y in height:
		matrix.append([])
		for x in width:
			matrix[y].append(value)
	return matrix

static func create_boolean_matrix(width: int, height: int, value: bool = true):
	var matrix=[]
	#crea una matriz booleana de las dimensiones dadas con todos los campos en falso
	for y in height:
		matrix.append([])
		for x in width:
			matrix[y].append(value)
	return matrix

#retorna el resultado de la operación lógica AND entre 2 matrices booleanas
static func matrix_and(mat_a: Array, mat_b: Array):
	if mat_a.size() == 0 or mat_b.size() == 0:
		return [[]]
	elif mat_a.size() == mat_b.size() and mat_a[0].size() == mat_b[0].size():
		var result = create_boolean_matrix(mat_a.size(), mat_a[0].size())
		for y in result.size():
			for x in result[0].size():
				result[y][x] = mat_a[y][x] and mat_b[y][x]
		return result
#retorna el mapa de elevaciones a partir de un mapa de alturas
static func get_slope_map(heightImage: Image):
	var mat = create_floating_matrix(heightImage.get_width(), heightImage.get_height())
	for y in heightImage.get_height():
		for x in heightImage.get_width():
			heightImage.lock()
			var height = heightImage.get_pixel(x, y).r
			heightImage.unlock()
			var slope_total = 0
			var neighbours_visited = 0
			for i in fullNeighbourhood.size():
					var next_x = x + fullNeighbourhood[i].x
					var next_y = y + fullNeighbourhood[i].y
					#El vecindario debe quedar dentro de los constraints del mapa de alturas
					if next_x >= 0 and next_x < heightImage.get_width() and next_y >= 0 and next_y < heightImage.get_height():
						heightImage.lock()
						var height_i = heightImage.get_pixel(next_x, next_y).r
						heightImage.unlock()
						var slope_i = abs(height - height_i)
						slope_total += slope_i
						neighbours_visited += 1
			#green  representa el mapa de inclinaciones
			mat[y][x] = slope_total / neighbours_visited
	return mat
