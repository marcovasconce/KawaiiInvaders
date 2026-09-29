extends KinematicBody2D


var velocidad = 0.5


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	global_position.x -= velocidad


func _on_VisibilityNotifier2D_screen_exited():
	if !is_queued_for_deletion():
		queue_free()
		get_parent().remove_child(self)


