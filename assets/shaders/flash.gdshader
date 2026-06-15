shader_type canvas_item;
// 受击闪白:flash_amount=0 显示原图,=1 显示纯白(保留 alpha)。
// 由 SpriteFlash.gd 设置 shader 参数 flash_amount 做短暂闪白。

uniform float flash_amount : hint_range(0.0, 1.0) = 0.0;
uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	vec3 mixed = mix(tex.rgb, flash_color.rgb, flash_amount);
	COLOR = vec4(mixed, tex.a) * COLOR;
}
