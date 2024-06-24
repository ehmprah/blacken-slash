extends Camera2D

var target_return_rate = 0.2
var dragging = false
var reset = false

func _process(_delta):
	if reset:
		position = lerp(position, Vector2.ZERO, target_return_rate)


func _unhandled_input(event):
	if dragging && event is InputEventScreenDrag:
		position -= event.relative
		clamp_position()


func _physics_process(_delta):
	if State.get_phase() == Config.PHASE_LEVEL_PLAY:
		var velocity = Input.get_vector("ui_page_left", "ui_page_right", "ui_page_up", "ui_page_down")
		if velocity != Vector2.ZERO:
			position += velocity * 5
			clamp_position()


func clamp_position():
	if position.x < -600:
		position.x = -600
	if position.x > 600:
		position.x = 600
	if position.y < -500:
		position.y = -500
	if position.y > 500:
		position.y = 500


func start_drag():
	dragging = true
	reset = false


func end_drag():
	dragging = false


func recenter():
	reset = true
