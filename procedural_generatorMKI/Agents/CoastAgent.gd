extends Agent

class_name CoastAgent

var seed_point: Vector2
var direction: Vector2
var attractor: Vector2
var repulsor: Vector2

func _init(tokens: int, limit: int, size: Vector2, random_gen: RandomNumberGenerator):
	._init(tokens, limit)
	self.seed_point = Vector2(random_gen.randi_range(0, size.x), random_gen.randi_range(0, size.y))
	self.direction = MathUtils.generate_random_normal(random_gen)
	self.attractor = Vector2(random_gen.randi_range(0, size.x), random_gen.randi_range(0, size.y))
	self.repulsor = Vector2(random_gen.randi_range(0, size.x), random_gen.randi_range(0, size.y))
	#repulsor y atractor deben quedar en direcciones diferentes
	while self.attractor.angle() == self.repulsor.angle():
		self.repulsor = Vector2(random_gen.randi_range(0, size.x), random_gen.randi_range(0, size.y))

func act(perception):
	if self.tokens >= self.limit:
		var child1 = CoastAgent.new(self.tokens / 2, self.limit, perception["size"], perception["rng"])
		var child2 = CoastAgent.new(self.tokens / 2, self.limit, perception["size"], perception["rng"])
		child1.act(perception)
		child2.act(perception)
	else:
		for i in self.tokens:
			pass
