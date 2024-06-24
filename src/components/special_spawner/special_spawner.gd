extends Node2D

signal animations_all_finished

onready var game = get_parent().get_parent()

var animations_left = 1
var alive = true

func handle():
	var entities = game.get_all_at_position(position)
	var is_blocked = false
	for entity in entities:
		if entity.is_in_group('enemy') || entity.is_in_group('player'):
			is_blocked = true
	if is_blocked == false:
		var enemy = game.spawn_enemy(position)
		yield(enemy.landing_execute(), 'completed')
		yield(enemy.on_new_position(), 'completed')
	yield(get_tree(), "idle_frame")
	emit_signal("animations_all_finished")
