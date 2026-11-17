extends 'res://objects/items/custom/seed_logic/custom_seed_base.gd'

## poopcity: the whole screen goes "greyscale", but brown

const SHADER_CODE := """
shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform vec3 dark_brown : source_color = vec3(0.10, 0.05, 0.01);
uniform vec3 light_brown : source_color = vec3(0.86, 0.64, 0.40);

void fragment() {
	vec3 c = texture(screen_tex, SCREEN_UV).rgb;
	float l = dot(c, vec3(0.299, 0.587, 0.114));
	COLOR = vec4(mix(dark_brown, light_brown, l), 1.0);
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
