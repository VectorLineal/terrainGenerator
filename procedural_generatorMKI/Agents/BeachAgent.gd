extends SoftwareAgent

class_name BeachAgent

var height_max: float
var height_min: float
var height_limit: float
var width: int

func _init(tokens: int, limit: float, max_h: float, min_h: float, width: int, list: Array, sea_level: float, heightImage: Image, random_gen: RandomNumberGenerator).(tokens):
	self.height_limit = limit
	self.height_max = max_h
	self.height_min = min_h
	self.width = width
	self.seed_point = getRandomCoastPointDynamic(true, list, sea_level, heightImage, random_gen)
	
func _to_string():
	return "base point: " + str(self.seed_point) + ", height limit: " + str(self.height_limit) + ", width: " + str(self.width)

func act(perception):
	if self.tokens <= 0:
		die()
	else:
		for i in self.tokens:
			#print("running token ", i)
			var heightImage = perception["map"]
			var image = perception["biome"]
			var sea = perception["sea"]
			var rng = perception["rng"]
			var dynamic_list: Array = perception["list"]
			#se asegura que el punto base no esté más alto que el límite
			heightImage.lock()
			var height = heightImage.get_pixel(self.seed_point.x, self.seed_point.y).r
			heightImage.unlock()
			#se pinta el mapa de bioma como arena
			paint_sand(self.seed_point.x, self.seed_point.y, image)
			#se aplana al rededor del punto
			var next_height = rng.randf_range(self.height_min, self.height_max)
			flatten_smooth_around(self.seed_point, next_height, dynamic_list, sea, heightImage, image)
			#se elige el próximo punto vecino del punto base, no debe estar necesariamente en la costa
			var next_point = get_next_beach(self.seed_point, false, dynamic_list, sea, heightImage, rng)
			
			#se camina aplanando puntos desde la dirección base hasta que se haya recorrido tanto como sea necesario
			for j in self.width:
				next_height = rng.randf_range(self.height_min, self.height_max)
				flatten_smooth_around(next_point, next_height, dynamic_list, sea, heightImage, image)
				next_point = get_next_beach(next_point, false, dynamic_list, sea, heightImage, rng)
			#ahora el punto base se pasa a un punto adyacente al punto base anterior, debe ser costero
			self.seed_point = get_next_beach(self.seed_point, true, dynamic_list, sea, heightImage, rng)

func flatten_smooth_around(point: Vector2, flatten_height: float, list: Array, sea_level: float, heightImage: Image, image: Image):
	var x = point.x
	var y = point.y
	for i in MathUtils.fullNeighbourhood.size():
		var next_x = x + MathUtils.fullNeighbourhood[i].x
		var next_y = y + MathUtils.fullNeighbourhood[i].y
		#El vecindario debe quedar dentro de los constraints del mapa de alturas
		if next_x >= 0 and next_x < heightImage.get_width() and next_y >= 0 and next_y < heightImage.get_height():
			#si el punto ya está marcado como playa o mar, es innecesario aplicar el proceso
			image.lock()
			var color: Color = image.get_pixel(next_x, next_y)
			image.unlock()
			if color.a > 0.5:
				var height_i = flatten_height
				var next_point = Vector2(next_x, next_y)
				heightImage.lock()
				heightImage.set_pixel(next_x, next_y, Color(height_i, height_i, height_i, 1))
				heightImage.unlock()
				smooth(next_point, sea_level, heightImage, list)
				paint_sand(next_x, next_y, image)
			
#pinta el punto en el mapa de bioma como arena
func paint_sand(x: float, y: float, image: Image):
	image.lock()
	var color: Color = image.get_pixel(x, y)
	image.unlock()
	#el alfa representará si está debajo del nivel del mar o si es una playa
	color.a = 0.25
	image.lock()
	image.set_pixel(x, y, color)
	image.unlock()
	
#función que calcula un punto aleatorio que esté encima de un nivel del mar usando programación dinámica
func getRandomCoastPointDynamic(is_shore: bool, list: Array, sea_level: float, heightImage: Image, random_gen: RandomNumberGenerator):
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
			if !is_point_surrounded(list[j], sea_level, heightImage) and height <= self.height_limit:
				available.append(list[j])
		else:
			if height <= self.height_limit:
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

#esta función elige el próximo punto para aplanar
func get_next_beach(point: Vector2, is_shore: bool, list: Array, sea_level: float, heightImage: Image, random_gen: RandomNumberGenerator):
	var x = point.x
	var y = point.y
	var available: Array
	for i in MathUtils.fullNeighbourhood.size():
		var next_x = x + MathUtils.fullNeighbourhood[i].x
		var next_y = y + MathUtils.fullNeighbourhood[i].y
		#El vecindario debe quedar dentro de los constraints del mapa de alturas
		if next_x >= 0 and next_x < heightImage.get_width() and next_y >= 0 and next_y < heightImage.get_height():
			heightImage.lock()
			var height_i = heightImage.get_pixel(next_x, next_y).r
			heightImage.unlock()
			var next_point: Vector2 = Vector2(next_x, next_y)
			if is_shore:
				#el punto debe estar por encima del nivel del mar y no debe estar totalmente rodeado
				if !is_point_surrounded(next_point, sea_level, heightImage) and height_i > sea_level and height_i <= self.height_limit:
					available.append(next_point)
			else:
				#solo se tendrá en cuenta la altitud, no importa si el punto da al mar
				if height_i > sea_level and height_i <= self.height_limit:
					available.append(next_point)
			
	#si hay solo un elemento posible, se retorna ese, si hay más se retorna uno de esos aleatoriamente, si no, se escoge un nuevo punto en la costa
	if available.size() == 1:
		return available[0]
	if available.size() > 1:
		return available[random_gen.randi_range(0, available.size() - 1)]
	else:
		return getRandomCoastPointDynamic(true, list, sea_level, heightImage, random_gen)

#aplana el terreno en un punto dado
func smooth(point: Vector2, sea: float, heightImage: Image, dynamic_list: Array):
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

#para mantener el programa óptimo, si la nueva altura es menor al nivel del mar, se elimina de la lista, si era menor y se vuelve mayor, se añade
func fix_dynamic_list(point: Vector2, dynamic_list: Array, height: float, sea: float):
	var index = MathUtils.get_element_index(point, dynamic_list)
	if index >= 0:
		if height <= sea:
			dynamic_list.remove(index)
	else:
		if height > sea:
			dynamic_list.append(point)
