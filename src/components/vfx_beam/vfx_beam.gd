extends Node2D

signal animation_finished

const HitParticles = preload("res://components/vfx_beam/hit_particles.tscn")

var colors = []
var target
var is_child = false

onready var line = $Line
onready var tween = $Tween
onready var particles = $Particles
onready var particles_casting = $Particles/CastingParticles
onready var particles_beam = $Particles/BeamParticles

func _ready():
	visible = false
	line.points[1] = target
	particles_casting.rotation = atan2(target.y, target.x)
	particles_beam.rotation = atan2(target.y, target.x)
	particles_beam.position = target * 0.5
	particles_beam.process_material.emission_box_extents.x = target.length() * 0.5


func add_hit(vector):
	var hit = HitParticles.instance()
	hit.position = vector
	particles.add_child(hit)


func animate():
	visible = true
	if !is_child:
		SFX.play(SFX.sounds.BEAM)
	for particle in particles.get_children():
		particle.emitting = true
	if is_child:
		particles_casting.emitting = false
	tween.interpolate_property(line, "width", 0, 5.0, 0.4)
	tween.interpolate_property(self, "modulate", colors[0], colors[1], 0.4)
	tween.start()
	yield(tween, "tween_all_completed")
	for particle in particles.get_children():
		particle.emitting = false
	tween.stop_all()
	tween.interpolate_property(line, "width", line.width, 0, 0.2)
	tween.start()
	yield(tween, "tween_all_completed")
	emit_signal("animation_finished")
	queue_free()
