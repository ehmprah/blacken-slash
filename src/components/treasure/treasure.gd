extends Node2D

signal animation_finished

var alive = true
var drops
var lifetime

func enter():
	update()
	$AnimationPlayer.play("Enter")
	yield($AnimationPlayer, "animation_finished")
	SFX.play(SFX.sounds.TREASURE_DROP)


func update():
	lifetime -= 1
	if lifetime < 0:
		destroy()
	else:
		SFX.play(SFX.sounds.BUZZ)
		$Sprite/Label.text = String(lifetime)


func loot():
	SFX.play(SFX.sounds.OPEN_TREASURE)
	$AnimationPlayer.play_backwards("Enter")
	yield($AnimationPlayer, "animation_finished")
	Pathfinding.disable_tile(position, false)
	queue_free()


func destroy():
	SFX.play(SFX.sounds.TREASURE_DISAPPEAR)
	$AnimationPlayer.play_backwards("Enter")
	yield($AnimationPlayer, "animation_finished")
	Pathfinding.disable_tile(position, false)
	emit_signal('animation_finished')
	queue_free()
