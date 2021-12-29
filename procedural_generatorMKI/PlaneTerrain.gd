extends MeshInstance

#variables sobre generación de terreno base
var heightMap
var biomeMap
var rng = RandomNumberGenerator.new()
var size = 512
var original_seed
var octaves = 8
var period = 64.0
var persistence = 0.5
var lacunarity = 2.0

#variables para medir desempeño
var slope_score

#Variables sobre la generación climática
var seaLevel = 0.1
var maxTemperature = 30
var minTemperature = 0
var wetPoints = 10
var maxWet = 1.0
var maxWetRange = 0.6
var climate_iterations = 0

#variables sobre algoritmos físicos
var talus_angle = 20 / self.size
var iterations = 5

#variables sobre agentes
var detail = 8
var landmass = 0.4
var smooth_tokens = 800
var smooth_amount = 15
var smooth_refresh_times = 4
var beach_tokens = 1000
var mountain_tokens = 1000
var river_tokens = 1000
var agent_manager

# Called when the node enters the scene tree for the first time.
func _ready():
	#Generación de terreno base se hace usando ruido simplex (implementación que Godot ya posee)
	var noise = OpenSimplexNoise.new()
	#reemplazar por semilla suministrada por el usuario
	self.original_seed = 3419374653#randi()
	noise.seed = self.original_seed
	rng.set_seed(noise.seed)
	noise.octaves = self.octaves
	noise.period = self.period
	noise.persistence = self.persistence
	noise.lacunarity = self.lacunarity
	self.heightMap = ImageTexture.new()
	var heightImage = Image.new()
	
	#se aplica ruido simplex para crear mapa de altura
	##heightImage = noise.get_image(size, size)
	#var heightImage = Voronoi.generate_voronoi_diagram(Vector2(512, 512), 24, 1.0, self.rng)
	#se aplica mapa de Voronoi
	##Voronoi.apply_voronoi_diagram(heightImage, 24, 1, 0.25, 0.0, rng)
	
	heightImage.create(size, size, false, Image.FORMAT_RGBAF)
	#agente de costa
	var limit = int((self.landmass * size * size) / (pow(2.0, self.detail))) + 1
	var coast_tokens = floor(self.landmass * size * size)
	var smooth_refresh_rate = int(self.smooth_tokens / smooth_refresh_times)
	agent_manager = AgentManager.new(limit, coast_tokens, self.smooth_tokens, self.smooth_amount, smooth_refresh_rate, self.beach_tokens, self.mountain_tokens, self.river_tokens)
	agent_manager.start_coast_agents(self.seaLevel, heightImage, rng)
	agent_manager.start_smooth_agents(self.seaLevel, heightImage, rng)
	#agent_manager.run_coast_agents(self.seaLevel, heightImage, rng)
	
	#Paso de ajuste de terreno y simulación usando algún métodos físicos (erosión física y termal).
	#se genera mapa de biomas, contiene humedad y temperatura
	self.biomeMap = ImageTexture.new()
	var image = Image.new()
	image.create(size, size, false, Image.FORMAT_RGBAF)
	
	#se aplica algoritmo de refinamiento de terreno
	#TerrainRefinement.thermal_erosion(heightImage, self.talus_angle, self.iterations)
	##TerrainRefinement.olsen_erosion(heightImage, self.talus_angle, self.iterations)
	#se generan puntos iniciales de humedad a partir de los cuales se distribuirá la humedad por todo el terreno
	var wetConcentrations = Weather.generate_Wet_points(image, wetPoints, maxWet, maxWetRange, rng)
	#se distribuyen humedad y temperatura, además se calcula mapa de inclinaciones
	Weather.distribute_wet_temp(image, heightImage, minTemperature, maxTemperature, seaLevel, maxWet, wetPoints, wetConcentrations)
	#se obtienen medidas de calidad del terreno generado
	self.slope_score = MathUtils.calculate_scores(image)
	print("slope mean = ", slope_score.x, ", slope standard desviation = ", slope_score.y, ", erosion score = ", slope_score.z)
	#se aplica campo vetorial de vientos al mapa de clima para simular precipitaciones
	Weather.simulate_precipitations(image, heightImage, climate_iterations, maxWet, 2, 0.15, 0.02, self.rng)
	
	#se pasan variables uniformes al shader
	self.heightMap.create_from_image(heightImage)
	#print("biome ", heightMap.get_data().get_height(), heightMap.get_data().get_width())
	self.get_surface_material(0).set_shader_param("map", heightMap)
	self.get_surface_material(0).set_shader_param("height_scale", 0.75)
	self.biomeMap.create_from_image(image)
	print("biome ", biomeMap.get_data().get_height(), "x", biomeMap.get_data().get_width(), ", seed: ", self.original_seed)
	self.get_surface_material(0).set_shader_param("biome_map", biomeMap)
	self.get_surface_material(0).set_shader_param("seed", rng.randf_range(0, 300000))
	
	#Paso de refinamiento de terreno usando técnicas de sistemas inteligentes
	#El texturizado se hace desde el fragment shader dependiendo de temperatura y humedad que producen un bioma.
	
	#Paso de pocisionamiento de assets para dar mayor detalle al terreno
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
