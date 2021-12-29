class_name MathUtils

#modified Von Neumann neighbourhood
const neighbourhood = [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]
const fullNeighbourhood = [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1), Vector2(0, -1), Vector2(1, 0), Vector2(0, 1), Vector2(-1, 0)]

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
