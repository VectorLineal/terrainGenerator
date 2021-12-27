extends Agent

class_name CoastAgent

var seed_point: Vector2
var direction: Vector2
var attractor: Vector2
var repulsor: Vector2

func _init(tokens: int, limit: int, sea_level: float, heightImage: Image, random_gen: RandomNumberGenerator):
	._init(tokens, limit)
	self.seed_point = getRandomCoastPoint(sea_level, heightImage, random_gen)
	self.direction = MathUtils.generate_random_normal(random_gen)
	self.attractor = Vector2(random_gen.randi_range(0, heightImage.get_width() - 1), random_gen.randi_range(0, heightImage.get_height() - 1))
	self.repulsor = Vector2(random_gen.randi_range(0, heightImage.get_width() - 1), random_gen.randi_range(0, heightImage.get_height() - 1))
	#repulsor y atractor deben quedar en direcciones diferentes
	while self.attractor.angle() == self.repulsor.angle():
		self.repulsor = Vector2(random_gen.randi_range(0, heightImage.get_width() - 1), random_gen.randi_range(0, heightImage.get_height() - 1))

func act(perception):
	if self.tokens >= self.limit:
		var child1 = CoastAgent.new(self.tokens / 2, self.limit, perception["sea"], perception["map"], perception["rng"])
		var child2 = CoastAgent.new(self.tokens / 2, self.limit, perception["sea"], perception["map"], perception["rng"])
		child1.act(perception)
		child2.act(perception)
	else:
		for i in self.tokens:
			var heightImage = perception["map"]
			var sea = perception["sea"]
			#se asegura que el punto base no esté totalmente rodeado por el area ya elevada
			while is_point_surrounded(self.seed_point, sea, heightImage):
				var next_direction = MathUtils.angle_to_grid(self.direction)
				self.seed_point = Vector2(self.seed_point.x + next_direction[0], self.seed_point.y+ next_direction[1])
			#se obtiene el próximo punto para elevar
			var next_point = get_next_coast(self.seed_point, sea, heightImage)
			heightImage.lock()
			heightImage.set_pixel(next_point.x, next_point.y, Color(sea * 1.5, sea * 1.5, sea * 1.5, 1))
			heightImage.unlock()
			#ahora el punto base es el punto ya elevado
			self.seed_point = next_point

#función que calcula un punto aleatorio que esté encima de un nivel del mar dado
func getRandomCoastPoint(sea_level: float, heightImage: Image, random_gen: RandomNumberGenerator):
	var p: Vector2 = Vector2(0, 0)
	var available: Array = []
	#se obtienen todos los puntos elevados por encima del nivel del mar
	heightImage.lock()
	for y in heightImage.get_height():
		for x in heightImage.get_width():
			var height = heightImage.get_pixel(x, y).r
			if height > sea_level:
				available.append(Vector2(x, y))
	heightImage.unlock()
	#obtenemos un punto aleatorio; en tal caso de que aún no haya ninguno, simplemente se toma un punto arbitrario
	if available.size() > 0:
		p = available[random_gen.randi_range(0, available.size() - 1)]
	else:
		p = Vector2(random_gen.randi_range(0, heightImage.get_width() - 1), random_gen.randi_range(0, heightImage.get_height() - 1))
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
		heightImage.lock()
		if next_x >= 0 and next_x < heightImage.get_width() and next_y >= 0 and next_y < heightImage.get_height():
			var height_i = heightImage.get_pixel(next_x, next_y).r
			#solo se tendrán en cuenta casillas sin elevar
			if height_i <= sea_level:
				var dr = MathUtils.sqr_dst(next_x, next_y, self.repulsor.x, self.repulsor.y)
				#se debe obtener la mínima distancia a los bordes del mapa por lo que se recorren las 4 esquinas
				var de = MathUtils.sqr_dst(next_x, next_y, 0, 0)
				de = min(de, MathUtils.sqr_dst(next_x, next_y, heightImage.get_width() - 1, 0))
				de = min(de, MathUtils.sqr_dst(next_x, next_y, 0, heightImage.get_height() - 1))
				de = min(de, MathUtils.sqr_dst(next_x, next_y, heightImage.get_width() - 1, heightImage.get_height() - 1))
				var da = MathUtils.sqr_dst(next_x, next_y, self.attractor.x, self.attractor.y)
				var next_score = dr - da + 3 * de
				#se debe tener el mejor puntaje y el punto que apunta
				if score < next_score:
					score = next_score
					next_point = Vector2(next_x, next_y)
		heightImage.unlock()
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
