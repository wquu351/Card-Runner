## 纹理生成器：提供静态方法生成程序化纹理，用于精灵、粒子和UI元素
extends Node

static func create_player_texture(size: int = 64) -> ImageTexture:
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	
	var center = Vector2(size / 2.0, size / 2.0)
	var radius = size / 2.0 - 2
	
	for x in range(size):
		for y in range(size):
			var dist = Vector2(x, y).distance_to(center)
			if dist <= radius:
				var t = dist / radius
				var color = Color(0.2, 0.6, 1.0, 1.0)
				
				if t < 0.3:
					color = Color(0.4, 0.8, 1.0, 1.0)
				elif t < 0.7:
					color = Color(0.2, 0.5, 0.9, 1.0)
				else:
					color = Color(0.1, 0.3, 0.7, 1.0)
				
				var highlight = Vector2(x - size * 0.35, y - size * 0.35).length()
				if highlight < size * 0.25:
					color = color.lerp(Color(1, 1, 1, 1.0), 0.5 * (1 - highlight / (size * 0.25)))
				
				image.set_pixel(x, y, color)
			else:
				image.set_pixel(x, y, Color(0, 0, 0, 0))
	
	var texture = ImageTexture.create_from_image(image)
	return texture

static func create_energy_core_texture(size: int = 55) -> ImageTexture:
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	
	var center = Vector2(size / 2.0, size / 2.0)
	var radius = size / 2.0 - 2
	
	for x in range(size):
		for y in range(size):
			var dist = Vector2(x, y).distance_to(center)
			if dist <= radius:
				var t = dist / radius
				var color: Color
				
				if t < 0.3:
					color = Color(1.0, 0.5, 0.4, 1.0)
				elif t < 0.6:
					color = Color(1.0, 0.25, 0.15, 1.0)
				else:
					color = Color(0.8, 0.15, 0.05, 1.0)
				
				var highlight = Vector2(x - size * 0.35, y - size * 0.35).length()
				if highlight < size * 0.22:
					color = color.lerp(Color(1, 1, 0.9, 1), 0.6 * (1 - highlight / (size * 0.22)))
				
				image.set_pixel(x, y, color)
			else:
				image.set_pixel(x, y, Color(0, 0, 0, 0))
	
	var texture = ImageTexture.create_from_image(image)
	return texture

static func create_glow_texture(size: int = 80, glow_color: Color = Color(1.0, 0.3, 0.2)) -> ImageTexture:
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	
	var center = Vector2(size / 2.0, size / 2.0)
	var radius = size / 2.0
	
	for x in range(size):
		for y in range(size):
			var dist = Vector2(x, y).distance_to(center)
			if dist <= radius:
				var alpha = (1.0 - (dist / radius)) * (1.0 - (dist / radius))
				alpha *= 0.6
				var color = Color(glow_color.r, glow_color.g, glow_color.b, alpha)
				image.set_pixel(x, y, color)
			else:
				image.set_pixel(x, y, Color(0, 0, 0, 0))
	
	var texture = ImageTexture.create_from_image(image)
	return texture

static func create_explosion_ring(size: int = 120) -> ImageTexture:
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	
	var center = Vector2(size / 2.0, size / 2.0)
	var outer_radius = size / 2.0 - 1
	var inner_radius = outer_radius * 0.6
	
	for x in range(size):
		for y in range(size):
			var dist = Vector2(x, y).distance_to(center)
			if dist >= inner_radius and dist <= outer_radius:
				var t = (dist - inner_radius) / (outer_radius - inner_radius)
				var alpha = sin(t * PI) * 0.9
				var color = Color(1.0, 0.4 + t * 0.3, 0.15, alpha)
				
				var edge_glow = 1.0 - abs(t - 0.5) * 2.0
				if edge_glow > 0.7:
					color = color.lerp(Color(1, 0.9, 0.5, 1), (edge_glow - 0.7) / 0.3 * 0.5)
				
				image.set_pixel(x, y, color)
			else:
				image.set_pixel(x, y, Color(0, 0, 0, 0))
	
	var texture = ImageTexture.create_from_image(image)
	return texture

