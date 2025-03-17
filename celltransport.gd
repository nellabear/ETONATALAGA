extends CharacterBody2D

var scrolling=false
var of=Vector2(0,0)

func _physics_process(delta):
	var mouse_pos=get_global_mouse_position() - of
	if scrolling:
		$"../Control/Background/Panel/celltransport".position.y=mouse_pos.y
		
	move_and_slide()
	if Input.is_action_pressed("click"):
		scrolling=true
		of = get_global_mouse_position() - $"../Control/Background/Panel/celltransport".position
		
	else:
		scrolling=false
