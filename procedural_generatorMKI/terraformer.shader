shader_type spatial;
//render_mode unshaded;

uniform float minTemp = 0.0;
uniform float height_scale = 0.5;
uniform float seed = 43758.5453;
uniform float sea_level = 0.0;
uniform sampler2D map;
uniform sampler2D biome_map;
uniform vec4 color;

float rand(vec2 co){
    return fract(sin(dot(co.xy ,vec2(seed * 0.000297, seed * 0.00178))) * seed);
}

float rand_range(vec2 co, float inf, float sup){
	return (rand(co) * (sup - inf)) + inf;
}

float lerp(float a, float b, float t){
	return (1.0 - t) * a + b * t;
}

float invLerp(float a, float b, float v){
	return (v - a) / (b - a);
}

float remap(float iMin, float iMax, float oMin, float oMax, float v){
	float t = invLerp(iMin, iMax, v);
	return lerp(oMin, oMax, t);
}

void vertex() {
	float tempRanges = 9.0;
	float height = texture(map, VERTEX.xz / 2.0 + 0.5).x;
	//if(height >= 8.0 / tempRanges){
	//	texture(biome_map, VERTEX.xz / 2.0 + 0.5).x = rand_range(VERTEX.xz, remap(0, 30.0, 0, 1.0, minTemp), remap(0, 30.0, 0, 1.0, 2.0 * minTemp / 30.0));
	//}
	height *= height_scale;
	VERTEX.y += height * 0.5;
  	COLOR.xyz = vec3(height) * texture(biome_map, VERTEX.xz / 2.0 + 0.5).xyz;
	vec2 e = vec2(0.01, 0.0);
	vec3 normal = normalize(vec3(texture(map, VERTEX.xz / 2.0 - e).x - texture(map, VERTEX.xz / 2.0 + e).x, 2.0 * e.x, texture(map, VERTEX.xz / 2.0 - e.yx).x - texture(map, VERTEX.xz / 2.0 + e.yx).x));
	NORMAL = normal;
}

void fragment(){
  ALBEDO = COLOR.xyz;
}