extends SoftwareAgent

class_name CoastAgent

var seed_point: Vector2
var direction: Vector2
var attractor: Vector2
var repulsor: Vector2

func _init(tokens: int, list: Array, sea_level: float, heightImage: Image, random_gen: RandomNumberGenerator).(tokens):
	self.seed_point = getRandomCoastPointDynamic(list, sea_level, heightImage, random_gen)
	self.direction = MathUtils.generate_random_normal(random_gen)
	self.attractor = Vector2(random_gen.randi_range(0, heightImage.get_width() - 1), random_gen.randi_range(0, heightImage.get_height() - 1))
	self.repulsor = Vector2(random_gen.randi_range(0, heightImage.get_width() - 1), random_gen.randi_range(0, heightImage.get_height() - 1))
	#repulsor y atractor deben quedar en direcciones diferentes
	self.repulsor.x = int(self.attractor.y / 2 + self.repulsor.x) % int(heightImage.get_width())
	self.repulsor.y = int(self.attractor.x / 2 + self.repulsor.y) % int(heightImage.get_height())

func _to_string():
	return "base point: " + str(self.seed_point) + ", direction: " + str(self.direction.angle() * 180 / PI) + ", attractor: " + str(self.attractor) + ", repulsor: " + str(self.repulsor)

func act(perception):
	if self.tokens <= 0:
		die()
	else:
		for i in self.tokens:
			var heightImage = perception["map"]
			var sea = perception["sea"]
			#se asegura que el punto base no esté totalmente rodeado por el area ya elevada
			while is_point_surrounded(self.seed_point, sea, heightImage):
				var next_direction = MathUtils.angle_to_grid(self.direction)
				var next_x = self.seed_point.x + next_direction[0]
				var next_y = self.seed_point.y + next_direction[1]
				#se debe asegurar que las coordenadas sigan dentro del mapa
				if next_x >= heightImage.get_width() || next_x < 0:
					next_x = self.seed_point.x
				if next_y >= heightImage.get_height() || next_y < 0:
					next_y = self.seed_point.y
				#en caso de que se haya llegado a un límite, elegir un punto aleatorio
				if next_x == self.seed_point.x && next_y == self.seed_point.y:
					#print("me atasqué")
					self.seed_point = getRandomCoastPointDynamic(perception["list"], sea, heightImage, perception["rng"])
				else:
					#print("no me atasqué o.x: ", seed_point.x, ", o.y: ", seed_point.y, ", n.x: ", next_x, ", n.y: ", next_y)
					self.seed_point = Vector2(next_x, next_y)
			#print("remaining tokens: ", self.tokens - i)
			#se obtiene el próximo punto para elevar
			#print("original: ", seed_point)
			var next_point = get_next_coast(self.seed_point, sea, heightImage)
			#print("next: ", next_point)
			heightImage.lock()
			heightImage.set_pixel(next_point.x, next_point.y, Color(sea * 1.5, sea * 1.5, sea * 1.5, 1))
			heightImage.unlock()
			perception["list"].append(next_point)
			#ahora el punto base es el punto ya elevado
			self.seed_point = next_point

#función que calcula un punto aleatorio que esté encima de un nivel del mar dado
func getRandomCoastPoint(sea_level: float, heightImage: Image, random_gen: RandomNumberGenerator):
	var p: Vector2 = Vector2(0, 0)
	var available: Array = []
	#se obtienen todos los puntos elevados por encima del nivel del mar
	for y in heightImage.get_height():
		for x in heightImage.get_width():
			heightImage.lock()
			var height = heightImage.get_pixel(x, y).r
			heightImage.unlock()
			var point = Vector2(x, y)
			#el punto debe estar por encima del nivel del mar y no debe estar totalmente rodeado
			if height > sea_level && !is_point_surrounded(point, sea_level, heightImage):
				available.append(point)
	
	#obtenemos un punto aleatorio; en tal caso de que aún no haya ninguno, simplemente se toma un punto arbitrario
	if available.size() > 0:
		p = available[random_gen.randi_range(0, available.size() - 1)]
	else:
		p = Vector2(random_gen.randi_range(0, heightImage.get_width() - 1), random_gen.randi_range(0, heightImage.get_height() - 1))
		#print("el mapa está sin tocar")
	return p

#función que calcula un punto aleatorio que esté encima de un nivel del mar usando programación dinámica
func getRandomCoastPointDynamic(list: Array, sea_level: float, heightImage: Image, random_gen: RandomNumberGenerator):
	var p: Vector2 = Vector2(0, 0)
	var available: Array = []
	#se obtienen todos los puntos elevados por encima del nivel del mar
	for j in list.size():
		#el punto debe estar por encima del nivel del mar y no debe estar totalmente rodeado
		if !is_point_surrounded(list[j], sea_level, heightImage):
			available.append(list[j])
	
	#obtenemos un punto aleatorio; en tal caso de que aún no haya ninguno, simplemente se toma un punto arbitrario
	if available.size() > 0:
		p = available[random_gen.randi_range(0, available.size() - 1)]
	else:
		p = Vector2(random_gen.randi_range(0, heightImage.get_width() - 1), random_gen.randi_range(0, heightImage.get_height() - 1))
		#print("el mapa está sin tocar")
	return p

#esta función elige el próximo punto para elevar
func get_next_coast(point: Vector2, sea_level: float, heightImage: Image):
	var x = point.x
	var y = point.y
	var score = -100000000
	var next_point: Vector2 = Vector2(0, 0)
	for i in MathUtils.fullNeighbourhood.size():
		var next_x = x + MathUtils.fullNeighbourhood[i].x
		var next_y = y + MathUtils.fullNeighbourhood[i].y
		#El vecindario debe quedar dentro de los constraints del mapa de alturas
		if next_x >= 0 and next_x < heightImage.get_width() and next_y >= 0 and next_y < heightImage.get_height():
			heightImage.lock()
			var height_i = heightImage.get_pixel(next_x, next_y).r
			heightImage.unlock()
			#solo se tendrán en cuenta casillas sin elevar
			if height_i <= sea_level:
				var dr = MathUtils.sqr_dst(next_x, next_y, self.repulsor.x, self.repulsor.y)
				#se debe obtener la mínima distancia a los bordes del mapa por lo que se calcula el borde del mapa más cercano primero
				#var corner = MathUtils.sqr_dst(next_x, next_y, 0, 0)
				#corner = min(corner, MathUtils.sqr_dst(next_x, next_y, heightImage.get_width() - 1, 0))
				#corner = min(corner, MathUtils.sqr_dst(next_x, next_y, 0, heightImage.get_height() - 1))
				#corner = min(corner, MathUtils.sqr_dst(next_x, next_y, heightImage.get_width() - 1, heightImage.get_height() - 1))
				var edge_map = MathUtils.get_closest_border(Vector2(next_x, next_y), Vector2(heightImage.get_width(), heightImage.get_height()))
				var edge = MathUtils.sqr_dst(next_x, next_y, edge_map.x, edge_map.y)
				var de = edge
				var da = MathUtils.sqr_dst(next_x, next_y, self.attractor.x, self.attractor.y)
				var next_score = dr + 3 * de - da
				#se debe tener el mejor puntaje y el punto que apunta
				if score < next_score:
					score = next_score
					next_point = Vector2(next_x, next_y)
	return next_point

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
