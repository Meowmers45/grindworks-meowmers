extends 'res://objects/items/custom/seed_logic/custom_seed_base.gd'

## poopcity: every colour on screen becomes a shade of brown

const SHADER_CODE := """
shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
// Range of brown hues (reddish brown -> yellowish brown)
uniform vec2 brown_hues = vec2(0.02, 0.12);

vec3 rgb2hsv(vec3 c) {
	vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
	vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
	float d = q.x - min(q.w, q.y);
	float e = 1.0e-10;
	return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb(vec3 c) {
	vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
	vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
	return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void fragment() {
	vec3 c = texture(screen_tex, SCREEN_UV).rgb;
	vec3 hsv = rgb2hsv(c);
	float l = dot(c, vec3(0.299, 0.587, 0.114));
	// Every hue gets its own brown, saturated colours stay rich, greys stay muted
	float h = mix(brown_hues.x, brown_hues.y, hsv.x);
	float s = mix(0.4, 0.85, hsv.y);
	float v = clamp(mix(l, hsv.z, 0.4) * 0.92, 0.0, 1.0);
	COLOR = vec4(hsv2rgb(vec3(h, s, v)), 1.0);
}
"""

var layer: CanvasLayer


func setup() -> void:
	layer = CanvasLayer.new()
	layer.layer = 128
	var rect := ColorRect.new()
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	var shader := Shader.new()
	shader.code = SHADER_CODE
	var mat := ShaderMaterial.new()
	mat.shader = shader
	rect.material = mat
	layer.add_child(rect)
	add_child(layer)
