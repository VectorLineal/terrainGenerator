extends MeshInstance

#var Voronoi = load("Voronio.gd")

#variables sobre generación de terreno base
var heightMap
var biomeMap
var rng = RandomNumberGenerator.new()
var size = 512

#Variables sobre la generación climática
var seaLevel = 0
var maxTemperature = 30
var minTemperature = 0
var wetPoints = 8
var maxWet = 1
var maxWetRange = 0.6
var climate_iterations = 50

#variables sobre algoritmos físicos
var talus_angle = 20 / self.size
var iterations = 50
#modified Von Neumann neighbourhood
var neighbourhood = [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]
var fullNeighbourhood = [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1), Vector2(0, -1), Vector2(1, 0), Vector2(0, 1), Vector2(-1, 0)]

# Called when the node enters the scene tree for the first time.
func _ready():
	#Generación de terreno base se hace usando ruido simplex (implementación que Godot ya posee)
	var noise = OpenSimplexNoise.new()
	#reemplazar por semilla suministrada por el usuario
	noise.seed = 3419374653#randi()
	rng.set_seed(noise.seed)
	noise.octaves = 8
	noise.period = 64.0
	noise.persistence = 0.5
	noise.lacunarity = 2.0
	self.heightMap = ImageTexture.new()
	var heightImage = noise.get_image(size, size)
	#se aplica mapa de Voronoi
	Voronoi.apply_voronoi_diagram(heightImage, 16, 1, 0.25, 0.0, rng)
	
	#Paso de ajuste de terreno y simulación usando algún métodos físicos (erosión física y termal).
	#se genera mapa de biomas, contiene humedad y temperatura
	self.biomeMap = ImageTexture.new()
	var image = Image.new()
	image.create(size, size, false, Image.FORMAT_RGBAF)
	#se aplica algoritmo de refinamiento de terreno
	#TerrainRefinement.thermal_erosion(heightImage, self.talus_angle, self.iterations, self.neighbourhood)
	TerrainRefinement.olsen_erosion(heightImage, self.talus_angle, self.iterations, self.neighbourhood)
	#se generan puntos iniciales de humedad a partir de los cuales se distribuirá la humedad por todo el terreno
	var wetConcentrations = Weather.generate_Wet_points(image, wetPoints, maxWet, maxWetRange, rng)
	#se distribuyen humedad y temperatura, además se calcula mapa de inclinaciones
	Weather.distribute_wet_temp(image, heightImage, minTemperature, maxTemperature, seaLevel, maxWet, wetPoints, wetConcentrations, fullNeighbourhood)
	#se aplica campo vetorial de vientos al mapa de clima para simular precipitaciones
	Weather.simulate_precipitations(image, heightImage, climate_iterations, maxWet, 5, self.rng)
	
	#se pasan variables uniformes al shader
	self.heightMap.create_from_image(heightImage)
	#print("biome ", heightMap.get_data().get_height(), heightMap.get_data().get_width())
	self.get_surface_material(0).set_shader_param("map", heightMap)
	self.get_surface_material(0).set_shader_param("height_scale", 0.75)
	self.biomeMap.create_from_image(image)
	print("biome ", biomeMap.get_data().get_height(), "x", biomeMap.get_data().get_width(), ", seed: ", self.rng.get_seed())
	self.get_surface_material(0).set_shader_param("biome_map", biomeMap)
	self.get_surface_material(0).set_shader_param("seed", rng.randf_range(0, 300000))
	
	#Paso de refinamiento de terreno usando técnicas de sistemas inteligentes
	#El texturizado se hace desde el fragment shader dependiendo de temperatura y humedad que producen un bioma.
	
	#Paso de pocisionamiento de assets para dar mayor detalle al terreno
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
