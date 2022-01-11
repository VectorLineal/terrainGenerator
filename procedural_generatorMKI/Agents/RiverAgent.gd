extends SoftwareAgent

class_name RiverAgent

var max_length: int #máximo largo del río
var min_length: int #mínimo largo del río
var grow_rate: float #que tanto se ancha el río
var expected_mountain: float #que altura de montaña se espera
var slope_degradation: float
var starting_slope: float

func _init(tokens: int, max_l: float, min_l: float, growth: float, expected_m: float, slope_d: float, starting_s: float, list: Array, sea_level: float, heightImage: Image, random_gen: RandomNumberGenerator).(tokens):
	#el número de tokens servirá como número máximo de intentos, si el río no se puede formar en esos intentos, el agente no hará nada
	#seed_point servirá como punto costero
	self.seed_point = getRandomLandPointDynamic(true, list, sea_level, heightImage, random_gen)
	self.max_length = max_l
	self.min_length = min_l
	self.grow_rate = growth
	self.expected_mountain = expected_m
	self.slope_degradation = slope_d
	self.starting_slope = starting_s

func act(perception):
	if self.tokens <= 0:
		die()
	else:
		var heightImage = perception["map"]
		var image = perception["biome"]
		var sea = perception["sea"]
		var rng = perception["rng"]
		var dynamic_list: Array = perception["list"]
		
		for i in self.tokens:
			#print("running token ", i)
			#se guardan un punto de montaña y un posible camino entre estos
			var mountain: Vector2 = getRandomLandPointDynamic(false, dynamic_list, sea, heightImage, rng)
			#la distancia entre montaña y costa inicial debería ser al menos la del río
			#while MathUtils.sqr_dst(mountain.x, mountain.y, seed_point.x, seed_point.y) >= self.min_length * self.min_length:
			#	mountain = getRandomLandPointDynamic(true, dynamic_list, sea, heightImage, rng)
			var path: Array
			#se guarda una variable que indica si es imposible hacer río
			var is_posible: bool = true
			#se guarda el punto actual, inicializa en el punto costero
			var next_x: float = self.seed_point.x
			var next_y: float = self.seed_point.y
			path.append(Vector2(next_x, next_y))
			#se obtiene la altura para saber si el punto está en la montaña o no
			heightImage.lock()
			var height = heightImage.get_pixel(next_x, next_y).r
			heightImage.unlock()
			#mientras el punto no esté en montaña, se creará camino del río
			while height <= self.expected_mountain and is_posible:
				var posible_path = get_next_path(Vector2(next_x, next_y), mountain, sea, heightImage)
				if (posible_path.x == next_x and posible_path.y == next_y) or path.has(posible_path):
					is_posible = false
				else:
					next_x = posible_path.x
					next_y = posible_path.y
					path.append(Vector2(next_x, next_y))
					heightImage.lock()
					height = heightImage.get_pixel(next_x, next_y).r
					heightImage.unlock()
			#si el camino escogido es muy corto o muy largo o nunca se llegó a la montaña, se debería intentar de nuevo hacer río en otra iteración
			if !is_posible or path.size() < self.min_length or path.size() > self.max_length:
				#print("i failed with ", path.size(), " of path")
				self.seed_point = getRandomLandPointDynamic(true, dynamic_list, sea, heightImage, rng)
			else:
				print("i succeded with ", path.size(), " of path")
				#esta variable crece a medida que el río deciende de la montaña
				var width: float = 1.0
				var next_slope: float = self.starting_slope
				for j in range(path.size() - 1, -1, -1):
					#si se llega a un punto que ya es un río se detiene el agente, así quedan ríos afluentes
					if is_river(path[j].x, path[j].y, image):
						print("I arrived to another river")
						print("I created a river in try ", i)
						return
					else:
						var next_direction: Array = [0, 0]
						if j < path.size() - 1:
							next_direction[0] = int(path[j].x - path[j + 1].x)
							next_direction[1] = int(path[j].y - path[j + 1].y)
						else:
							next_direction[0] = int(path[j].x - path[j - 1].x)
							next_direction[1] = int(path[j].y - path[j - 1].y)
						#se crea el area de río luego se aumenta su ancho a medida que baja de la montaña
						make_river(path[j], next_direction, int(width), next_slope, dynamic_list, sea, heightImage, image)
						next_slope += rng.randf_range(self.slope_degradation / 4.0, self.slope_degradation)
						width += self.grow_rate
				print("I created a river in try ", i)
				return

