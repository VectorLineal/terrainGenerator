extends MeshInstance

var heightMap
var biomeMap
var rng = RandomNumberGenerator.new()
var seaLevel = 0
var maxTemperature = 30
var minTemperature = 0
var wetPoints = 4

func remap(iMin, iMax, oMin, oMax, v):
	var t = inverse_lerp(iMin, iMax, v)
	return lerp(oMin, oMax, t)

# Called when the node enters the scene tree for the first time.
func _ready():
	#Generación de terreno base se hace usando ruido simplex (implementación que Godot ya posee)
	#print(self.get_surface_material(0).get_shader_param("map"))
	var noise = OpenSimplexNoise.new()
	#reemplazar por semilla suministrada por el usuario
	noise.seed = 3493353#randi()
	rng.seed = noise.seed
	noise.octaves = 4
	noise.period = 64.0
	noise.persistence = 0.5
	noise.lacunarity = 2.0
	self.heightMap = ImageTexture.new()
	var heightImage = noise.get_image(512, 512)
	self.heightMap.create_from_image(heightImage)
	print("biome ", heightMap.get_data().get_height(), heightMap.get_data().get_width())
	self.get_surface_material(0).set_shader_param("map", heightMap)
	self.get_surface_material(0).set_shader_param("height_scale", 0.7)
	
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
		wetConcentrations.append([rng.randi_range(0, image.get_width() -1), rng.randi_range(0, image.get_height() -1), rng.randf(), rng.randi_range(0, image.get_width() -1)])
		print("x: ", wetConcentrations[i][0], " y: ", wetConcentrations[i][1], " wet: ", wetConcentrations[i][2], " range: ", wetConcentrations[i][3])
	
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
