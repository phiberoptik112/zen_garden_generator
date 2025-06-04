uniform vec3 rockColor;
uniform float roughness;
uniform float metallic;
uniform float specular;
uniform vec3 lightDirection;
uniform vec3 lightColor;
uniform float ambientStrength;
uniform vec2 resolution;
uniform float time;
uniform float crackIntensity;
uniform float weathering;

varying vec4 RockTexCoord;
varying vec3 VaryingNormal;
varying vec3 VaryingPosition;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    
    vec2 u = f * f * (3.0 - 2.0 * f);
    
    return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

float ridgedNoise(vec2 p) {
    return 1.0 - abs(noise(p) * 2.0 - 1.0);
}

float fbm(vec2 p) {
    float value = 0.0;
    float amplitude = 0.5;
    float frequency = 1.0;
    
    for (int i = 0; i < 5; i++) {
        value += amplitude * noise(p * frequency);
        amplitude *= 0.5;
        frequency *= 2.0;
    }
    
    return value;
}

vec3 generateNormal(vec2 uv, float scale) {
    float eps = 0.001;
    float heightL = fbm(uv - vec2(eps, 0.0) * scale);
    float heightR = fbm(uv + vec2(eps, 0.0) * scale);
    float heightD = fbm(uv - vec2(0.0, eps) * scale);
    float heightU = fbm(uv + vec2(0.0, eps) * scale);
    
    vec3 normal = normalize(vec3(heightL - heightR, heightD - heightU, 2.0));
    return normal;
}

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    vec2 uv = texture_coords;
    
    // Generate rock surface texture
    float rockTexture = fbm(uv * 8.0);
    float detailTexture = fbm(uv * 32.0) * 0.3;
    float microTexture = noise(uv * 128.0) * 0.1;
    
    // Generate cracks
    float crackNoise = ridgedNoise(uv * 16.0);
    float cracks = smoothstep(0.7, 0.9, crackNoise) * crackIntensity;
    
    // Generate surface normal for lighting
    vec3 surfaceNormal = generateNormal(uv, 4.0);
    
    // Calculate lighting
    vec3 lightDir = normalize(-lightDirection);
    float NdotL = max(dot(surfaceNormal, lightDir), 0.0);
    
    // Ambient lighting
    vec3 ambient = ambientStrength * lightColor;
    
    // Diffuse lighting
    vec3 diffuse = NdotL * lightColor;
    
    // Specular lighting (simplified Blinn-Phong)
    vec3 viewDir = vec3(0.0, 0.0, 1.0);
    vec3 halfDir = normalize(lightDir + viewDir);
    float NdotH = max(dot(surfaceNormal, halfDir), 0.0);
    float specularPower = mix(32.0, 4.0, roughness);
    vec3 spec = pow(NdotH, specularPower) * specular * lightColor;
    
    // Combine base rock color with texture
    vec3 baseColor = rockColor;
    float textureFactor = rockTexture + detailTexture + microTexture;
    vec3 texturedColor = baseColor * (0.8 + textureFactor * 0.4);
    
    // Apply weathering
    float weatheringMask = fbm(uv * 6.0 + time * 0.001);
    vec3 weatheredColor = mix(texturedColor, texturedColor * 0.6, weathering * weatheringMask);
    
    // Apply cracks
    vec3 crackColor = vec3(0.1, 0.1, 0.1);
    vec3 crackedColor = mix(weatheredColor, crackColor, cracks);
    
    // Apply lighting
    vec3 finalColor = crackedColor * (ambient + diffuse) + spec * (1.0 - roughness);
    
    // Add metallic reflection
    if (metallic > 0.0) {
        vec3 reflection = reflect(-lightDir, surfaceNormal);
        float metalMask = noise(uv * 20.0);
        finalColor = mix(finalColor, finalColor * 2.0 * metalMask, metallic * 0.3);
    }
    
    return vec4(finalColor, 1.0);
}