class_name Agent

const ACTIVE = 1
const ABORT = 0
const DEAD = -1

var status: int
var tokens: int
var limit: int

func _init(tokens: int, limit: int):
	self.status = self.ACTIVE
	self.tokens = tokens
	self.limit = limit

func initialize():
	pass

func run(sea_level: float, heightImage: Image, random_gen: RandomNumberGenerator):
	if self.status != DEAD:
		self.status = ACTIVE
		var percept = { #percepción del agente sobre su entorno
			"map": heightImage, 
			"size": heightImage.get_size(), 
			"rng": random_gen,
			"sea": sea_level
		}
		
		if percept == null:
			self.status = ABORT
		#si todo está en orden, se ejecuta la acción
		if self.status != ABORT:
			act(percept)

func act(perception): #esta función será sobreescrita por cada agente que hereda
	pass

func die():
	self.status = DEAD

func pause():
	self.status = ABORT

func live():
	self.status = ACTIVE
