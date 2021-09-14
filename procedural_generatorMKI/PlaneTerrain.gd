extends MeshInstance

#var Voronoi = load("Voronio.gd")

#variables sobre generación de terreno base
var heightMap
var biomeMap
var rng = RandomNumberGenerator.new()
var seaLevel = 0
var maxTemperature = 30
var minTemperature = 0
var wetPoints = 5
var climate_iterations = 10

#variables sobre algoritmos físicos
var talus_angle = 0.03125
var iterations = 25
#modified Von Neumann neighbourhood
var neighbourhood = [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]

# Called when the node enters the scene tree for the first time.
func _ready():
	#Generación de terreno base se hace usando ruido simplex (implementación que Godot ya posee)
	#print(self.get_surface_material(0).get_shader_param("map"))
	var noise = OpenSimplexNoise.new()
	#reemplazar por semilla suministrada por el usuario
	noise.seed = 3493353#randi()
	rng.set_seed(noise.seed)
	noise.octaves = 8
	noise.period = 64.0
	noise.persistence = 0.5
	noise.lacunarity = 2.0
	self.heightMap = ImageTexture.new()
	var heightImage = noise.get_image(512, 512)
	Voronoi.apply_voronoi_diagram(heightImage, 16, 1, rng)
	
	#se genera mapa de Voronoi
	#self.voronoiMap = ImageTexture.new()
	#self.voronoiMap.create_from_image(Voronoi.generate_voronoi_diagram(Vector2(512, 512), 15, 1, rng))
	#self.get_surface_material(0).set_shader_param("voronoi_map", voronoiMap)
	
	#Paso de ajuste de terreno y simulación usando algún métodos físicos (erosión física y termal).
	self.biomeMap = ImageTexture.new()
	var image = Image.new()
	image.create(512, 512, false, Image.FORMAT_RGBAF)
	image.lock()
	heightImage.lock()
	
	#se aplica erosión termal optimizada de Olsen
	for iter in self.iterations:
		for y in heightImage.get_height():
			for x in heightImage.get_width():
# warning-ignore:unused_variable
				var slope_total = 0
				var slope_max = 0
				var height = heightImage.get_pixel(x, y).r
				#casilla objetivo donde se mandará el material erosionado
				var lowest_height = 1
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
							if slope_i > slope_max:
								lowest_height = height_i
								slope_max = slope_i
								lowest_index = i
				#Se mueve el material respectivo y se modifica el mapa de altura
				if lowest_index >= 0:
					var new_height = height - slope_max / 2
					heightImage.set_pixel(x, y, Color(new_height, new_height, new_height, 1))
					new_height = lowest_height + slope_max / 2
					heightImage.set_pixel(x + self.neighbourhood[lowest_index].x, y + self.neighbourhood[lowest_index].y, Color(new_height, new_height, new_height, 1))
	
	#se generan puntos iniciales de humedad a partir de los cuales se distribuirá la humedad por todo el terreno
	var wetConcentrations = []
	for i in self.wetPoints:
		wetConcentrations.append([rng.randi_range(0, image.get_width() -1), rng.randi_range(0, image.get_height() -1), rng.randf(), rng.randi_range(image.get_width() / 50, image.get_width() -1)])
		print("x: ", wetConcentrations[i][0], " y: ", wetConcentrations[i][1], " wet: ", wetConcentrations[i][2], " range: ", wetConcentrations[i][3])
	
	#Se crea mapa de temperatura (R), humedad (B)
	var max_blue = 0
	for y in image.get_height():
		for x in image.get_width():
			var height = heightImage.get_pixel(x, y).r
			#red representa temperatura
			var red = 1 - MathUtils.remap(minTemperature, maxTemperature, self.seaLevel, 1, height * (maxTemperature - minTemperature))
			#blue representa humedad
			var blue = 0
			for i in self.wetPoints:
				var terDif = ((pow(wetConcentrations[i][3], 2) -  pow(x - wetConcentrations[i][0], 2) - pow(y - wetConcentrations[i][1], 2)) / pow(wetConcentrations[i][3], 2)) - 0.1 * (height - heightImage.get_pixel(wetConcentrations[i][0], wetConcentrations[i][1]).r)
				if terDif < 0:
					terDif = 0
				blue += terDif * wetConcentrations[i][2]
			if blue > max_blue:
				max_blue = blue
			if max_blue > 0:
				blue = blue / max_blue
			#image.set_pixel(x, y, Color(self.rng.randf(), self.rng.randf(), self.rng.randf(), self.rng.randf()))
			#print("map x: ", x, " y: ", y, " wet: ", blue)
			image.set_pixel(x, y, Color(red, 0, blue, 1))
	#se aplica campo vetorial de vientos al mapa de clima para simular precipitaciones
	var wind_field = MathUtils.generate_vectorial_fractal_field(image.get_width(), image.get_height(), self.rng)
	for k in self.climate_iterations:
		for y in image.get_height():
			for x in image.get_width():
				var red = image.get_pixel(x, y).r
				var blue = image.get_pixel(x, y).b
				var max_delta_wet = 1 - blue
				var coords = MathUtils.angle_to_grid(wind_field[x][y])
				var next_x = x - coords[0]
				var next_y = y - coords[1]
				if next_x >= 0 and next_x < image.get_width() and next_y >= 0 and next_y < image.get_height():
					var red_i = image.get_pixel(next_x, next_y).r
					var blue_i = image.get_pixel(next_x, next_y).b
					var wet_i = red_i * blue_i
					if wet_i > max_delta_wet:
						wet_i = max_delta_wet
					blue += wet_i
					if blue_i - wet_i < 0 or blue_i - wet_i > 1:
						print("map x: ", next_x, " y: ", next_y, " wet: ", blue_i - wet_i)
					if blue < 0 or blue > 1:
						print("map x: ", x, " y: ", y, " wet: ", blue)
					image.set_pixel(next_x, next_y, Color(red_i, 0, blue_i - wet_i, 1))
					image.set_pixel(x, y, Color(red, 0, blue, 1))
	image.unlock()
	heightImage.unlock()
	
	#se pasan variables uniformes al shader
	self.heightMap.create_from_image(heightImage)
	#print("biome ", heightMap.get_data().get_height(), heightMap.get_data().get_width())
	self.get_surface_material(0).set_shader_param("map", heightMap)
	self.get_surface_material(0).set_shader_param("height_scale", 1)
	self.biomeMap.create_from_image(image)
	print("biome ", biomeMap.get_data().get_height(), "x", biomeMap.get_data().get_width(), ", seed: ", self.rng.get_seed())
	self.get_surface_material(0).set_shader_param("biome_map", biomeMap)
	self.get_surface_material(0).set_shader_param("seed", rng.randf_range(0, pow(2.0, 63)))
	
	#Paso de refinamiento de terreno usando técnicas de sistemas inteligentes
	#El texturizado se hace desde el fragment shader dependiendo de clima, humedad, altura, bioma, etc.
	
	#Paso de pocisionamiento de assets para dar mayor detalle al terreno
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