#esta función aplana los puntos perpendiculares al punto creando un area hundida
func make_river(cur_point: Vector2, next_direction: Array, width: int, next_slope: float, dynamic_list: Array, sea: float, heightImage: Image, image: Image):
	var perpendicular_directions = MathUtils.get_perpendicular_grids(next_direction)
	var elevation: float = next_slope
	#se obtiene la altura actual y se asegura que no rebase 1
	heightImage.lock()
	var height = heightImage.get_pixel(self.seed_point.x, self.seed_point.y).r
	heightImage.unlock()
	var next_height: float = height - next_slope
	#no se peden tener alturas negativas
	if next_height < 0.0:
		print("too low")
		return
	heightImage.lock()
	heightImage.set_pixel(cur_point.x, cur_point.y, Color(next_height, next_height, next_height, 1))
	heightImage.unlock()
	#se marca como río en mapa de biomas
	paint_river(cur_point.x, cur_point.y, image)
	for j in width:
		var left_x = self.seed_point.x + perpendicular_directions[0][0] * (1 + j)
		var left_y = self.seed_point.y + perpendicular_directions[0][1] * (1 + j)
				
		var right_x = self.seed_point.x + perpendicular_directions[1][0] * (1 + j)
		var right_y = self.seed_point.y + perpendicular_directions[1][1] * (1 + j)
		#se asegura que las nuevas coordenadas estén dentro del mapa además debe haber elevación o el proceso no tendría sentido
		if left_x >= 0 and left_x < heightImage.get_width() and left_y >= 0 and left_y < heightImage.get_height():
			if next_height >= 0:
				#se pone la nueva altura
				heightImage.lock()
				heightImage.set_pixel(left_x, left_y, Color(next_height, next_height, next_height, 1))
				heightImage.unlock()
				paint_river(left_x, left_y, image)
				#se aplana
				#flatten(Vector2(left_x, left_y), sea, heightImage, dynamic_list)
		if right_x >= 0 and right_x < heightImage.get_width() and right_y >= 0 and right_y < heightImage.get_height():
			if next_height <= 1:
				#se pone la nueva altura
				heightImage.lock()
				heightImage.set_pixel(right_x, right_y, Color(next_height, next_height, next_height, 1))
				heightImage.unlock()
				paint_river(right_x, right_y, image)
				#se aplana
				#flatten(Vector2(right_x, right_y), sea, heightImage, dynamic_list)
	#se aplana la nueva altura
	flatten(cur_point, sea, heightImage, dynamic_list)
	flatten_around(cur_point, dynamic_list, sea, heightImage)

#funcíon que aplana el vecindario de dado puntp
func flatten_around(point: Vector2, list: Array, sea_level: float, heightImage: Image):
	var x = point.x
	var y = point.y
	for i in MathUtils.fullNeighbourhood.size():
		var next_x = x + MathUtils.fullNeighbourhood[i].x
		var next_y = y + MathUtils.fullNeighbourhood[i].y
		#El vecindario debe quedar dentro de los constraints del mapa de alturas
		if next_x >= 0 and next_x < heightImage.get_width() and next_y >= 0 and next_y < heightImage.get_height():
			flatten(Vector2(next_x, next_y), sea_level, heightImage, list)
	
#función que calcula un punto aleatorio que esté encima de un nivel del mar usando programación dinámica
func getRandomLandPointDynamic(is_shore: bool, list: Array, sea_level: float, heightImage: Image, random_gen: RandomNumberGenerator):
	var p: Vector2 = Vector2(0, 0)
	var available: Array = []
	#se obtienen todos los puntos elevados por encima del nivel del mar
	for j in list.size():
		#se obtiene la altura en el punto y se debe asegurar que no sobrepase la altura límite
		heightImage.lock()
		var height = heightImage.get_pixel(list[j].x, list[j].y).r
		heightImage.unlock()
		if is_shore:
			#el punto debe estar por encima del nivel del mar y no debe estar totalmente rodeado
			if !is_point_surrounded(list[j], sea_level, heightImage):
				available.append(list[j])
		else:
			if height >= self.expected_mountain:
				available.append(list[j])
	
	#obtenemos un punto aleatorio; en tal caso de que aún no haya ninguno, simplemente se toma un punto arbitrario
	if available.size() > 0:
		p = available[random_gen.randi_range(0, available.size() - 1)]
	else:
		p = Vector2(random_gen.randi_range(0, heightImage.get_width() - 1), random_gen.randi_range(0, heightImage.get_height() - 1))
		#print("el mapa está sin tocar")
	return p
	
