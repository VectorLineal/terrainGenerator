extends MeshInstance

var heightMap

# Called when the node enters the scene tree for the first time.
func _ready():
	#Generación de terreno base se hace usando ruido simplex (implementación que Godot ya posee)
	#print(self.get_surface_material(0).get_shader_param("map"))
	var noise = OpenSimplexNoise.new()
	noise.seed = randi()
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
	
	#Paso de refinamiento de terreno usando técnicas de sistemas inteligentes
	#El texturizado se hace desde el fragment shader dependiendo de clima, humedad, altura, bioma, etc.
	
	#Paso de pocisionamiento de assets para dar mayor detalle al terreno
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
