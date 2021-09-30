class_name Voronoi

static func generate_voronoi_diagram(imgSize : Vector2, num_cells: int, max_height: float, random_gen: RandomNumberGenerator):
	
	var img = Image.new()
	img.create(imgSize.x, imgSize.y, false, Image.FORMAT_RGBH)

	var points = []
	var rand_heights = []
	
	for i in range(num_cells):
		points.push_back(Vector2(int(random_gen.randf() * img.get_size().x), int(random_gen.randf() * img.get_size().y)))
		
		#var colorPossibilities = [ Color.blue, Color.red, Color.green, Color.purple, Color.yellow, Color.orange]
		rand_heights.push_back(random_gen.randf())
		
	for y in range(img.get_size().y):
		for x in range(img.get_size().x):
			var dmin = img.get_size().length()
			var dmin2 = img.get_size().length()
			var j = -1
			for i in range(num_cells):
				var d = (points[i] - Vector2(x, y)).length()
				if d < dmin:
					dmin2 = dmin
					dmin = d
					j = i
				elif d < dmin2 and d >= dmin:
					dmin2 = d
			var color_scale = MathUtils.remap(0, dmin2, max_height, 0, dmin) * rand_heights[j]
			img.lock()
			img.set_pixel(x, y, Color(color_scale, color_scale, color_scale, 1))
			img.unlock()
	return img
	
static func apply_voronoi_diagram(target : Image, num_cells: int, max_height: float, clipping: float, valley_prob: float, random_gen: RandomNumberGenerator):
	var points = []
	var rand_heights = []
	
	for i in range(num_cells):
		points.push_back(Vector2(int(random_gen.randf() * target.get_size().x), int(random_gen.randf() * target.get_size().y)))
		
		#var colorPossibilities = [ Color.blue, Color.red, Color.green, Color.purple, Color.yellow, Color.orange]
		if random_gen.randf() >= valley_prob:
			rand_heights.push_back(random_gen.randf())
		else:
			rand_heights.push_back(0)
		
	for y in range(target.get_size().y):
		for x in range(target.get_size().x):
			var dmin = target.get_size().length()
			var dmin2 = target.get_size().length()
			var j = -1
			for i in range(num_cells):
				var d = (points[i] - Vector2(x, y)).length()
				if d < dmin:
					dmin2 = dmin
					dmin = d
					j = i
				elif d < dmin2 and d >= dmin:
					dmin2 = d
			var color_scale = (MathUtils.remap(0, dmin2, max_height, 0, dmin) * rand_heights[j]) - clipping
			if color_scale < 0:
				color_scale = 0
			target.lock()
			color_scale += target.get_pixel(x, y).r
			target.set_pixel(x, y, Color(color_scale / 2, color_scale / 2, color_scale / 2, 1))
			target.unlock()