static func create_big_block_texture(width: int = 100, height: int = 60) -> ImageTexture:
	var image = Image.create(width, height, false, Image.FORMAT_RGBA8)
	
	var corner_radius = 12
	
	for x in range(width):
		for y in range(height):
			var in_corner = false
			var corner_dist = 0.0
			
			if x < corner_radius and y < corner_radius:
				corner_dist = Vector2(x, y).distance_to(Vector2(corner_radius, corner_radius))
				in_corner = true
			elif x >= width - corner_radius and y < corner_radius:
				corner_dist = Vector2(x, y).distance_to(Vector2(width - corner_radius - 1, corner_radius))
				in_corner = true
			elif x < corner_radius and y >= height - corner_radius:
				corner_dist = Vector2(x, y).distance_to(Vector2(corner_radius, height - corner_radius - 1))
				in_corner = true
			elif x >= width - corner_radius and y >= height - corner_radius:
				corner_dist = Vector2(x, y).distance_to(Vector2(width - corner_radius - 1, height - corner_radius - 1))
				in_corner = true
			
			var should_draw = false
			if in_corner:
				should_draw = corner_dist <= corner_radius
			else:
				should_draw = true
			
			if should_draw:
				var t_x = x / float(width)
				var t_y = y / float(height)
				var color: Color
				
				if t_y < 0.35:
					color = Color(0.45, 0.65, 0.95, 1.0)
				elif t_y < 0.65:
					color = Color(0.3, 0.5, 0.85, 1.0)
				else:
					color = Color(0.2, 0.4, 0.75, 1.0)
				
				var edge_highlight = min(t_x, 1.0 - t_x)
				color = color.lerp(Color(0.6, 0.75, 1.0, 1.0), edge_highlight * 0.25)
				
				image.set_pixel(x, y, color)
			else:
				image.set_pixel(x, y, Color(0, 0, 0, 0))
	
	var texture = ImageTexture.create_from_image(image)
	return texture

static func create_bomb_texture(size: int = 48) -> ImageTexture:
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center = Vector2(size / 2.0, size / 2.0)
	var radius = size / 2.0 - 2
	for x in range(size):
		for y in range(size):
			var dist = Vector2(x, y).distance_to(center)
			if dist <= radius:
				var t = dist / radius
				var color = Color(0.3, 0.3, 0.35, 1.0)
				if t < 0.4:
					color = Color(0.5, 0.5, 0.55, 1.0)
				elif t < 0.7:
					color = Color(0.35, 0.35, 0.4, 1.0)
				else:
					color = Color(0.2, 0.2, 0.25, 1.0)
				var highlight = Vector2(x - size * 0.35, y - size * 0.35).length()
				if highlight < size * 0.2:
					color = color.lerp(Color(1, 1, 1, 1), 0.4 * (1 - highlight / (size * 0.2)))
				if y < size * 0.3 and abs(x - center.x) < 3:
					color = Color(1.0, 0.6, 0.1, 1.0)
					if y < size * 0.15:
						color = Color(1.0, 0.9, 0.3, 1.0)
				image.set_pixel(x, y, color)
			else:
				image.set_pixel(x, y, Color(0, 0, 0, 0))
	var texture = ImageTexture.create_from_image(image)
	return texture

static func create_shield_texture(size: int = 80) -> ImageTexture:
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center = Vector2(size / 2.0, size / 2.0)
	var outer_radius = size / 2.0 - 1
	var inner_radius = outer_radius * 0.7
	for x in range(size):
		for y in range(size):
			var dist = Vector2(x, y).distance_to(center)
			if dist <= outer_radius and dist >= inner_radius:
				var t = (dist - inner_radius) / (outer_radius - inner_radius)
				var alpha = 0.6 * (1.0 - abs(t - 0.5) * 2.0)
				var color = Color(0.3, 0.8, 1.0, alpha)
				if t < 0.3:
					color = Color(0.5, 0.9, 1.0, alpha * 1.2)
				image.set_pixel(x, y, color)
			else:
				image.set_pixel(x, y, Color(0, 0, 0, 0))
	var texture = ImageTexture.create_from_image(image)
	return texture

