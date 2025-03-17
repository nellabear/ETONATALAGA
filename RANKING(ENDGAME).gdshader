shader_type canvas_item;

uniform float speed  = .06;

void vertex() {
	UV.y += TIME * speed;
}