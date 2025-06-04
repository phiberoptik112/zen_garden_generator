uniform float pixelSize;
uniform float grainIntensity;
uniform float colorVariation;
uniform vec3 sandColor;
uniform float noiseScale;
uniform float time;
uniform vec2 resolution;

varying vec4 SandTexCoord;

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

float fbm(vec2 p) {
    float value = 0.0;
    float amplitude = 0.5;
    float frequency = 1.0;
    
    for (int i = 0; i < 4; i++) {
        value += amplitude * noise(p * frequency);
        amplitude *= 0.5;
        frequency *= 2.0;
    }
    
    return value;
}

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    vec2 uv = texture_coords;
    
    // Pixelate
    vec2 pixelatedUV = floor(uv * resolution / pixelSize) * pixelSize / resolution;
    
    // Generate noise for sand grains
    vec2 noiseCoord = pixelatedUV * noiseScale;
    float grain = fbm(noiseCoord + time * 0.01);
    float microGrain = noise(noiseCoord * 8.0 + time * 0.02);
    
    // Add subtle movement to simulate wind
    vec2 windOffset = vec2(sin(time * 0.05), cos(time * 0.03)) * 0.001;
    float windNoise = noise(pixelatedUV * 16.0 + windOffset);
    
    // Combine noise layers
    float combinedNoise = grain * 0.6 + microGrain * 0.3 + windNoise * 0.1;
    
    // Generate sand color variations
    vec3 baseColor = sandColor;
    vec3 darkVariation = baseColor * 0.8;
    vec3 lightVariation = baseColor * 1.2;
    
    // Apply color variation based on noise
    vec3 finalColor = mix(darkVariation, lightVariation, combinedNoise);
    
    // Add grain intensity
    float grainFactor = 1.0 + (combinedNoise - 0.5) * grainIntensity;
    finalColor *= grainFactor;
    
    // Add random speckles for individual grains
    float speckle = hash(pixelatedUV * 100.0);
    if (speckle > 0.95) {
        finalColor = mix(finalColor, vec3(1.0), 0.3);
    } else if (speckle < 0.05) {
        finalColor = mix(finalColor, vec3(0.0), 0.2);
    }
    
    // Apply color variation parameter
    float variation = (combinedNoise - 0.5) * colorVariation;
    finalColor = mix(baseColor, finalColor, 1.0 + variation);
    
    return vec4(finalColor, 1.0);
}