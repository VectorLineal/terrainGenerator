extends SoftwareAgent

class_name SmoothAgent

var original_point: Vector2
var restart_rate: int

func _init(tokens: int, rate: int, list: Array, sea_level: float, heightImage: Image, random_gen: RandomNumberGenerator).(tokens):
	self.seed_point = getRandomLandPointDynamic(list, sea_level, heightImage, random_gen)
	self.original_point = Vector2(self.seed_point.x, self.seed_point.y)
	self.restart_rate = rate

func _to_string():
	return "base point: " + str(self.seed_point) + " original point: " + str(self.original_point) + " refresh rate: " + str(self.restart_rate)

func act(perception):
	if self.tokens <= 0:
		die()
	else:
		var heightImage = perception["map"]
		var sea = perception["sea"]
		var rng = perception["rng"]
		var dynamic_list: Array = perception["list"]
		for i in self.tokens:
			if i % self.restart_rate == 0:
				self.seed_point.x = self.original_point.x
				self.seed_point.y = self.original_point.y
			#se hace el proceso de aplanado y que retorna los vecinos visitados
			var visited_neighbours: Array = MathUtils.flatten(self.seed_point, sea, heightImage, dynamic_list)
			
			var next_point = visited_neighbours[rng.randi_range(0, visited_neighbours.size() - 1)]
			#ahora el punto base es un punto visitado aleatorio
			self.seed_point = next_point

#función que calcula un punto aleatorio que esté encima de un nivel del mar usando programación dinámica
func getRandomLandPointDynamic(list: Array, sea_level: float, heightImage: Image, random_gen: RandomNumberGenerator):
	var p: Vector2 = Vector2(0, 0)
	#obtenemos un punto aleatorio; en tal caso de que aún no haya ninguno, simplemente se toma un punto arbitrario
	if list.size() > 0:
		p = list[random_gen.randi_range(0, list.size() - 1)]
	else:
		p = Vector2(random_gen.randi_range(0, heightImage.get_width() - 1), random_gen.randi_range(0, heightImage.get_height() - 1))
		#print("el mapa está sin tocar")
	return p