static func create_fire_texture(width: int = 40, height: int = 50) -> ImageTexture:
	var image = Image.create(width, height, false, Image.FORMAT_RGBA8)
	
	var center_x = width / 2.0
	var bottom = height - 2
	var top = 4
	
	for x in range(width):
		for y in range(height):
			var t = 1.0 - (y - top) / float(bottom - top)
			t = clamp(t, 0.0, 1.0)
			
			var dist_from_center = abs(x - center_x) / (width / 2.0)
			var edge_fade = 1.0 - dist_from_center * dist_from_center
			edge_fade = clamp(edge_fade, 0.0, 1.0)
			
			var alpha = t * edge_fade
			if alpha < 0.05:
				image.set_pixel(x, y, Color(0, 0, 0, 0))
				continue
			
			var color: Color
			if t < 0.3:
				color = Color(1.0, 0.9, 0.3, 1.0)
			elif t < 0.6:
				color = Color(1.0, 0.5, 0.1, 1.0)
			else:
				color = Color(0.8, 0.15, 0.05, 1.0)
			
			var hl = Vector2(x - width * 0.4, y - height * 0.3).length()
			if hl < width * 0.15:
				color = color.lerp(Color(1, 1, 0.8, 1), 0.5 * (1 - hl / (width * 0.15)))
			
			color.a = alpha
			image.set_pixel(x, y, color)
	
	var texture = ImageTexture.create_from_image(image)
	return texture

static func create_shockwave_texture(width: int = 200, height: int = 60) -> ImageTexture:
	var image = Image.create(width, height, false, Image.FORMAT_RGBA8)
	
	var center_x = width / 2.0
	var center_y = height / 2.0
	
	for x in range(width):
		for y in range(height):
			var dist_x = abs(x - center_x) / center_x
			var dist_y = abs(y - center_y) / center_y
			
			var edge_x = 1.0 - dist_x
			edge_x = clamp(edge_x, 0.0, 1.0)
			
			var ring = 1.0 - abs(dist_y - 0.3) / 0.7
			ring = clamp(ring, 0.0, 1.0)
			
			var alpha = edge_x * ring * 0.8
			if alpha < 0.03:
				image.set_pixel(x, y, Color(0, 0, 0, 0))
				continue
			
			var color = Color(0.4, 0.7, 1.0, 1.0)
			
			if dist_y < 0.3:
				color = Color(0.6, 0.9, 1.0, 1.0)
			
			var center_glow = 1.0 - (Vector2(x, y).distance_to(Vector2(center_x, center_y)) / (width / 2.0))
			center_glow = clamp(center_glow, 0.0, 1.0)
			if center_glow > 0.7:
				color = color.lerp(Color(1, 1, 1, 1), (center_glow - 0.7) / 0.3 * 0.5)
			
			color.a = alpha
			image.set_pixel(x, y, color)
	
	var texture = ImageTexture.create_from_image(image)
	return texture

static func create_beam_texture(width: int = 40, height: int = 400) -> ImageTexture:
	var image = Image.create(width, height, false, Image.FORMAT_RGBA8)
	
	var center_x = width / 2.0
	
	for x in range(width):
		for y in range(height):
			var dist_from_center = abs(x - center_x) / center_x
			
			var edge_fade = 1.0 - dist_from_center * dist_from_center
			edge_fade = clamp(edge_fade, 0.0, 1.0)
			
			var t = y / float(height)
			var vert_fade = 1.0
			if t < 0.1:
				vert_fade = t / 0.1
			elif t > 0.9:
				vert_fade = (1.0 - t) / 0.1
			
			var alpha = edge_fade * vert_fade * 0.9
			if alpha < 0.03:
				image.set_pixel(x, y, Color(0, 0, 0, 0))
				continue
			
			var color: Color
			if dist_from_center < 0.3:
				color = Color(1.0, 0.9, 1.0, 1.0)
			elif dist_from_center < 0.6:
				color = Color(0.7, 0.3, 1.0, 1.0)
			else:
				color = Color(0.4, 0.1, 0.8, 1.0)
			
			color.a = alpha
			image.set_pixel(x, y, color)
	
	var texture = ImageTexture.create_from_image(image)
	return texture

