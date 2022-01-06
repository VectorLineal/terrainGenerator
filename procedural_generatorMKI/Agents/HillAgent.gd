extends SoftwareAgent

class_name HillAgent

var direction: Vector2
var height_max: float
var height_min: float
var slope_degradation: float
var width: int
var variance: float

func _init(tokens: int, max_h: float, min_h: float, slope_d: float, width: int, variance: float, list: Array, sea_level: float, heightImage: Image, random_gen: RandomNumberGenerator).(tokens):
	self.seed_point = getRandomLandPointDynamic(list, sea_level, heightImage, random_gen)
	self.direction = MathUtils.generate_random_normal(random_gen)
	self.height_max = max_h
	self.height_min = min_h
	self.slope_degradation = slope_d
	self.width = width
	self.variance = variance

func _to_string():
	return "base point: " + str(self.seed_point) + ", direction: " + str(self.direction.angle() * 180 / PI) + ", max height: " + str(self.height_max) + ", width: " + str(self.width) + ", refresh rate: " + str(self.restart_rate)

func act(perception):
	if self.tokens <= 0:
		die()
	else:
		for i in self.tokens:
			var heightImage = perception["map"]
			var sea = perception["sea"]
			var rng = perception["rng"]
			var dynamic_list: Array = perception["list"]
			
			var next_direction = MathUtils.angle_to_grid(self.direction)
			var perpendicular_directions = MathUtils.get_perpendicular_grids(next_direction)
			var elevation: float #guarda el cambio de elvación inical
			#si el punto se sale del mapa, el agente se detiene
			if !(self.seed_point.x >= 0 and self.seed_point.x < heightImage.get_width() and self.seed_point.y >= 0 and self.seed_point.y < heightImage.get_height()):
				print("I flushed in token ", i, " with coords: ", self.seed_point, " and direction: ", next_direction)
				return
				
			var mean_height = 0
			var counter = 0
			for k in MathUtils.fullNeighbourhood.size():
				var next_x = seed_point.x + MathUtils.fullNeighbourhood[k].x
				var next_y = seed_point.y + MathUtils.fullNeighbourhood[k].y
				#El vecindario debe quedar dentro de los constraints del mapa de alturas
				if next_x >= 0 and next_x < heightImage.get_width() and next_y >= 0 and next_y < heightImage.get_height():
						heightImage.lock()
						mean_height += heightImage.get_pixel(next_x, next_y).r
						heightImage.unlock()
						counter += 1.0
			#la altura esperada dependerá del promedio de alturas del vecindario
			var height = mean_height / counter
			var next_height: float = height * 1.2
			#if self.height_max > height:
				#next_height = rng.randf_range(height, self.height_max)
			#No debe exceder los límites de altura
			if next_height > self.height_max:
				#print("too high ", next_height)
				continue
			
			elevation = next_height - height
			var elevation_left: float = elevation
			var elevation_right: float = elevation
			var degradation_left: float = rng.randf_range(0, self.slope_degradation)
			var degradation_right: float = rng.randf_range(0, self.slope_degradation)
			heightImage.lock()
			heightImage.set_pixel(self.seed_point.x, self.seed_point.y, Color(next_height, next_height, next_height, 1))
			heightImage.unlock()
			fix_dynamic_list(self.seed_point, dynamic_list, next_height, sea)
			
			#se eleva perpendicularmente al punto
			for j in self.width:
				elevation_left -= degradation_left
				elevation_right -= degradation_right
				var left_x = self.seed_point.x + perpendicular_directions[0][0] * (1 + j)
				var left_y = self.seed_point.y + perpendicular_directions[0][1] * (1 + j)
				
				var right_x = self.seed_point.x + perpendicular_directions[1][0] * (1 + j)
				var right_y = self.seed_point.y + perpendicular_directions[1][1] * (1 + j)
				#se asegura que las nuevas coordenadas estén dentro del mapa además debe haber elevación o el proceso no tendría sentido
				if left_x >= 0 and left_x < heightImage.get_width() and left_y >= 0 and left_y < heightImage.get_height() && elevation_left > 0:
					heightImage.lock()
					var height_left = heightImage.get_pixel(left_x, left_y).r
					heightImage.unlock()
					next_height = height_left + elevation_left
					#se agrega o resta la varianza aleatoriamente para simular ruido
					next_height += rng.randf_range(-self.variance, self.variance)
					if next_height <= 1:
						#se pone la nueva altura
						heightImage.lock()
						heightImage.set_pixel(left_x, left_y, Color(next_height, next_height, next_height, 1))
						heightImage.unlock()
						fix_dynamic_list(Vector2(left_x, left_y), dynamic_list, next_height, sea)
				if right_x >= 0 and right_x < heightImage.get_width() and right_y >= 0 and right_y < heightImage.get_height() && elevation_right > 0:
					heightImage.lock()
					var height_right = heightImage.get_pixel(right_x, right_y).r
					heightImage.unlock()
					next_height = height_right + elevation_right
					#se agrega o resta la varianza aleatoriamente para simular ruido
					next_height += rng.randf_range(-self.variance, self.variance)
					if next_height <= 1:
						#se pone la nueva altura
						heightImage.lock()
						heightImage.set_pixel(right_x, right_y, Color(next_height, next_height, next_height, 1))
						heightImage.unlock()
						fix_dynamic_list(Vector2(right_x, right_y), dynamic_list, next_height, sea)
		
			#se mueve el siguiente punto a la dirección de la montaña
			var next_point = Vector2(self.seed_point.x + next_direction[0], self.seed_point.y + next_direction[1])
			var index = MathUtils.get_element_index(next_point, dynamic_list)
			#en caso que el siguiente punto vaya a una casilla bajo el nivel del mar, se cambia la dirección
			if index < 0 || !(next_point.x >= 0 and next_point.x < heightImage.get_width() and next_point.y >= 0 and next_point.y < heightImage.get_height()):
				for k in MathUtils.fullNeighbourhood.size():
					var next_x = seed_point.x + MathUtils.fullNeighbourhood[k].x
					var next_y = seed_point.y + MathUtils.fullNeighbourhood[k].y
					next_point = Vector2(next_x, next_y)
					#El vecindario debe quedar dentro de los constraints del mapa de alturas
					if next_x >= 0 and next_x < heightImage.get_width() and next_y >= 0 and next_y < heightImage.get_height():
						index = MathUtils.get_element_index(next_point, dynamic_list)
						#si se encuentra un punto dentro de la masa continental, se elige como nueva dirección
						if index >= 0:
							self.direction = MathUtils.fullNeighbourhood[k].normalized()
							k = 8
			#ahora el punto correspondiente en la dirección del agente
			self.seed_point = next_point

#para mantener el programa óptimo, si la nueva altura es menor al nivel del mar, se elimina de la lista, si era menor y se vuelve mayor, se añade
func fix_dynamic_list(point: Vector2, dynamic_list: Array, height: float, sea: float):
	var index = MathUtils.get_element_index(point, dynamic_list)
	if index >= 0:
		if height <= sea:
			dynamic_list.remove(index)
	else:
		if height > sea:
			dynamic_list.append(point)

#función que calcula un punto aleatorio que esté encima de un nivel del mar usando programación dinámica
func getRandomLandPointDynamic(list: Array, sea_level: float, heightImage: Image, random_gen: RandomNumberGenerator):
	var p: Vector2 = Vector2(0, 0)
	#obtenemos un punto aleatorio; en tal caso de que aún no haya ninguno, simplemente se toma un punto arbitrario
	if list.size() > 0:
		p = list[random_gen.randi_range(0, list.size() - 1)]
	else:
		p = Vector2(random_gen.randi_range(0, heightImage.get_width() - 1), random_gen.randi_range(0, heightImage.get_height() - 1))
		#print("el mapa está sin tocar")
	return p
