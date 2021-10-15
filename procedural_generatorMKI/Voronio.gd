class_name Voronoi

#genera un mapa de Voronoi
static func generate_voronoi_diagram(imgSize : Vector2, num_cells: int, max_height: float, random_gen: RandomNumberGenerator):
	var img = Image.new()
	img.create(imgSize.x, imgSize.y, false, Image.FORMAT_RGBH)

	var points = []
	var rand_heights = []
	
	#se generan los centros de las regiones del mapa y su altura máxima respectiva
	for i in range(num_cells):
		points.push_back(Vector2(int(random_gen.randf() * img.get_size().x), int(random_gen.randf() * img.get_size().y)))
		rand_heights.push_back(random_gen.randf())
		
	for y in range(img.get_size().y):
		for x in range(img.get_size().x):
			var dmin = img.get_size().length()
			var dmin2 = img.get_size().length()
			var j = -1 #guarda el índice del punto central más cercano
			for i in range(num_cells):
				#se almacena distancia de cada vector centro hasta el punto actual
				var d = (points[i] - Vector2(x, y)).length()
				#se guarda la distancia mínima y la segunda distancia mínima
				if d < dmin:
					dmin2 = dmin
					dmin = d
					j = i
				elif d < dmin2 and d >= dmin:
					dmin2 = d
			#a partir de ambas distancias se obtiene el color del punto
			var color_scale = MathUtils.remap(0, dmin2, max_height, 0, dmin) * rand_heights[j]
			#se almacenan los colores en la imagen
			img.lock()
			img.set_pixel(x, y, Color(color_scale, color_scale, color_scale, 1))
			img.unlock()
	return img
	
#aplica mapa de Voronoi a un mapa de altura target
static func apply_voronoi_diagram(target : Image, num_cells: int, max_height: float, clipping: float, valley_prob: float, random_gen: RandomNumberGenerator):
	var points = []
	var rand_heights = []
	#se almacena distancia de cada vector centro hasta el punto actual
	for i in range(num_cells):
		points.push_back(Vector2(int(random_gen.randf() * target.get_size().x), int(random_gen.randf() * target.get_size().y)))
		#si se determina que el punto es un valle, su altura debe ser 0
		if random_gen.randf() >= valley_prob:
			rand_heights.push_back(random_gen.randf())
		else:
			rand_heights.push_back(0)
		
	for y in range(target.get_size().y):
		for x in range(target.get_size().x):
			var dmin = target.get_size().length()
			var dmin2 = target.get_size().length()
			var j = -1 #guarda el índice del punto central más cercano
			for i in range(num_cells):
				#se almacena distancia de cada vector centro hasta el punto actual
				var d = (points[i] - Vector2(x, y)).length()
				#se guarda la distancia mínima y la segunda distancia mínima
				if d < dmin:
					dmin2 = dmin
					dmin = d
					j = i
				elif d < dmin2 and d >= dmin:
					dmin2 = d
			#a partir de ambas distancias se obtiene el color del punto
			var color_scale = (MathUtils.remap(0, dmin2, max_height, 0, dmin) * rand_heights[j]) - clipping
			#No pueden quedar valores debajo de 0
			if color_scale < 0:
				color_scale = 0
			#se promedia valor obtenido con el del mapa de altura y se sobreescribe el mapa de altura
			target.lock()
			color_scale += target.get_pixel(x, y).r
			target.set_pixel(x, y, Color(color_scale / 2, color_scale / 2, color_scale / 2, 1))
			target.unlock()
