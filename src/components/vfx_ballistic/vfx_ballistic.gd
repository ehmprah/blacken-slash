extends Node2D

# refactor a la: https://docs.godotengine.org/en/stable/tutorials/math/beziers_and_curves.html#quadratic-bezier

signal animation_finished

var colors = []
var target

onready var tween = $Tween
onready var follow = $Path/Follow
onready var sprite = $Path/Follow/Sprite
onready var trail = $Path/Follow/Sprite/TrailParticles
onready var hit = $Path/Follow/Sprite/HitParticles

func _ready():
	calculate_trajectory(position, position + target)


func animate_fire():
	SFX.play(SFX.sounds.BALLISTIC_FIRE)
	tween.interpolate_property(sprite, "modulate", colors[0], colors[1], 0.4)
	tween.interpolate_property(follow, "unit_offset", 0.0, 1.0, 0.5, Tween.TRANS_LINEAR, Tween.EASE_OUT_IN)
	tween.start()
	yield(tween, "tween_all_completed")


func animate():
	SFX.play(SFX.sounds.BALLISTIC_HIT)
	trail.emitting = false
	hit.emitting = true
	yield(get_tree().create_timer(0.5), "timeout")
	emit_signal("animation_finished")
	queue_free()


func calculate_trajectory(start, end):
	var num_of_points = 30.0
	var gravity = -9.8
	# Handle vertical trajectories
	if end.x == start.x:
		$Path.curve = Curve2D.new()
		$Path.curve.add_point(Vector2.ZERO)
		$Path.curve.add_point(end - start)
		return
	
	var DOT = Vector2(1,0).dot((end - start).normalized())
	var angle = deg2rad(90 - 45 * DOT)
	
	var x_dis = end.x - start.x
	var y_dis = -1.0 * (end.y - start.y)
	
	var speed = sqrt(
		((0.5 * gravity * x_dis * x_dis) / pow(cos(angle), 2)) / 
		(y_dis - (tan(angle) * x_dis))
	)

	var x_component = cos(angle) * speed
	var y_component = sin(angle) * speed

	var total_time = x_dis / x_component
	$Path.curve = Curve2D.new()
	
	for point in num_of_points:
		var time = total_time * (point / num_of_points)
		var dx = time * x_component
		var dy = -1.0 * (time * y_component + 0.5 * gravity * time * time)
		$Path.curve.add_point(Vector2(dx, dy))
