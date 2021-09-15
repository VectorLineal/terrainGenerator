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

vec2 getLinearFunctionFromPoints(vec4 points){
	float a = (points.w - points.y) / (points.z - points.x);
	float b = (points.z * points.y - points.x * points.w) / (points.z - points.x);
	return vec2(a, b);
}

float calculateLinearFunction(vec2 function, float x){
	return x * function.x + function.y;
}

vec2 getLinearInv(vec2 function){
	return vec2(1.0 / function.x, -function.y / function.x);
}
bool isInSlopes(vec4 slopeL, vec4 slopeR, float x, float y){
	return y <= calculateLinearFunction(getLinearFunctionFromPoints(slopeL), x) && y >= calculateLinearFunction(getLinearFunctionFromPoints(slopeR), x);
}

bool isDotInSquare(vec4 square, float x, float y){
	return x >= square.x && x <= square.z && y >= square.y && y <= square.w;
}

void vertex() {
	float tempRanges = 9.0;
	//float height = texture(map, VERTEX.xz / 2.0 + 0.5).x;
	float height = texture(map, UV).x;
	//if(height >= 8.0 / tempRanges){
	//	texture(biome_map, VERTEX.xz / 2.0 + 0.5).x = rand_range(VERTEX.xz, remap(0, 30.0, 0, 1.0, minTemp), remap(0, 30.0, 0, 1.0, 2.0 * minTemp / 30.0));
	//}
	
	//desertico
	vec4 desert = vec4(0, 0, 0.12, 1);
	//vec3 desertC = vec3(0.82, 0.52, 0.39);
	vec3 desertC = vec3(0.765, 0.741, 0.655);
	//yermo
	vec4 wasteland = vec4(0.12, 0, 0.24, 1);
	vec3 wastelandC = vec3(0.5, 0.25, 0);
	//nevado
	vec4 snow = vec4(0.24, 0, 1, 0.2);
	vec3 snowC = vec3(0.569, 0.6, 0.67);
	//paramo
	vec4 paramount = vec4(0.24, 0.2, 1, 0.4);
	vec3 paramountC = vec3(0.263, 0.686, 0.463);
	//pradera
	vec4 greenland = vec4(0.24, 0.4, 0.49, 0.78);
	vec3 greenlandC  = vec3(0.522, 0.624, 0.463);
	//bosque
	vec4 forest = vec4(0.49, 0.4, 0.76, 0.78);
	vec3 forestC = vec3(0.275, 0.494, 0.141);
	//bosque humedo
	vec4 forestW = vec4(0.76, 0.4, 1, 0.78);
	vec3 forestWC = vec3(0.298, 0.396, 0.322);
	//llanuras
	vec4 plains = vec4(0.24, 0.78, 0.5, 1);
	vec3 plainsC = vec3(0.73, 0.72, 0.1);
	//vec3 plainsC = vec3(1, 0, 0.13);
	//selvatico
	vec4 jungle = vec4(0.5, 0.78, 0.74, 1);
	vec3 jungleC = vec3(0.153, 0.427, 0.31);
	//selva húmeda tropical
	vec4 jungleW = vec4(0.74, 0.78, 1, 1);
	vec3 jungleWC = vec3(0.168, 0.318, 0.173);
	//vec3 jungleC = vec3(0.157, 0.45, 0.2);
	
	float temperature = texture(biome_map, UV).x;
	float wet = texture(biome_map, UV).z;
	vec3 biomeColor;
	if(isDotInSquare(desert, wet, temperature)){
		biomeColor = desertC;
	}else if(isDotInSquare(wasteland, wet, temperature)){
		biomeColor = wastelandC;
	}else if(isDotInSquare(snow, wet, temperature)){
		biomeColor = snowC;
	}else if(isDotInSquare(paramount, wet, temperature)){
		biomeColor = paramountC;
	}else if(isDotInSquare(greenland, wet, temperature)){
		biomeColor = greenlandC;
	}else if(isDotInSquare(forest, wet, temperature)){
		biomeColor = forestC;
	}else if(isDotInSquare(forestW, wet, temperature)){
		biomeColor = forestWC;
	}else if(isDotInSquare(plains, wet, temperature)){
		biomeColor = plainsC;
	}else if(isDotInSquare(jungle, wet, temperature)){
		biomeColor = jungleC;
	}else if(isDotInSquare(jungleW, wet, temperature)){
		biomeColor = jungleWC;
	}else{ // en caso que no se coinsida con un bioma anteriormente listado, se tomará como bioma yermo
		biomeColor = wastelandC;
	}
	
	height *= height_scale;
	VERTEX.y += height;
  	//COLOR.xyz = texture(biome_map, UV).xxx;
	COLOR.xyz = vec3(height) * biomeColor;
	vec2 e = vec2(0.01, 0.0);
	vec3 normal = normalize(vec3(texture(map, VERTEX.xz / 2.0 - e).x - texture(map, VERTEX.xz / 2.0 + e).x, 2.0 * e.x, texture(map, VERTEX.xz / 2.0 - e.yx).x - texture(map, VERTEX.xz / 2.0 + e.yx).x));
	NORMAL = normal;
}

void fragment(){
  ALBEDO = COLOR.xyz;
}