static func create_decoy_texture(size: int = 64) -> ImageTexture:
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	
	var center = Vector2(size / 2.0, size / 2.0)
	var radius = size / 2.0 - 2
	
	for x in range(size):
		for y in range(size):
			var dist = Vector2(x, y).distance_to(center)
			if dist <= radius:
				var t = dist / radius
				var color = Color(0.4, 0.7, 1.0, 0.6)
				
				if t < 0.3:
					color = Color(0.6, 0.85, 1.0, 0.7)
				elif t < 0.7:
					color = Color(0.35, 0.6, 0.9, 0.6)
				else:
					color = Color(0.2, 0.45, 0.75, 0.5)
				
				var highlight = Vector2(x - size * 0.35, y - size * 0.35).length()
				if highlight < size * 0.25:
					color = color.lerp(Color(1, 1, 1, 0.8), 0.4 * (1 - highlight / (size * 0.25)))
				
				var stripe = sin(y * 0.5) * 0.15
				color.a = clamp(color.a + stripe, 0.3, 0.8)
				
				image.set_pixel(x, y, color)
			else:
				image.set_pixel(x, y, Color(0, 0, 0, 0))
	
	var texture = ImageTexture.create_from_image(image)
	return texture

static func create_obstacle_texture(width: int = 50, height: int = 60) -> ImageTexture:
	var image = Image.create(width, height, false, Image.FORMAT_RGBA8)
	
	var corner_radius = 8
	
	for x in range(width):
		for y in range(height):
			var in_corner = false
			var corner_dist = 0.0
			
			if x < corner_radius and y < corner_radius:
				corner_dist = Vector2(x, y).distance_to(Vector2(corner_radius, corner_radius))
				in_corner = true
			elif x >= width - corner_radius and y < corner_radius:
				corner_dist = Vector2(x, y).distance_to(Vector2(width - corner_radius - 1, corner_radius))
				in_corner = true
			elif x < corner_radius and y >= height - corner_radius:
				corner_dist = Vector2(x, y).distance_to(Vector2(corner_radius, height - corner_radius - 1))
				in_corner = true
			elif x >= width - corner_radius and y >= height - corner_radius:
				corner_dist = Vector2(x, y).distance_to(Vector2(width - corner_radius - 1, height - corner_radius - 1))
				in_corner = true
			
			var should_draw = false
			if in_corner:
				should_draw = corner_dist <= corner_radius
			else:
				should_draw = true
			
			if should_draw:
				var t = y / float(height)
				var color = Color(1.0, 0.4, 0.3, 1.0)
				
				if t < 0.3:
					color = Color(1.0, 0.5, 0.4, 1.0)
				elif t < 0.6:
					color = Color(0.9, 0.35, 0.25, 1.0)
				else:
					color = Color(0.8, 0.25, 0.2, 1.0)
				
				var highlight = 1.0 - abs(x - width / 2.0) / (width / 2.0)
				color = color.lerp(Color(1, 0.6, 0.5, 1.0), highlight * 0.3)
				
				image.set_pixel(x, y, color)
			else:
				image.set_pixel(x, y, Color(0, 0, 0, 0))
	
	var texture = ImageTexture.create_from_image(image)
	return texture

static func create_background_texture(width: int = 540, height: int = 1170) -> ImageTexture:
	var image = Image.create(width, height, false, Image.FORMAT_RGBA8)
	
	var color_top = Color(0.05, 0.05, 0.15, 1.0)
	var color_mid = Color(0.1, 0.05, 0.2, 1.0)
	var color_bottom = Color(0.15, 0.05, 0.1, 1.0)
	
	for y in range(height):
		var t = y / float(height)
		var c: Color
		if t < 0.5:
			c = color_top.lerp(color_mid, t * 2)
		else:
			c = color_mid.lerp(color_bottom, (t - 0.5) * 2)
		
		for x in range(width):
			image.set_pixel(x, y, c)
	
	var rng = RandomNumberGenerator.new()
	rng.seed = 42
	
	for i in range(100):
		var star_x = rng.randi_range(0, width - 1)
		var star_y = rng.randi_range(0, height - 1)
		var star_size = rng.randi_range(1, 3)
		var star_brightness = rng.randf_range(0.3, 1.0)
		
		for dx in range(-star_size, star_size + 1):
			for dy in range(-star_size, star_size + 1):
				var px = star_x + dx
				var py = star_y + dy
				if px >= 0 and px < width and py >= 0 and py < height:
					var dist = Vector2(dx, dy).length()
					if dist <= star_size:
						var intensity = star_brightness * (1 - dist / star_size)
						var current = image.get_pixel(px, py)
						current.r = min(1.0, current.r + intensity)
						current.g = min(1.0, current.g + intensity * 0.9)
						current.b = min(1.0, current.b + intensity * 0.7)
						image.set_pixel(px, py, current)
	
	var texture = ImageTexture.create_from_image(image)
	return texture

