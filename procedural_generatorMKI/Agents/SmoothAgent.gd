extends SoftwareAgent

class_name SmoothAgent

var seed_point: Vector2
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
		for i in self.tokens:
			if i % self.restart_rate == 0:
				self.seed_point.x = self.original_point.x
				self.seed_point.y = self.original_point.y
			var heightImage = perception["map"]
			var sea = perception["sea"]
			var rng = perception["rng"]
			heightImage.lock()
			var height = heightImage.get_pixel(self.seed_point.x, self.seed_point.y).r
			heightImage.unlock()
			var amount = 3 * height
			var counter = 3.0
			var visited_neighbours: Array = []
			
			for j in MathUtils.fullNeighbourhood.size():
				var next_x = self.seed_point.x + MathUtils.fullNeighbourhood[j].x
				var next_y = self.seed_point.y + MathUtils.fullNeighbourhood[j].y
				#El vecindario debe quedar dentro de los constraints del mapa de alturas
				if next_x >= 0 and next_x < heightImage.get_width() and next_y >= 0 and next_y < heightImage.get_height():
					heightImage.lock()
					var height_i = heightImage.get_pixel(next_x, next_y).r
					heightImage.unlock()
					amount += height_i
					counter += 1.0
					visited_neighbours.append(Vector2(next_x, next_y))
			height = amount / counter
			if height > 1:
				print("nos pasamos de altura con ", height)
			heightImage.lock()
			heightImage.set_pixel(self.seed_point.x, self.seed_point.y, Color(height, height, height, 1))
			heightImage.unlock()
			
			#para mantener el programa óptimo, si la nueva altura es menor al nivel del mar, se elimina de la lista, si era menor y se vuelve mayor, se añade
			var dynamic_list: Array = perception["list"]
			var index = MathUtils.get_element_index(self.seed_point, dynamic_list)
			if index >= 0:
				if height <= sea:
					dynamic_list.remove(index)
			else:
				if height > sea:
					dynamic_list.append(self.seed_point)
			
			var next_point = visited_neighbours[rng.randi_range(0, visited_neighbours.size() - 1)]
			#ahora el punto base es el punto ya elevado
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
