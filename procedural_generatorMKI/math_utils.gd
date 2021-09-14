class_name MathUtils

static func remap(iMin, iMax, oMin, oMax, v):
	var t = inverse_lerp(iMin, iMax, v)
	return lerp(oMin, oMax, t)

static func code_vec2(v: Vector2):
	var t = Vector2((v.x + 1) / 2.0, (v.y + 1) / 2.0)
	return t
	
static func decode_vec2(t: Vector2):
	var v = Vector2(2 * t.x - 1, 2 * t.y - 1)
	return v

static func sqr_dst(in_x, in_y, fin_x, fin_y):
	return pow(fin_x - in_x, 2) + pow(fin_y - in_y, 2)

static func angle_to_grid(v: Vector2):
	var ang = v.angle()
	if ang >= -PI / 8 and ang < PI / 8:
		return [1, 0]
	elif ang >= PI / 8 and ang < 3 * PI / 8:
		return [1, 1]
	elif ang >= -3 * PI / 8 and ang < -PI / 8:
		return [1, -1]
	elif ang >= -5 * PI / 8 and ang < -3 * PI / 8:
		return [0, -1]
	elif ang >= -7 * PI / 8 and ang < -5 * PI / 8:
		return [-1, -1]
	elif ang >= 3 * PI / 8 and ang < 5 * PI / 8:
		return [0, 1]
	elif ang >= 5 * PI / 8 and ang < 7 * PI / 8:
		return [-1, 1]
	else:
		return [-1, 0]

static func generate_vectorial_fractal_field(width: int, height: int, rng: RandomNumberGenerator):
	#En el peor de los casos, genera un valor máximo de 3 la suma de sus componentes
	var field = []
	for i in height:
		var row = []
		for j in width:
			var a = i == 0
			var b = j == 0
			var c = i == width - 1
			var d = j == height - 1
			if((a and b) or (a and d) or (b and c) or (c and d)):
				row.append(Vector2(rng.randf_range(-1, 1), rng.randf_range(-1, 1)))
			else:
				row.append(Vector2(0, 0))
		field.append(row)
	
	var max_square_dist = sqr_dst(0, 0, width - 1, height - 1)
	for i in height:
		for j in width:
			var a = i == 0
			var b = j == 0
			var c = i == width - 1
			var d = j == height - 1
			var extremes = [Vector2(0,0), Vector2(0,height - 1), Vector2(width - 1,0), Vector2(width - 1,height - 1)]
			if(not((a and b) or (a and d) or (b and c) or (c and d))):
				var cur_x = 0
				var cur_y = 0
				for delta in extremes.size():
					var temp_x = extremes[delta].x
					var temp_y = extremes[delta].y
					var cur_dist = sqr_dst(temp_x, temp_y, j, i)
					cur_x += (field[temp_x][temp_y].x * (1 -(cur_dist / max_square_dist))) / 3.0
					cur_y += (field[temp_x][temp_y].y * (1 -(cur_dist / max_square_dist))) / 3.0
				field[j][i].x = cur_x
				field[j][i].y = cur_y
	#for i in height:
	#	for j in width:
	#		print("x: ", j, ", y: ", i, "; vec: x: ", field[j][i].x, ", y: ", field[j][i].y)
	return field
