class_name Weather

#genera puntos de humedad aleatorios
static func generate_Wet_points(image: Image ,wet_points: int, maxWet: float, maxWetRange: float, rng: RandomNumberGenerator):
	var wetConcentrations = []
	for i in wet_points:
		#pocisiona puntos de humedad de rango aleatorio entre 0 y maxwetrange de cantidad aleatoria entre 0 y maxwet
		wetConcentrations.append([rng.randi_range(0, image.get_width() -1), rng.randi_range(0, image.get_height() -1), rng.randf() * maxWet, rng.randi_range(image.get_width() / 50, image.get_width() -1) * maxWetRange])
		print("x: ", wetConcentrations[i][0], " y: ", wetConcentrations[i][1], " wet: ", wetConcentrations[i][2], " range: ", wetConcentrations[i][3])
	return wetConcentrations

#se crea mapa de temperatura y humedad además de calcular inclinación media en cada casilla
static func distribute_wet_temp(image: Image, heightImage: Image, minTemperature: float, maxTemperature: float, seaLevel: float, maxWet: float, wetPoints: int, wetConcentrations: Array):
	image.lock()
	heightImage.lock()
	#Se crea mapa de temperatura (R), inclinación (G), humedad (B)
	var max_blue = 0
	for y in image.get_height():
		for x in image.get_width():
			var height = heightImage.get_pixel(x, y).r
			var slope_total = 0
			var neighbours_visited = 0
			for i in MathUtils.fullNeighbourhood.size():
					var next_x = x + MathUtils.fullNeighbourhood[i].x
					var next_y = y + MathUtils.fullNeighbourhood[i].y
					#El vecindario debe quedar dentro de los constraints del mapa de alturas
					if next_x >= 0 and next_x < heightImage.get_width() and next_y >= 0 and next_y < heightImage.get_height():
						var height_i = heightImage.get_pixel(next_x, next_y).r
						var slope_i = abs(height - height_i)
						slope_total += slope_i
						neighbours_visited += 1
			#green  representa el mapa de inclinaciones
			var green = slope_total / neighbours_visited
			#red representa temperatura
			var red = 1 - MathUtils.remap(minTemperature, maxTemperature, seaLevel, 1, height * (maxTemperature - minTemperature))
			#blue representa humedad
			var blue = 0
			for i in wetPoints:
				var terDif = ((pow(wetConcentrations[i][3], 2) -  pow(x - wetConcentrations[i][0], 2) - pow(y - wetConcentrations[i][1], 2)) / pow(wetConcentrations[i][3], 2)) - 0.1 * (height - heightImage.get_pixel(wetConcentrations[i][0], wetConcentrations[i][1]).r)
				if terDif < 0:
					terDif = 0
				blue += terDif * wetConcentrations[i][2]
			if blue > max_blue:
				max_blue = blue
			if max_blue > 0:
				blue = blue / max_blue
			#print("map x: ", x, " y: ", y, " wet: ", blue," temp: ", red)
			image.set_pixel(x, y, Color(red, green, blue * maxWet, 1))
	image.unlock()
	heightImage.unlock()

#simula movimiento de humedad dependiendo del campo vectorial de vientos
static func simulate_precipitations(image: Image, heightImage: Image, climate_iterations: int, maxWet: float, refresh_rate: int, retention: float, maxWetRange: float, rng: RandomNumberGenerator):
	#se genera campo vectorial de vientos
	var wind_field = MathUtils.generate_vectorial_fractal_field(image.get_width(), image.get_height(), rng)
	#se procede a la simulación
	image.lock()
	heightImage.lock()
	for k in climate_iterations:
		if k > 0 and k % refresh_rate == 0:
			wind_field = MathUtils.generate_vectorial_fractal_field(image.get_width(), image.get_height(), rng)
		for y in image.get_height():
			for x in image.get_width():
				var red = image.get_pixel(x, y).r
				var blue = image.get_pixel(x, y).b
				var delta_wet = red * blue
				var max_delta_wet = blue * (1 - retention)
				if max_delta_wet > 0:
					var coords = MathUtils.vec_to_grid(Vector2(x, y), wind_field[x][y], Vector2(image.get_width(), image.get_height()), maxWetRange)
					var next_x = coords[0]
					var next_y = coords[1]
					if next_x != x or next_y != y:
						var red_i = image.get_pixel(next_x, next_y).r
						var blue_i = image.get_pixel(next_x, next_y).b
						var max_delta_wet_i = maxWet - blue_i
						if max_delta_wet_i < max_delta_wet:
							max_delta_wet = max_delta_wet_i
						if delta_wet > max_delta_wet:
							delta_wet = max_delta_wet
						blue -= delta_wet
						blue_i += delta_wet
						#print("map x: ", x, " y: ", y, " wet: ", blue, ", delta: ", delta_wet)
						#print("to x: ", next_x, " y: ", next_y, " wet: ", blue_i)
						if blue_i < 0 or blue_i > 1:
							print("map x: ", next_x, " y: ", next_y, " wet: ", blue_i)
						if blue < 0 or blue > 1:
							print("map x: ", x, " y: ", y, " wet: ", blue," temp: ", red)
						image.set_pixel(x, y, Color(red, 0, blue * maxWet, 1))
						image.set_pixel(next_x, next_y, Color(red_i, 0, blue_i, 1))
	image.unlock()
	heightImage.unlock()
