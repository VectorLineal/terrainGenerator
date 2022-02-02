class_name TerrainRefinement

static func thermal_erosion(heightImage: Image, talus_angle: float, iterations: int):
	heightImage.lock()
	for iter in iterations:
		for y in heightImage.get_height():
			for x in heightImage.get_width():
				var slope_max = 0
				var height = heightImage.get_pixel(x, y).r
				#casilla objetivo donde se mandará el material erosionado
				var lowest_height = 1
				var lowest_index = -1
				#se recorre vendiaro de Neumann
				for i in MathUtils.neighbourhood.size():
					var next_x = x + MathUtils.neighbourhood[i].x
					var next_y = y + MathUtils.neighbourhood[i].y
					#El vecindario debe quedar dentro de los constraints del mapa de alturas
					if next_x >= 0 and next_x < heightImage.get_width() and next_y >= 0 and next_y < heightImage.get_height():
						var height_i = heightImage.get_pixel(next_x, next_y).r
						var slope_i = height - height_i
						if slope_i > talus_angle:
							if slope_i > slope_max:
								lowest_height = height_i
								slope_max = slope_i
								lowest_index = i
				#Se mueve el material respectivo y se modifica el mapa de altura
				if lowest_index >= 0:
					var new_height = height - slope_max / 2
					heightImage.set_pixel(x, y, Color(new_height, new_height, new_height, 1))
					new_height = lowest_height + slope_max / 2
					heightImage.set_pixel(x + MathUtils.neighbourhood[lowest_index].x, y + MathUtils.neighbourhood[lowest_index].y, Color(new_height, new_height, new_height, 1))
	heightImage.unlock()

static func olsen_erosion(heightImage: Image, talus_angle: float, iterations: int):
	#versión modificada de erosion termal del paper de Jacob Olsen
	heightImage.lock()
	for iter in iterations:
		for y in heightImage.get_height():
			for x in heightImage.get_width():
				var slope_max = 0
				var height = heightImage.get_pixel(x, y).r
				#casilla objetivo donde se mandará el material erosionado
				var lowest_height = 1
				var lowest_index = -1
				#se recorre vendiaro de Neumann
				for i in MathUtils.neighbourhood.size():
					var next_x = x + MathUtils.neighbourhood[i].x
					var next_y = y + MathUtils.neighbourhood[i].y
					#El vecindario debe quedar dentro de los constraints del mapa de alturas
					if next_x >= 0 and next_x < heightImage.get_width() and next_y >= 0 and next_y < heightImage.get_height():
						var height_i = heightImage.get_pixel(next_x, next_y).r
						var slope_i = height - height_i
						if slope_i > slope_max:
							lowest_height = height_i
							slope_max = slope_i
							lowest_index = i
				#Se mueve el material respectivo y se modifica el mapa de altura
				if lowest_index >= 0:
					if slope_max > 0 and slope_max <= talus_angle:
						var new_height = height - slope_max / 2
						heightImage.set_pixel(x, y, Color(new_height, new_height, new_height, 1))
						new_height = lowest_height + slope_max / 2
						heightImage.set_pixel(x + MathUtils.neighbourhood[lowest_index].x, y + MathUtils.neighbourhood[lowest_index].y, Color(new_height, new_height, new_height, 1))
	heightImage.unlock()

static func smooth_map(heightImage: Image):
	#aplana todo el mapa una única vez
	heightImage.lock()
	for y in heightImage.get_height():
		for x in heightImage.get_width():
			var height = heightImage.get_pixel(x, y).r
			var acumulation = 3 * height
			var counter = 3.0
			for i in MathUtils.fullNeighbourhood.size():
				var next_x = x + MathUtils.fullNeighbourhood[i].x
				var next_y = y + MathUtils.fullNeighbourhood[i].y
				#El vecindario debe quedar dentro de los constraints del mapa de alturas
				if next_x >= 0 and next_x < heightImage.get_width() and next_y >= 0 and next_y < heightImage.get_height():
					var height_i = heightImage.get_pixel(next_x, next_y).r
					acumulation += height_i
					counter += 1.0
			#Se ajusta la nueva altura
			var new_height = acumulation / counter
			heightImage.set_pixel(x, y, Color(new_height, new_height, new_height, 1))
	heightImage.unlock()
