class_name AgentManager

#var CoastAgent = load("CoastAgent.gd")

var coast_limit: int
var coast: int
var smooth: int
var beach: int
var mountain: int
var river: int
var coast_agents: Array = []
var dynamic_filled_list: Array = []
var smooth_agents: Array = []
var beach_agents: Array = []
var mountain_agents: Array = []
var river_agents: Array = []

func _init(limit_a: int, coast_t: int, smooth_t: int, beach_t: int, mountain_t: int, river_t: int):
	self.coast_limit = limit_a
	self.coast = coast_t
	self.smooth = smooth_t
	self.beach = beach_t
	self.mountain = mountain_t
	self.river = river_t
	
func start_coast_agents(sea_level: float, heightImage: Image, random_gen: RandomNumberGenerator):
	var children = 1
	var available = self.coast
	#partimos los tokens en la cantidad de hijos necesarios para cumplir con el límite
	while available >= self.coast_limit:
		available /= 2
		children *= 2
	#se crean los agentes hijos y se añaden a la lista de agentes
	available = int(available)
	print("children amount: ", children, " with ", available, " tokens each")
	for i in children:
		var child = CoastAgent.new(available, self.dynamic_filled_list, sea_level, heightImage, random_gen)
		self.coast_agents.append(child)
		child.run(self.dynamic_filled_list, sea_level, heightImage, random_gen)
		print("running ", i, " agent: ", child._to_string())

func run_coast_agents(sea_level: float, heightImage: Image, random_gen: RandomNumberGenerator):
	for i in self.coast_agents.size():
		self.coast_agents[i].run(sea_level, heightImage, random_gen)
