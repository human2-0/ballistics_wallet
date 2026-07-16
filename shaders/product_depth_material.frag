#include <flutter/runtime_effect.glsl>

uniform vec2 uViewportSize;
uniform vec2 uTextureSize;
uniform vec2 uTilt;
uniform float uDepthStrength;
uniform float uFitMode;
uniform sampler2D uTexture;

out vec4 fragColor;

vec2 fittedUv(vec2 canvasUv, out float inside) {
  float viewportAspect = uViewportSize.x / max(uViewportSize.y, 1.0);
  float textureAspect = uTextureSize.x / max(uTextureSize.y, 1.0);
  vec2 displayedSize = vec2(1.0);

  if (uFitMode < 0.5) {
    if (textureAspect > viewportAspect) {
      displayedSize.y = viewportAspect / textureAspect;
    } else {
      displayedSize.x = textureAspect / viewportAspect;
    }
  } else {
    if (textureAspect > viewportAspect) {
      displayedSize.x = textureAspect / viewportAspect;
    } else {
      displayedSize.y = viewportAspect / textureAspect;
    }
  }

  vec2 uv = (canvasUv - 0.5) / displayedSize + 0.5;
  inside = step(0.0, uv.x) * step(uv.x, 1.0) *
      step(0.0, uv.y) * step(uv.y, 1.0);
  return uv;
}

float heightAt(vec2 uv) {
  if (uv.x <= 0.0 || uv.x >= 1.0 || uv.y <= 0.0 || uv.y >= 1.0) {
    return 0.0;
  }

  vec4 sampleColor = texture(uTexture, uv);
  // Product cutouts can contain wide, dark export halos. Erode that fringe
  // before it participates in the height field, then restore a narrow AA edge.
  float alpha = smoothstep(0.30, 0.62, sampleColor.a);
  if (alpha < 0.002) {
    return 0.0;
  }

  float luminance = dot(sampleColor.rgb, vec3(0.2126, 0.7152, 0.0722));
  vec2 centered = (uv - 0.5) * vec2(1.45, 1.25);
  float broadVolume = sqrt(max(0.0, 1.0 - dot(centered, centered)));
  float surface = 0.14 + 0.68 * broadVolume + 0.18 * luminance;
  return alpha * clamp(surface, 0.0, 1.0);
}

float silhouetteAt(vec2 uv) {
  if (uv.x <= 0.0 || uv.x >= 1.0 || uv.y <= 0.0 || uv.y >= 1.0) {
    return 0.0;
  }

  vec2 radius = vec2(3.25) / uTextureSize;
  float alpha = texture(uTexture, uv).a;
  alpha = min(alpha, texture(uTexture, uv + vec2(radius.x, 0.0)).a);
  alpha = min(alpha, texture(uTexture, uv - vec2(radius.x, 0.0)).a);
  alpha = min(alpha, texture(uTexture, uv + vec2(0.0, radius.y)).a);
  alpha = min(alpha, texture(uTexture, uv - vec2(0.0, radius.y)).a);
  alpha = min(alpha, texture(uTexture, uv + radius * 0.72).a);
  alpha = min(alpha, texture(uTexture, uv - radius * 0.72).a);
  alpha = min(alpha, texture(uTexture, uv + vec2(radius.x, -radius.y) * 0.72).a);
  alpha = min(alpha, texture(uTexture, uv + vec2(-radius.x, radius.y) * 0.72).a);
  return smoothstep(0.20, 0.68, alpha);
}

vec2 parallaxUv(vec2 baseUv) {
  const float layerCount = 20.0;
  const float layerStep = 1.0 / layerCount;
  vec2 ray = vec2(uTilt.y, -uTilt.x) * 0.072 * uDepthStrength;
  vec2 deltaUv = ray / layerCount;
  vec2 uv = baseUv + ray * 0.5;
  float travelled = 0.0;

  for (int layer = 0; layer < 20; layer++) {
    float surfaceHeight = heightAt(uv);
    if (travelled >= surfaceHeight) {
      break;
    }
    uv -= deltaUv;
    travelled += layerStep;
  }
  return uv;
}

void main() {
  vec2 canvasUv = FlutterFragCoord().xy / uViewportSize;
#ifdef IMPELLER_TARGET_OPENGLES
  canvasUv.y = 1.0 - canvasUv.y;
#endif

  float inside = 0.0;
  vec2 baseUv = fittedUv(canvasUv, inside);

  vec2 uv = parallaxUv(baseUv);
  vec4 base = texture(uTexture, clamp(uv, vec2(0.001), vec2(0.999)));
  vec4 undisplaced = texture(uTexture, clamp(baseUv, vec2(0.001), vec2(0.999)));
  float baseMask = silhouetteAt(uv);
  float undisplacedMask = silhouetteAt(baseUv);
  if (baseMask < 0.02 && undisplacedMask >= 0.02) {
    uv = baseUv;
    base = undisplaced;
    baseMask = undisplacedMask;
  }
  if (baseMask < 0.002) {
    fragColor = vec4(0.0);
    return;
  }
  float sourceAlpha = base.a;
  float cleanAlpha = baseMask;
  base.rgb *= cleanAlpha / max(sourceAlpha, 0.001);
  base.a = cleanAlpha;

  vec2 normalStep = vec2(2.2) / uTextureSize;
  float leftHeight = heightAt(uv - vec2(normalStep.x, 0.0));
  float rightHeight = heightAt(uv + vec2(normalStep.x, 0.0));
  float topHeight = heightAt(uv - vec2(0.0, normalStep.y));
  float bottomHeight = heightAt(uv + vec2(0.0, normalStep.y));
  vec3 normal = normalize(vec3(
    (leftHeight - rightHeight) * 8.5,
    (topHeight - bottomHeight) * 8.5,
    0.72
  ));

  vec3 lightDirection = normalize(vec3(
    -0.48 + uTilt.y * 0.72,
    -0.62 - uTilt.x * 0.72,
    1.0
  ));
  vec3 viewDirection = normalize(vec3(
    uTilt.y * 0.52,
    -uTilt.x * 0.52,
    1.0
  ));
  vec3 halfDirection = normalize(lightDirection + viewDirection);

  float diffuse = 0.74 + 0.34 * max(dot(normal, lightDirection), 0.0);
  float specular = pow(max(dot(normal, halfDirection), 0.0), 38.0) * 0.30;
  float rim = pow(1.0 - max(dot(normal, viewDirection), 0.0), 2.4) * 0.18;
  float ambientOcclusion = 0.80 + 0.20 * heightAt(uv);

  vec3 litColor = base.rgb * diffuse * ambientOcclusion;
  litColor += vec3(specular + rim) * base.a;
  float sideWall = (1.0 - undisplacedMask) * smoothstep(0.20, 0.82, base.a);
  vec3 sideColor = vec3(0.18, 0.065, 0.022) * base.a;
  litColor = mix(litColor, sideColor, sideWall * 0.84);
  float edgeFade = smoothstep(0.0, 0.075, canvasUv.x) *
      smoothstep(0.0, 0.075, canvasUv.y) *
      smoothstep(0.0, 0.075, 1.0 - canvasUv.x) *
      smoothstep(0.0, 0.075, 1.0 - canvasUv.y) * inside;
  fragColor = vec4(clamp(litColor, vec3(0.0), vec3(1.0)), base.a) * edgeFade;
}
