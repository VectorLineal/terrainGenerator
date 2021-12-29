class_name AgentManager

#var CoastAgent = load("CoastAgent.gd")
#coast agents
var coast_limit: int
var coast: int
var coast_agents: Array = []
#smooth agents
var smooth: int
var smooth_amount: int
var smooth_refresh: int
var smooth_agents: Array = []
#beach agents
var beach: int
var beach_agents: Array = []
#mountain agents
var mountain: int
var mountain_agents: Array = []
#river agents
var river: int
var river_agents: Array = []
#auxiliars
var dynamic_filled_list: Array = []

func _init(limit_a: int, coast_t: int, smooth_t: int, smooth_amount: int, smooth_refresh: int, beach_t: int, mountain_t: int, river_t: int):
	self.coast_limit = limit_a
	self.coast = coast_t
	self.smooth = smooth_t
	self.smooth_amount = smooth_amount
	self.smooth_refresh = smooth_refresh
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
	print("coast children amount: ", children, " with ", available, " tokens each")
	for i in children:
		var child = CoastAgent.new(available, self.dynamic_filled_list, sea_level, heightImage, random_gen)
		self.coast_agents.append(child)
		child.run(self.dynamic_filled_list, sea_level, heightImage, random_gen)
		print("running ", i, " coast agent: ", child._to_string())

func run_coast_agents(sea_level: float, heightImage: Image, random_gen: RandomNumberGenerator):
	for i in self.coast_agents.size():
		self.coast_agents[i].run(self.dynamic_filled_list, sea_level, heightImage, random_gen)

func start_smooth_agents(sea_level: float, heightImage: Image, random_gen: RandomNumberGenerator):
	print("smooth agents amount: ", self.smooth_amount, " with ", self.smooth, " tokens each")
	for i in self.smooth_amount:
		var smoother = SmoothAgent.new(self.smooth, self.smooth_refresh, self.dynamic_filled_list, sea_level, heightImage, random_gen)
		self.smooth_agents.append(smoother)
		smoother.run(self.dynamic_filled_list, sea_level, heightImage, random_gen)
		print("running ", i, " smooth agent: ", smoother._to_string())