#comprueba si el punto actual ya tiene a todos sus vecinos elevados
func is_point_surrounded(point: Vector2, sea_level: float, heightImage: Image):
	var x = point.x
	var y = point.y
	for i in MathUtils.fullNeighbourhood.size():
		var next_x = x + MathUtils.fullNeighbourhood[i].x
		var next_y = y + MathUtils.fullNeighbourhood[i].y
		#El vecindario debe quedar dentro de los constraints del mapa de alturas
		if next_x >= 0 and next_x < heightImage.get_width() and next_y >= 0 and next_y < heightImage.get_height():
			heightImage.lock()
			var height_i = heightImage.get_pixel(next_x, next_y).r
			heightImage.unlock()
			#si alguna casilla sigue sin elvar, este punto es operable
			if height_i <= sea_level:
				return false
	return true

func get_next_path(point: Vector2, mountain: Vector2, sea_level: float, heightImage: Image):
	var x = point.x
	var y = point.y
	var m_x = mountain.x
	var m_y = mountain.y
	var next_point: Vector2 = Vector2(x, y)
	var cur_score = -10000000000
	for i in MathUtils.fullNeighbourhood.size():
		var next_x = x + MathUtils.fullNeighbourhood[i].x
		var next_y = y + MathUtils.fullNeighbourhood[i].y
		#El vecindario debe quedar dentro de los constraints del mapa de alturas
		if next_x >= 0 and next_x < heightImage.get_width() and next_y >= 0 and next_y < heightImage.get_height():
			heightImage.lock()
			var height_i = heightImage.get_pixel(next_x, next_y).r
			heightImage.unlock()
			var score = height_i - MathUtils.sqr_dst(next_x, next_y, m_x, m_y)
			if height_i > sea_level and score > cur_score:
				cur_score = score
				next_point = Vector2(next_x, next_y)
			
	return next_point

func fix_dynamic_list(point: Vector2, dynamic_list: Array, height: float, sea: float):
	var index = MathUtils.get_element_index(point, dynamic_list)
	if index >= 0:
		if height <= sea:
			dynamic_list.remove(index)
	else:
		if height > sea:
			dynamic_list.append(point)

#aplana el terreno en un punto dado
func flatten(point: Vector2, sea: float, heightImage: Image, dynamic_list: Array):
	if point.x < 0 || point.y < 0:
		print("fatal error at point:", point)
	heightImage.lock()
	var height = heightImage.get_pixel(point.x, point.y).r
	heightImage.unlock()
	var amount = 3 * height
	var counter = 3.0
			
	for j in MathUtils.fullNeighbourhood.size():
		var next_x = point.x + MathUtils.fullNeighbourhood[j].x
		var next_y = point.y + MathUtils.fullNeighbourhood[j].y
		#El vecindario debe quedar dentro de los constraints del mapa de alturas
		if next_x >= 0 and next_x < heightImage.get_width() and next_y >= 0 and next_y < heightImage.get_height():
			heightImage.lock()
			var height_i = heightImage.get_pixel(next_x, next_y).r
			heightImage.unlock()
			amount += height_i
			counter += 1.0
	height = amount / counter
	if height > 1:
		height = 1
	heightImage.lock()
	heightImage.set_pixel(point.x, point.y, Color(height, height, height, 1))
	heightImage.unlock()
			
	#para mantener el programa óptimo, si la nueva altura es menor al nivel del mar, se elimina de la lista, si era menor y se vuelve mayor, se añade
	fix_dynamic_list(point, dynamic_list, height, sea)

#pinta el punto en el mapa de bioma como río
func paint_river(x: float, y: float, image: Image):
	image.lock()
	var color: Color = image.get_pixel(x, y)
	image.unlock()
	#el alfa representará si está debajo del nivel del mar o si es una playa
	color.a = 0.6
	image.lock()
	image.set_pixel(x, y, color)
	image.unlock()

func is_river(x: float, y: float, image: Image):
	image.lock()
	var color: Color = image.get_pixel(x, y)
	image.unlock()
	#el alfa representará si está debajo del nivel del mar o si es una playa
	if color.a < 1.0 and color.a > 0.5:
		return true
	else:
		return false
