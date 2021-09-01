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
	//h: altura, t: tempratura, w: humedad
	//pradera
	vec3 greenland = vec3(0.3, 0.3, 0.2);
	vec3 greenlandC = vec3(0, 0.64, 0.24);
	//llanuras
	vec3 plains = vec3(0, 0.6, 0.35);
	vec3 plainsC = vec3(0.73, 0.72, 0.1);
	//vec3 plainsC = vec3(0.592, 0.93, 0.13);
	//selvatico
	vec3 jungle = vec3(0, 0.5, 0.65);
	vec3 jungleC = vec3(0.08, 0.6, 0);
	//vec3 jungleC = vec3(0.157, 0.45, 0.2);
	//desertico
	vec3 desert = vec3(0, 0.85, 0.1);
	vec3 desertC = vec3(0.82, 0.52, 0.39);
	//vec3 desertC = vec3(0.88, 0.75, 0.5);
	//nevado
	vec3 snow = vec3(0.9, 0.2, 0.4);
	vec3 snowC = vec3(1, 0.98, 0.98);
	//paramo
	vec3 paramount = vec3(0.65, 0.4, 0.55);
	vec3 paramountC = vec3(0.69, 0.5, 0.88);
	vec3 wasteland = vec3(0.5, 0.25, 0);
	
	float temperature = texture(biome_map, VERTEX.xz / 2.0 + 0.5).x;
	float wet = texture(biome_map, VERTEX.xz / 2.0 + 0.5).z;
	vec3 biomeColor;
	if(height <= greenland.x){ // puede ser llanura, selva o desierto o yermo
		if(wet <= desert.z){
			biomeColor = desertC;
		}else if(wet > desert.z && wet <= plains.z){
			biomeColor = wasteland;
		}else if(wet > plains.z && wet <= jungle.z){
			biomeColor = plainsC;
		}else{
			biomeColor = jungleC;
		}
	}else if(height > greenland.x && height <= paramount.x){ //puede ser pradera, yermo, desierto, selva
		if(wet >= jungle.z){
			biomeColor = jungleC;
		}else if(wet < jungle.z && wet >= greenland.z){
			biomeColor = greenlandC;
		}else if(wet < greenland.z && wet >= desert.z){
			biomeColor = wasteland;
		}else if(wet < desert.z){
			biomeColor = desertC;
		}
	}else if(height > paramount.x && height <= snow.x){ //puede ser paramo, pradera o yermo
		if(wet >= paramount.z){
			biomeColor = paramountC;
		}else if(wet < paramount.z && wet >= greenland.z){
			biomeColor = greenlandC;
		}else{
			biomeColor = wasteland;
		}
	}else if(height > snow.x){ //tiene que ser un nevado
		biomeColor = snowC;
	}else{ // en caso que no se coinsida con un bioma anteriormente listado, se tomará como bioma yermo
		biomeColor = wasteland;
	}
	
	height *= height_scale;
	VERTEX.y += height;
  	//COLOR.xyz = vec3(height) * texture(biome_map, VERTEX.xz / 2.0 + 0.5).xyz;
	COLOR.xyz = vec3(height) * biomeColor;
	vec2 e = vec2(0.01, 0.0);
	vec3 normal = normalize(vec3(texture(map, VERTEX.xz / 2.0 - e).x - texture(map, VERTEX.xz / 2.0 + e).x, 2.0 * e.x, texture(map, VERTEX.xz / 2.0 - e.yx).x - texture(map, VERTEX.xz / 2.0 + e.yx).x));
	NORMAL = normal;
}

void fragment(){
  ALBEDO = COLOR.xyz;
}