extends MeshInstance

var heightMap
var biomeMap
var rng = RandomNumberGenerator.new()
var seaLevel = 0
var maxTemperature = 30
var minTemperature = 0

func remap(iMin, iMax, oMin, oMax, v):
	var t = inverse_lerp(iMin, iMax, v)
	return lerp(oMin, oMax, t)

# Called when the node enters the scene tree for the first time.
func _ready():
	#Generación de terreno base se hace usando ruido simplex (implementación que Godot ya posee)
	#print(self.get_surface_material(0).get_shader_param("map"))
	var noise = OpenSimplexNoise.new()
	#reemplazar por semilla suministrada por el usuario
	noise.seed = 10000#randi()
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
	for y in image.get_height():
		for x in image.get_width():
			#image.set_pixel(x, y, Color(self.rng.randf(), self.rng.randf(), self.rng.randf(), self.rng.randf()))
			if heightImage.get_pixel(x, y).r >= 2.0 / 3.0 or heightImage.get_pixel(x, y).r <= 8.0 / 9.0:
				image.set_pixel(x, y, Color(1 - remap(minTemperature, maxTemperature, 0, 1, heightImage.get_pixel(x, y).r * (maxTemperature - minTemperature)), 0, 0, 1))
			else:
				image.set_pixel(x, y, Color(1 - self.rng.randf_range(2.0 / 3.0,8.0 / 9.0), 0, 0, 1))
	
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
