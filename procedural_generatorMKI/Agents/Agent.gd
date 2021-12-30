class_name SoftwareAgent

const ACTIVE = 1
const ABORT = 0
const DEAD = -1

var status: int
var tokens: int
var seed_point: Vector2

func _init(tokens: int):
	self.status = self.ACTIVE
	self.tokens = tokens

func initialize():
	pass

func run(list: Array, sea_level: float, heightImage: Image, random_gen: RandomNumberGenerator):
	if self.status != DEAD:
		live()
		var percept = { #percepción del agente sobre su entorno
			"map": heightImage, 
			"size": heightImage.get_size(), 
			"rng": random_gen,
			"sea": sea_level,
			"list": list
		}
		
		if percept == null:
			pause()
		#si todo está en orden, se ejecuta la acción
		if self.status != ABORT:
			act(percept)

func act(perception): #esta función será sobreescrita por cada agente que hereda
	if self.tokens <= 0:
		die()

func die():
	self.status = DEAD

func pause():
	self.status = ABORT

func live():
	self.status = ACTIVE