static func create_particle_texture(size: int = 16) -> ImageTexture:
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	
	var center = Vector2(size / 2.0, size / 2.0)
	var radius = size / 2.0
	
	for x in range(size):
		for y in range(size):
			var dist = Vector2(x, y).distance_to(center)
			if dist <= radius:
				var alpha = (1.0 - (dist / radius)) * (1.0 - (dist / radius))
				var color = Color(1, 1, 1, alpha)
				image.set_pixel(x, y, color)
			else:
				image.set_pixel(x, y, Color(0, 0, 0, 0))
	
	var texture = ImageTexture.create_from_image(image)
	return texture

static func create_dart_texture(size: int = 32) -> ImageTexture:
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	
	var center_x = size / 2.0
	var center_y = size / 2.0
	var half_len = size / 2.0 - 2
	var half_width = size / 4.0
	
	for x in range(size):
		for y in range(size):
			var rel_y = y - center_y
			var rel_x = x - center_x
			var in_triangle = false
			
			if rel_y >= -half_len and rel_y <= half_len:
				var progress = (rel_y + half_len) / (2.0 * half_len)
				var max_half_w = half_width * (1.0 - progress)
				if abs(rel_x) <= max_half_w:
					in_triangle = true
			
			if in_triangle:
				var progress = (rel_y + half_len) / (2.0 * half_len)
				var color = Color(0.2, 0.9, 0.8, 1.0)
				
				if progress < 0.3:
					color = Color(0.4, 1.0, 0.9, 1.0)
				elif progress < 0.7:
					color = Color(0.15, 0.75, 0.7, 1.0)
				else:
					color = Color(0.1, 0.5, 0.5, 1.0)
				
				var edge_dist = abs(rel_x) / max(half_width * (1.0 - progress), 0.01)
				color = color.lerp(Color(1, 1, 1, 1), (1.0 - edge_dist) * 0.3)
				
				image.set_pixel(x, y, color)
			else:
				image.set_pixel(x, y, Color(0, 0, 0, 0))
	
	var texture = ImageTexture.create_from_image(image)
	return texture

static func create_afterimage_texture(size: int = 64) -> ImageTexture:
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	
	var center = Vector2(size / 2.0, size / 2.0)
	var radius = size / 2.0 - 2
	
	for x in range(size):
		for y in range(size):
			var dist = Vector2(x, y).distance_to(center)
			if dist <= radius:
				var t = dist / radius
				var alpha = (1.0 - t) * 0.5
				var color = Color(0.3, 0.7, 1.0, alpha)
				image.set_pixel(x, y, color)
			else:
				image.set_pixel(x, y, Color(0, 0, 0, 0))
	
	var texture = ImageTexture.create_from_image(image)
	return texture

static func create_coin_texture(size: int = 32) -> ImageTexture:
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	
	var center = Vector2(size / 2.0, size / 2.0)
	var outer_radius = size / 2.0 - 1
	var inner_radius = outer_radius * 0.65
	
	for x in range(size):
		for y in range(size):
			var dist = Vector2(x, y).distance_to(center)
			if dist <= outer_radius:
				var t = dist / outer_radius
				var color: Color
				
				if dist <= inner_radius:
					color = Color(1.0, 0.85, 0.2, 1.0)
					var hl = Vector2(x - size * 0.35, y - size * 0.35).length()
					if hl < size * 0.2:
						color = color.lerp(Color(1, 1, 0.8, 1), 0.6 * (1 - hl / (size * 0.2)))
				else:
					color = Color(0.9, 0.7, 0.1, 1.0)
					if t > 0.9:
						color = Color(0.7, 0.5, 0.05, 1.0)
				
				image.set_pixel(x, y, color)
			else:
				image.set_pixel(x, y, Color(0, 0, 0, 0))
	
	var texture = ImageTexture.create_from_image(image)
	return texture
