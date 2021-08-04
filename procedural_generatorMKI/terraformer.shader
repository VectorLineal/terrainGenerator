shader_type spatial;
//render_mode unshaded;

uniform float height_scale = 0.5;
uniform sampler2D map;
uniform sampler2D biome_map;
uniform vec4 color;

void vertex() {
	float height = texture(map, VERTEX.xz / 2.0 + 0.5).x * height_scale;
	//float height = fbm(VERTEX.xz * 4.0) * height_scale;
	VERTEX.y += height * 0.5;
  	COLOR.xyz = vec3(height) * texture(biome_map, VERTEX.xz / 2.0 + 0.5).xyz;
	vec2 e = vec2(0.01, 0.0);
	vec3 normal = normalize(vec3(texture(map, VERTEX.xz / 2.0 - e).x - texture(map, VERTEX.xz / 2.0 + e).x, 2.0 * e.x, texture(map, VERTEX.xz / 2.0 - e.yx).x - texture(map, VERTEX.xz / 2.0 + e.yx).x));
	NORMAL = normal;
}

void fragment(){
  ALBEDO = COLOR.xyz;
}