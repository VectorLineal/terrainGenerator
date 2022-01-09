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
var beach_amount: int
var beach_agents: Array = []
#mountain agents
var mountain: int
var mountain_amount: int
var mountain_refresh: int
var mountain_agents: Array = []
#hill agents
var hill: int
var hill_amount: int
var hill_agents: Array = []
#river agents
var river: int
var river_agents: Array = []
#auxiliars
var dynamic_filled_list: Array = []

func _init(limit_a: int, coast_t: int, smooth_t: int, smooth_amount: int, smooth_refresh: int, beach_t: int, beach_a: int, mountain_t: int, mountain_a: int, mountain_r: int, hill_t: int, hill_a: int, river_t: int):
	self.coast_limit = limit_a
	self.coast = coast_t
	
	self.smooth = smooth_t
	self.smooth_amount = smooth_amount
	self.smooth_refresh = smooth_refresh
	
	self.beach = beach_t
	self.beach_amount = beach_a
	
	self.mountain = mountain_t
	self.mountain_amount = mountain_a
	self.mountain_refresh = mountain_r
	
	self.hill = hill_t
	self.hill_amount = hill_a
	
	self.river = river_t
	
func start_coast_agents(sea_level: float, heightImage: Image, biomeImage: Image, random_gen: RandomNumberGenerator):
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
		child.run(self.dynamic_filled_list, sea_level, heightImage, biomeImage, random_gen)
		print("running ", i, " coast agent: ", child._to_string())

func run_coast_agents(sea_level: float, heightImage: Image, biomeImage: Image, random_gen: RandomNumberGenerator):
	for i in self.coast_agents.size():
		self.coast_agents[i].run(self.dynamic_filled_list, sea_level, heightImage, biomeImage, random_gen)

func start_smooth_agents(sea_level: float, heightImage: Image, biomeImage: Image, random_gen: RandomNumberGenerator):
	print("smooth agents amount: ", self.smooth_amount, " with ", self.smooth, " tokens each")
	for i in self.smooth_amount:
		var smoother = SmoothAgent.new(self.smooth, self.smooth_refresh, self.dynamic_filled_list, sea_level, heightImage, random_gen)
		self.smooth_agents.append(smoother)
		smoother.run(self.dynamic_filled_list, sea_level, heightImage, biomeImage, random_gen)
		print("running ", i, " smooth agent: ", smoother._to_string())

func run_smooth_agents(sea_level: float, heightImage: Image, biomeImage: Image, random_gen: RandomNumberGenerator):
	for i in self.smooth_agents.size():
		self.smooth_agents[i].run(self.dynamic_filled_list, sea_level, heightImage, biomeImage, random_gen)

func start_mountain_agents(width: int, max_mountain_h: float, min_mountain_h: float, mountain_s: float, mountain_v: float, sea_level: float, heightImage: Image, biomeImage: Image, random_gen: RandomNumberGenerator):
	print("mountain agents amount: ", self.mountain_amount, " with ", self.mountain, " tokens each")
	for i in self.mountain_amount:
		var riser = MountainAgent.new(self.mountain, self.mountain_refresh, max_mountain_h, min_mountain_h, mountain_s, width, mountain_v, self.dynamic_filled_list, sea_level, heightImage, random_gen)
		self.mountain_agents.append(riser)
		riser.run(self.dynamic_filled_list, sea_level, heightImage, biomeImage, random_gen)
		print("running ", i, " mountain agent")
		
func start_hill_agents(width: int, max_mountain_h: float, min_mountain_h: float, mountain_s: float, mountain_v: float, sea_level: float, heightImage: Image, biomeImage: Image, random_gen: RandomNumberGenerator):
	print("hill agents amount: ", self.hill_amount, " with ", self.hill, " tokens each")
	for i in self.hill_amount:
		var riser = HillAgent.new(self.hill, max_mountain_h, min_mountain_h, mountain_s, width, mountain_v, self.dynamic_filled_list, sea_level, heightImage, random_gen)
		self.hill_agents.append(riser)
		riser.run(self.dynamic_filled_list, sea_level, heightImage, biomeImage, random_gen)
		print("running ", i, " hill agent")
		
func start_beach_agents(width: int, max_beach_h: float, min_beach_h: float, beach_l: float, sea_level: float, heightImage: Image, biomeImage: Image, random_gen: RandomNumberGenerator):
	print("beach agents amount: ", self.beach_amount, " with ", self.beach, " tokens each")
	for i in self.beach_amount:
		var flatter = BeachAgent.new(self.beach, beach_l, max_beach_h, min_beach_h, width, self.dynamic_filled_list, sea_level, heightImage, random_gen)
		self.beach_agents.append(flatter)
		flatter.run(self.dynamic_filled_list, sea_level, heightImage, biomeImage, random_gen)
		print("running ", i, " beach agent")
