shader_type spatial;
//render_mode unshaded;
uniform float seed = 4791.9511;
uniform vec2 texture_size = vec2(512, 512);

uniform float minTemp = 0.0;
uniform float height_scale = 0.5;
uniform float sea_level = 0.0;
uniform sampler2D map;
uniform sampler2D biome_map;

varying vec3 textureShaperV1;
varying vec3 textureShaperV2;
varying vec3 textureShaperV3;
varying float slope;

float hash(vec2 p) {
  return fract(sin(dot(p * 17.17, vec2(14.91, 67.31))) * seed);
}

float noise(vec2 x) {
  vec2 p = floor(x);
  vec2 f = fract(x);
  f = f * f * (3.0 - 2.0 * f);
  vec2 a = vec2(1.0, 0.0);
  return mix(mix(hash(p + a.yy), hash(p + a.xy), f.x),
         mix(hash(p + a.yx), hash(p + a.xx), f.x), f.y);
}

float fbm(vec2 x, float amp, float freq) {
  float height = 0.0;
  float curAmp = amp;
  float curFreq = freq;
  for (int i = 0; i < 6; i++){
    height += noise(x * curFreq) * curAmp;
    curAmp *= 0.5;
    curFreq *= 2.0;
  }
  return height;
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
	float height = texture(map, UV).x;
	
	height *= height_scale;
	VERTEX.y += height;
  	//COLOR.xyz = texture(map, UV).xxx;
	vec2 e = vec2(0.01, 0);
	vec3 normal = normalize(vec3(texture(map, UV - e).x - texture(map, UV + e).x, 2.0 * e.x, texture(map, UV - e.yx).x - texture(map, UV + e.yx).x));
	NORMAL = normal;
	slope = texture(biome_map, UV).y;
	textureShaperV1 = vec3((fbm(VERTEX.xz * 4.0, 1.2, 200.0) + sin((VERTEX.z - VERTEX.x) * 160.0) + sin((VERTEX.z + VERTEX.x) * 240.0) / 3.0));
	textureShaperV2 = vec3((fbm(VERTEX.xz * 0.15, 1.0, 2000.0) + sin((VERTEX.z - VERTEX.x) * 1200.0 * cos(VERTEX.x * 320.0) * sin(VERTEX.z * 640.0)) + sin((VERTEX.z + VERTEX.x) * 500.0 * cos(VERTEX.x * 640.0) * sin(VERTEX.z * 320.0))) / 3.0);
	textureShaperV3 = vec3((fbm(VERTEX.xz * 1.0, 2.0, 2200.0) + sin((VERTEX.z - VERTEX.x) * 3200.0) + sin((VERTEX.z + VERTEX.x) * 1600.0)  + cos(VERTEX.x * 50.0) * sin(VERTEX.z * 80.0)) / 4.0);
}

