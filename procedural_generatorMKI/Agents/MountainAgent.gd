extends HillAgent

class_name MountainAgent

var restart_rate: int
var direction_status: int = 0

func _init(tokens: int, rate: int, max_h: float, min_h: float, slope_d: float, width: int, variance: float, list: Array, sea_level: float, heightImage: Image, random_gen: RandomNumberGenerator).(tokens, max_h, min_h, slope_d, width, variance, list, sea_level, heightImage, random_gen):
	self.restart_rate = rate

func _to_string():
	return "base point: " + str(self.seed_point) + ", direction: " + str(self.direction.angle() * 180 / PI) + ", max height: " + str(self.height_max) + ", width: " + str(self.width) + ", refresh rate: " + str(self.restart_rate)

func act(perception):
	if self.tokens <= 0:
		die()
	else:
		var heightImage = perception["map"]
		var sea = perception["sea"]
		var rng = perception["rng"]
		var dynamic_list: Array = perception["list"]
		for i in self.tokens:
			var next_direction = MathUtils.rotate_45_grid(MathUtils.angle_to_grid(self.direction), self.direction_status)
			var perpendicular_directions = MathUtils.get_perpendicular_grids(next_direction)
			var elevation: float #guarda el cambio de elvación inical
			#si el punto se sale del mapa, el agente se detiene
			if !(self.seed_point.x >= 0 and self.seed_point.x < heightImage.get_width() and self.seed_point.y >= 0 and self.seed_point.y < heightImage.get_height()):
				print("I flushed in token ", i, " with coords: ", self.seed_point, " and direction: ", next_direction)
				return
			#se obtiene la altura actual y se asegura que no rebase 1
			heightImage.lock()
			var height = heightImage.get_pixel(self.seed_point.x, self.seed_point.y).r
			heightImage.unlock()
			var next_height: float
			#var next_height: float = height + rng.randf_range(0, self.height_max - self.height_min)
			if height <= self.height_min:
				next_height = rng.randf_range(self.height_min, self.height_max)
			elif height > self.height_min && height < self.height_max:
				next_height = rng.randf_range(height, self.height_max)
			else:
				#print("too high ", height)
				continue
			#if height > 1.0:
			#	print("too high")
			#	continue
			
			elevation = next_height - height
			var elevation_left: float = elevation
			var elevation_right: float = elevation
			var degradation_left: float = rng.randf_range(0, self.slope_degradation)
			var degradation_right: float = rng.randf_range(0, self.slope_degradation)
			heightImage.lock()
			heightImage.set_pixel(self.seed_point.x, self.seed_point.y, Color(next_height, next_height, next_height, 1))
			heightImage.unlock()
			
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
						#se aplana
						flatten(Vector2(left_x, left_y), sea, heightImage, dynamic_list)
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
						#se aplana
						flatten(Vector2(right_x, right_y), sea, heightImage, dynamic_list)
			#se aplana la nueva altura
			flatten(Vector2(self.seed_point.x, self.seed_point.y), sea, heightImage, dynamic_list)	
			#se mueve la dirección en 45° aleatoriamente
			if i % self.restart_rate == 0 && i != 0:
				if self.direction_status == 1 || self.direction_status == -1:
					self.direction_status = 0
				else:
					self.direction_status = direction_status + MathUtils.random_sign(rng)
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
							self.direction_status = 0
							k = 8
			#ahora el punto correspondiente en la dirección del agente
			self.seed_point = next_point

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
