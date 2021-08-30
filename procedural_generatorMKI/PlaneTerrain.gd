extends MeshInstance

#variables sobre generación de terreno base
var heightMap
var biomeMap
var voronoiMap
var rng = RandomNumberGenerator.new()
var seaLevel = 0
var maxTemperature = 30
var minTemperature = 0
var wetPoints = 4

#variables sobre algoritmos físicos
var talus_angle = 0.015
var iterations = 10
#modified Von Neumann neighbourhood
var neighbourhood = [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]

func remap(iMin, iMax, oMin, oMax, v):
	var t = inverse_lerp(iMin, iMax, v)
	return lerp(oMin, oMax, t)
	
func generate_voronoi_diagram(imgSize : Vector2, num_cells: int, max_height: float, random_gen: RandomNumberGenerator):
	
	var img = Image.new()
	img.create(imgSize.x, imgSize.y, false, Image.FORMAT_RGBH)

	var points = []
	var rand_heights = []
	
	for i in range(num_cells):
		points.push_back(Vector2(int(random_gen.randf() * img.get_size().x), int(random_gen.randf() * img.get_size().y)))
		
		#var colorPossibilities = [ Color.blue, Color.red, Color.green, Color.purple, Color.yellow, Color.orange]
		rand_heights.push_back(random_gen.randf())
		
	for y in range(img.get_size().y):
		for x in range(img.get_size().x):
			var dmin = img.get_size().length()
			var dmin2 = img.get_size().length()
			var j = -1
			for i in range(num_cells):
				var d = (points[i] - Vector2(x, y)).length()
				if d < dmin:
					dmin2 = dmin
					dmin = d
					j = i
				elif d < dmin2 and d >= dmin:
					dmin2 = d
			var color_scale = remap(0, dmin2, max_height, 0, dmin) * rand_heights[j]
			img.lock()
			img.set_pixel(x, y, Color(color_scale, color_scale, color_scale, 1))
			img.unlock()
	return img

# Called when the node enters the scene tree for the first time.
func _ready():
	#Generación de terreno base se hace usando ruido simplex (implementación que Godot ya posee)
	#print(self.get_surface_material(0).get_shader_param("map"))
	var noise = OpenSimplexNoise.new()
	#reemplazar por semilla suministrada por el usuario
	noise.seed = 3493353#randi()
	rng.seed = noise.seed
	noise.octaves = 8
	noise.period = 64.0
	noise.persistence = 0.5
	noise.lacunarity = 2.0
	self.heightMap = ImageTexture.new()
	var heightImage = noise.get_image(512, 512)
	self.heightMap.create_from_image(heightImage)
	print("biome ", heightMap.get_data().get_height(), heightMap.get_data().get_width())
	self.get_surface_material(0).set_shader_param("map", heightMap)
	self.get_surface_material(0).set_shader_param("height_scale", 0.7)
	
	#se genera mapa de Voronoi
	self.voronoiMap = ImageTexture.new()
	self.voronoiMap.create_from_image(generate_voronoi_diagram(Vector2(512, 512), 15, 1, rng))
	self.get_surface_material(0).set_shader_param("voronoi_map", voronoiMap)
	
	#Paso de ajuste de terreno y simulación usando algún métodos físicos (erosión física y termal).
	#Se crea mapa de temperatura (R), humedad (G), vientos (BA)
	self.biomeMap = ImageTexture.new()
	var image = Image.new()
	image.create(512, 512, false, Image.FORMAT_RGBAF)
	image.lock()
	heightImage.lock()
	
	#se generan puntos iniciales d ehumedad a partir de los cuales se distribuirá la humedad por todo el terreno
	var wetConcentrations = []
	for i in self.wetPoints:
		wetConcentrations.append([rng.randi_range(0, image.get_width() -1), rng.randi_range(0, image.get_height() -1), rng.randf(), rng.randi_range(image.get_width() / 50, image.get_width() -1)])
		print("x: ", wetConcentrations[i][0], " y: ", wetConcentrations[i][1], " wet: ", wetConcentrations[i][2], " range: ", wetConcentrations[i][3], ", image lenght: ", image.get_size().length(), ", square length: ", image.get_width()* image.get_width() + image.get_height() * image.get_height())
	
	for y in image.get_height():
		for x in image.get_width():
			var height = heightImage.get_pixel(x, y).r
			#red representa temperatura
			var red = 1 - remap(minTemperature, maxTemperature, self.seaLevel, 1, height * (maxTemperature - minTemperature))
			#blue representa humedad
			var blue = 0
			for i in self.wetPoints:
				var terDif = ((pow(wetConcentrations[i][3], 2) -  pow(x - wetConcentrations[i][0], 2) - pow(y - wetConcentrations[i][1], 2)) / pow(wetConcentrations[i][3], 2)) - 0.1 * (height - heightImage.get_pixel(wetConcentrations[i][0], wetConcentrations[i][1]).r)
				if terDif < 0:
					terDif = 0
				blue += terDif * wetConcentrations[i][2]
			blue = blue / self.wetPoints
			#image.set_pixel(x, y, Color(self.rng.randf(), self.rng.randf(), self.rng.randf(), self.rng.randf()))
			image.set_pixel(x, y, Color(red, 0, blue, 1))

	#se aplica erosión termal optimizada de Olsen
	for iter in self.iterations:
		for y in image.get_height():
			for x in image.get_width():
				var slope_total = 0
				var slope_max = 0
				var height = heightImage.get_pixel(x, y).r
				#casilla objetivo donde se mandará el material erosionado
				var lowest_slope = 1
				var lowest_index = -1
				#se recorre vendiaro de Neumann
				for i in self.neighbourhood.size():
					var next_x = x + self.neighbourhood[i].x
					var next_y = y + self.neighbourhood[i].y
					#El vecindario debe quedar dentro de los constraints del mapa de alturas
					if next_x >= 0 and next_x < heightImage.get_width() and next_y >= 0 and next_y < heightImage.get_height():
						var height_i = heightImage.get_pixel(next_x, next_y).r
						var slope_i = height - height_i
						if slope_i > self.talus_angle:
							slope_total += slope_i
							if slope_i < lowest_slope:
								lowest_slope = slope_i
								lowest_index = i
							if slope_i > slope_max:
								slope_max = slope_i
				#Se mueve el material respectivo y se modifica el mapa de altura
				if lowest_index >= 0:
					var new_height = height - slope_max / 2
					heightImage.set_pixel(x, y, Color(new_height, new_height, new_height, 1))
					new_height = lowest_slope + slope_max / 2
					heightImage.set_pixel(x + self.neighbourhood[lowest_index].x, y + self.neighbourhood[lowest_index].y, Color(new_height, new_height, new_height, 1))
	image.unlock()
	heightImage.unlock()
	
	self.biomeMap.create_from_image(image)
	print("biome ", biomeMap.get_data().get_height(), biomeMap.get_data().get_width(), ", ", self.biomeMap.get_data())
	self.get_surface_material(0).set_shader_param("biome_map", biomeMap)
	self.get_surface_material(0).set_shader_param("seed", rng.randf_range(0, pow(2.0, 63)))
	
	#Paso de refinamiento de terreno usando técnicas de sistemas inteligentes
	#El texturizado se hace desde el fragment shader dependiendo de clima, humedad, altura, bioma, etc.
	
	#Paso de pocisionamiento de assets para dar mayor detalle al terreno
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
