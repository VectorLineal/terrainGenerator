shader_type spatial;
//render_mode unshaded;

uniform float height_scale = 0.5;
uniform int seed = 4791;
uniform float amplitude = 0.5;
uniform float frequency = 3.0;
uniform int iterations = 6;
uniform sampler2D map;
uniform vec4 color;

float hash(vec2 p) {
  return fract(sin(dot(p * 17.17, vec2(14.91, 67.31))) * float(seed));
}

float diamondSquare(vec2 coords){
	mat3 diamondMat;
	int cSeed = seed;
	vec2 parameter = coords;
	//initialization
	diamondMat[0][0] = hash(parameter);
	parameter *= parameter;
	diamondMat[0][2] = hash(parameter);
	parameter *= parameter;
	diamondMat[2][0] = hash(parameter);
	parameter *= parameter;
	diamondMat[2][2] = hash(parameter);
	parameter *= parameter;
	//square step
	diamondMat[1][1] = (diamondMat[0][0] + diamondMat[0][2] + diamondMat[2][0] + diamondMat[2][2]) / 4.0;
	//diamond step
	diamondMat[0][1] = (diamondMat[0][0] + diamondMat[0][2] + diamondMat[1][1]) / 3.0;
	diamondMat[1][0] = (diamondMat[0][0] + diamondMat[2][0] + diamondMat[1][1]) / 3.0;
	diamondMat[1][2] = (diamondMat[2][2] + diamondMat[0][2] + diamondMat[1][1]) / 3.0;
	diamondMat[2][1] = (diamondMat[2][0] + diamondMat[2][2] + diamondMat[1][1]) / 3.0;
	
	int picked = int(hash(parameter) * 9.0);
	if(picked == 0)
		return diamondMat[0][0];
	else if(picked == 1)
		return diamondMat[0][1];
	else if(picked == 1)
		return diamondMat[0][2];
	else if(picked == 3)
		return diamondMat[1][0];
	else if(picked == 4)
		return diamondMat[1][1];
	else if(picked == 5)
		return diamondMat[1][2];
	else if(picked == 6)
		return diamondMat[2][0];
	else if(picked == 7)
		return diamondMat[2][1];
	else
		return diamondMat[2][2];
}

float noise(vec2 x) {
  vec2 p = floor(x);
  vec2 f = fract(x);
  f = f * f * (3.0 - 2.0 * f);
  vec2 a = vec2(1.0, 0.0);
  return mix(mix(hash(p + a.yy), hash(p + a.xy), f.x),
         mix(hash(p + a.yx), hash(p + a.xx), f.x), f.y);
}

float fbm(vec2 x) {
  float height = 0.0;
  float amplitudeF = amplitude;
  float frequencyF = frequency;
  for (int i = 0; i < iterations; i++){
    height += noise(x * frequencyF) * amplitudeF;
    amplitudeF *= 0.5;
    frequencyF *= 2.0;
  }
  return height;
}

void vertex() {
	float height = texture(map, VERTEX.xz / 2.0 + 0.5).x;
	//float height = fbm(VERTEX.xz * 4.0) * height_scale;
	//float height = diamondSquare(VERTEX.xz) * height_scale;
	VERTEX.y += height * 0.5;
  	COLOR.xyz = vec3(height);
	vec2 e = vec2(0.01, 0.0);
	vec3 normal = normalize(vec3(fbm(VERTEX.xz - e) - fbm(VERTEX.xz + e), 2.0 * e.x, fbm(VERTEX.xz - e.yx) - fbm(VERTEX.xz + e.yx)));
	NORMAL = normal;
}

void fragment(){
  ALBEDO = COLOR.xyz;
}