void fragment(){
	//desert amp:1, freq:1000, x:60, y:60, turbP:60, turbSize:2, conf:1
	//snow amp:1, freq:800, clip: 0.2, conf:g2
	//grass amp 0.8, freq 1280, clip: 0.2 conf: g1
	//desert amp:1, freq:800, x:30, y:30, turbP:700, turbSize:2, conf:1
	float amplitude = 1.0;
	float frequency = 1000.0;
	float xPeriod = 50.0;
	float yPeriod = 50.0;
	float turbPower = 60.0;
	float turbSize = 8.0;
	
	//desertico
	vec4 desert = vec4(0, 0, 0.12, 1);
	//vec3(0.82, 0.52, 0.39); vec3(0.784, 0.598, 0.337);
	vec3 desertC = vec3(0.97, 0.678, 0.204);
	//yermo
	vec4 wasteland = vec4(0.12, 0, 0.24, 1);
	vec3 wastelandC = vec3(0.4, 0.19, 0.04);
	//nevado
	vec4 snow = vec4(0.24, 0, 1, 0.2);
	vec3 snowC = vec3(0.569, 0.6, 0.67);
	//paramo
	vec4 paramount = vec4(0.24, 0.2, 1, 0.4);
	vec3 paramountC = vec3(0.263, 0.686, 0.463);
	//pradera
	vec4 greenland = vec4(0.24, 0.4, 0.49, 0.78);
	vec3 greenlandC  = vec3(0.227, 0.387, 0.04);
	//bosque
	vec4 forest = vec4(0.49, 0.4, 0.76, 0.78);
	vec3 forestC = vec3(0.26, 0.5, 0.07);
	//bosque humedo
	vec4 forestW = vec4(0.76, 0.4, 1, 0.78);
	vec3 forestWC = vec3(0.298, 0.396, 0.322);
	//llanuras
	vec4 plains = vec4(0.24, 0.78, 0.5, 1);
	vec3 plainsC = vec3(0.73, 0.72, 0.1);
	//vec3 plainsC = vec3(1, 0, 0.13);
	//selvatico
	vec4 jungle = vec4(0.5, 0.78, 0.74, 1);
	vec3 jungleC = vec3(0.02, 0.4, 0.03);
	//selva húmeda tropical
	vec4 jungleW = vec4(0.74, 0.78, 1, 1);
	vec3 jungleWC = vec3(0.168, 0.318, 0.173);
	//vec3 jungleC = vec3(0.157, 0.45, 0.2);
	
	//variables configuración normal
	float xyValue = UV.x * xPeriod / texture_size.x + UV.y * yPeriod / texture_size.y + turbPower * fbm(UV * turbSize, amplitude, frequency) / 256.0;
    float sineValue = abs(sin(xyValue * 3.14159));
	//ALBEDO = wastelandC * sineValue;
	//variable configuración G
	float clip = 0.2;
	float grassMultiplier = ((hash(UV) * fbm(UV, 0.75, 1920.0)) + clip);
	//ALBEDO = sineValue * wastelandC;
	//grass
	/*if(grassMultiplier > 1.0) grassMultiplier = 1.0;
	ALBEDO = grassMultiplier * greenlandC;*/
	//snow
	/*grassMultiplier = ((hash(UV) + fbm(UV, 1.0, 800.0)) / 2.0) + clip;
	if(grassMultiplier > 1.0) grassMultiplier = 1.0;
	ALBEDO = grassMultiplier * snowC;*/
	//ALBEDO = textureShaperV2;
	//ALBEDO = vec3(grassMultiplier);
	
	float temperature = texture(biome_map, UV).x;
	float wet = texture(biome_map, UV).z;
	vec3 biomeColor;
	if(isDotInSquare(desert, wet, temperature)){
		amplitude = 1.0;
		frequency = 1000.0;
		xPeriod = 60.0;
		yPeriod = 60.0;
		turbPower = 60.0;
		turbSize = 2.0;
		xyValue = UV.x * xPeriod / texture_size.x + UV.y * yPeriod / texture_size.y + turbPower * fbm(UV * turbSize, amplitude, frequency) / 256.0;
    	sineValue = abs(sin(xyValue * 3.14159));
		biomeColor = desertC * sineValue;
	}else if(isDotInSquare(wasteland, wet, temperature)){
		biomeColor = wastelandC * grassMultiplier;
	}else if(isDotInSquare(snow, wet, temperature)){
		grassMultiplier = ((hash(UV) + fbm(UV, 1.0, 800.0)) / 2.0) + clip;
		if(grassMultiplier > 1.0) grassMultiplier = 1.0;
		biomeColor = grassMultiplier * snowC;
	}else if(isDotInSquare(paramount, wet, temperature)){
		grassMultiplier = ((hash(UV) + fbm(UV, 1.0, 800.0)) / 2.0) + clip;
		if(grassMultiplier > 1.0) grassMultiplier = 1.0;
		biomeColor = grassMultiplier * snowC;
	}else if(isDotInSquare(greenland, wet, temperature)){
		grassMultiplier = ((hash(UV) * fbm(UV, 0.75, 1280.0)) + clip);
		if(grassMultiplier > 1.0) grassMultiplier = 1.0;
		biomeColor = grassMultiplier * greenlandC;
	}else if(isDotInSquare(forest, wet, temperature)){
		float filter = step(textureShaperV2.x, 0.3);
		grassMultiplier = ((hash(UV) * fbm(UV, 0.75, 1280.0)) + clip);
		if(grassMultiplier > 1.0) grassMultiplier = 1.0;
		vec3 mainColor = grassMultiplier * forestC;
		vec3 secColor = grassMultiplier * wastelandC;
		biomeColor = (1.0 - filter) * mainColor + filter * secColor;
	}else if(isDotInSquare(forestW, wet, temperature)){
		float filter = step(textureShaperV2.x, 0.3);
		grassMultiplier = ((hash(UV) * fbm(UV, 0.75, 1280.0)) + clip);
		if(grassMultiplier > 1.0) grassMultiplier = 1.0;
		vec3 mainColor = grassMultiplier * forestC;
		vec3 secColor = grassMultiplier * greenlandC;
		biomeColor = (1.0 - filter) * mainColor + filter * secColor;
	}else if(isDotInSquare(plains, wet, temperature)){
		float filter = step(textureShaperV2.x, 0.3);
		grassMultiplier = ((hash(UV) * fbm(UV, 0.75, 1280.0)) + clip);
		if(grassMultiplier > 1.0) grassMultiplier = 1.0;
		vec3 mainColor = grassMultiplier * greenlandC;
		vec3 secColor = grassMultiplier * wastelandC;
		biomeColor = (1.0 - filter) * mainColor + filter * secColor;
	}else if(isDotInSquare(jungle, wet, temperature)){
		float filter = step(textureShaperV2.x, 0.3);
		grassMultiplier = ((hash(UV) * fbm(UV, 0.75, 1024.0)) + clip);
		if(grassMultiplier > 1.0) grassMultiplier = 1.0;
		vec3 mainColor = grassMultiplier * jungleC;
		vec3 secColor = grassMultiplier * wastelandC;
		biomeColor = (1.0 - filter) * mainColor + filter * secColor;
	}else if(isDotInSquare(jungleW, wet, temperature)){
		float filter = step(textureShaperV2.x, 0.2);
		grassMultiplier = ((hash(UV) * fbm(UV, 0.75, 1024.0)) + clip);
		if(grassMultiplier > 1.0) grassMultiplier = 1.0;
		vec3 mainColor = grassMultiplier * jungleC;
		grassMultiplier = ((hash(UV) * fbm(UV, 0.75, 1792.0)) + clip);
		if(grassMultiplier > 1.0) grassMultiplier = 1.0;
		vec3 secColor = grassMultiplier * greenlandC;
		biomeColor = (1.0 - filter) * mainColor + filter * secColor;
	}else{ // en caso que no se coinsida con un bioma anteriormente listado, se tomará como bioma yermo
		biomeColor = grassMultiplier * wastelandC;
	}
	//biomeColor = textureShaperV2;
	ALBEDO = biomeColor;
	//ALBEDO = COLOR.xyz;
	//ALBEDO = vec3(0.0, 0.0, texture(biome_map, UV).z);
}