extends Node2D

signal animations_all_finished

const VFX_LIGHTNING = preload("res://components/vfx_lightning/vfx_lightning.tscn")

onready var game = get_parent().get_parent()

var alive = true
var animations_left = 1

func explode(entity):
	var effect = VFX_LIGHTNING.instance()
	effect.position = Vector2(0, -500)
	effect.target = Vector2(0, 500)
	effect.colors = Util.get_projectile_colors()
	add_child(effect)
	effect.connect("animation_finished", self, "_on_animation_finished")
	effect.animate()
	entity.deal_damage(
		Vector2.ZERO, 
		RNG.roll_damage({ 'min': 0.2, 'max': 2 }, { 'critical_chance': 0 })
	)
	entity.connect("animation_finished", self, "_on_animation_finished")
	animations_left += 1
	yield(self, 'animations_all_finished')


func _on_animation_finished():
	animations_left -= 1
	if animations_left == 0:
		emit_signal('animations_all_finished')
		queue_free()
