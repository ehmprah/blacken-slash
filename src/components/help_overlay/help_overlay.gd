extends PanelContainer

const Attribute = preload("res://components/attribute_base/attribute_base.tscn")
const SkillFX = preload("res://components/skill_fx/skill_fx.tscn")
const HelpEnemy = preload("res://components/help_enemy/help_enemy.tscn")

onready var main = get_node('/root/Main')
onready var animation = $AnimationPlayer
onready var details = {
	'scroll': $Scroll,
	'type': $Scroll/Panel/Container/Info/Grid/Game/Type,
	'level': $Scroll/Panel/Container/Info/Grid/Game/Level,
	'score': $Scroll/Panel/Container/Info/Grid/Score/Value,
	'modifier': $Scroll/Panel/Container/Info/Grid/Difficulty/Modifier,
	'meta': $Scroll/Panel/Container/Meta,
	'meta_name': $Scroll/Panel/Container/Meta/Labels/Name,
	'meta_desc': $Scroll/Panel/Container/Meta/Labels/Description,
	'player': $Scroll/Panel/Container/Player/Attributes,
	'enemies': $Scroll/Panel/Container/Enemies,
}

var cached = -1
var health

func _input(event):
	if (
		event.is_action_released("ui_cancel") ||
		event.is_action_released("ui_stats")
	):
		hide()


func _unhandled_input(_event):
	# We make sure no input escapes below while this overlay is active
	accept_event()


func _gui_input(event):
	# Hide the menu if you click outside the menu container
	if event is InputEventMouseButton && event.button_index == BUTTON_LEFT && !event.is_pressed():
		hide()


func _physics_process(_delta):
	var value = Input.get_axis("ui_page_up", "ui_page_down")
	if value != 0:
		details.scroll.scroll_vertical += value * 20


func show():
	main.ui.overlays.add_child(self)
	main.game.player.camera.set_physics_process(false)
	update()
	details.scroll.scroll_vertical = 0
	animation.play("Enter")
	yield(animation, "animation_finished")


func hide():
	animation.play_backwards("Enter")
	yield(animation, "animation_finished")
	main.ui.overlays.remove_child(self)
	main.game.player.camera.set_physics_process(true)


func update():
	# We fully update this only once per level
	if cached == State.game.difficulty.current:
		update_player_health()
	else:
		update_info()
		update_player()
		update_enemies()
		cached = State.game.difficulty.current


func update_info():
	# Update game type and level
	details.type.text = 'T_NORMAL' if State.game.type == Config.GAME_NORMAL else 'T_LADDER'
	details.level.text = '%s %d' % [tr('T_LEVEL'), State.game.difficulty.current]
	# Update score
	details.score.text = String(floor(State.game.difficulty.beaten * (State.game.score_modifier + 1)))
	details.modifier.text = '+' + Util.format_percent(State.game.score_modifier)
	# Update meta bonus
	details.meta.visible = State.game.meta.type > -1
	if details.meta.visible:
		var labels = Config.meta_labels[State.game.meta.type]
		details.meta_name.text = labels.name
		details.meta_desc.text = labels.desc


func update_player():
	Util.delete_children(details.player)
	for index in State.game.skills.size():
		var fx = SkillFX.instance()
		fx.show_help_icon = false
		fx.skill = State.game.skills[index].duplicate(true)
		details.player.add_child(fx)

	# Show effective health
	health = Attribute.instance()
	health.data = { 'name': 'T_HEALTH', 'value': '', 'format': Config.FORMAT_PLAIN }
	details.player.add_child(health)
	update_player_health()
	health.show_help_icon = false
	health.labels.rect_min_size = Vector2.ZERO

	# Add regular attributes
	for key in State.game.attributes:
		if (
			key != 'action_points' && 
			!key.begins_with('flag') &&
			State.game.difficulty.record >= Config.attributes[key]._level_min
		):
			var attribute = Attribute.instance()
			attribute.data = {
				'name': Config.attributes[key].name,
				'value': State.game.attributes[key],
				'format': Config.attributes[key].format,
			}
			details.player.add_child(attribute)
			attribute.labels.rect_min_size = Vector2.ZERO


func update_player_health():
	var hp = Util.get_effective_health(State.game.attributes)
	health.data.value = "%d/%d" % [hp * (1 - State.game.damage), hp]
	health.update()


func update_enemies():
	Util.delete_children(details.enemies)
	var types = {}
	for entity in main.game.entities.get_children():
		if entity.is_in_group('enemy'):
			types[entity.type] = 0
	for type in types:
		var enemy = HelpEnemy.instance()
		enemy.data = Config.enemies[type]
		details.enemies.add_child(enemy)
