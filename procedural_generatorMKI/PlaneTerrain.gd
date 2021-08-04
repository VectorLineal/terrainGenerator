extends MeshInstance

var heightMap
var biomeMap
var rng = RandomNumberGenerator.new()

# Called when the node enters the scene tree for the first time.
func _ready():
	#Generación de terreno base se hace usando ruido simplex (implementación que Godot ya posee)
	#print(self.get_surface_material(0).get_shader_param("map"))
	var noise = OpenSimplexNoise.new()
	#reemplazar por semilla suministrada por el usuario
	noise.seed = randi()
	rng.seed = noise.seed
	noise.octaves = 4
	noise.period = 64.0
	noise.persistence = 0.5
	noise.lacunarity = 2.0
	self.heightMap = NoiseTexture.new()
	self.heightMap.noise = noise
	print(heightMap.height, heightMap.width)
	self.get_surface_material(0).set_shader_param("map", heightMap)
	self.get_surface_material(0).set_shader_param("height_scale", 0.7)
	
	#Paso de ajuste de terreno y simulación usando algún métodos físicos (erosión física y termal).
	#Se crea mapa de temperatura (R), humedad (G), vientos (BA)
	self.biomeMap = ImageTexture.new()
	var image = Image.new()
	image.create(512, 512, false, Image.FORMAT_RGBAF)
	image.lock()
	for y in image.get_height():
		for x in image.get_width():
			image.set_pixel(x, y, Color(self.rng.randf(), self.rng.randf(), self.rng.randf(), self.rng.randf()))
	
	image.unlock()
	
	self.biomeMap.create_from_image(image)
	print("biome ", biomeMap.get_data().get_height(), biomeMap.get_data().get_width(), ", ", self.biomeMap.get_data())
	self.get_surface_material(0).set_shader_param("biome_map", biomeMap)
	
	#Paso de refinamiento de terreno usando técnicas de sistemas inteligentes
	#El texturizado se hace desde el fragment shader dependiendo de clima, humedad, altura, bioma, etc.
	
	#Paso de pocisionamiento de assets para dar mayor detalle al terreno
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
