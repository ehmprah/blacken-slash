extends "res://components/title_base/title_base.gd"

const PopUp = preload('res://components/popup/popup.tscn')
const Changelog = preload('res://components/changelog/changelog.tscn')

onready var main = get_node('/root/Main')
onready var container_welcome = $UI/Welcome
onready var container_menu = $UI/Menu
onready var build = $Text/Build
onready var quit_btn = $UI/Menu/Container/Quit
onready var btn_hide_welcome = $UI/Welcome/Container/Container/HideWelcome
onready var newgame = $NewGame
onready var modes = {
	'normal': {
		'button': $UI/Menu/Container/Normal,
		'label': $UI/Menu/Container/Normal/V/Info,
	},
	'ladder': {
		'button': $UI/Menu/Container/Ladder,
		'label': $UI/Menu/Container/Ladder/V/Info,
	}
}

var ident_played = false

func _ready():
	# warning-ignore:return_value_discarded
	Controls.connect('controls_changed', self, 'ui_focus')
	# warning-ignore:return_value_discarded
	Settings.connect('language_changed', self, 'update_labels')
	if OS.has_feature('mobile') || OS.get_name() == 'HTML5':
		quit_btn.visible = false


func ui_focus(needs_focus):
	if visible && needs_focus:
		if container_welcome.visible:
			btn_hide_welcome.grab_focus()
		else:
			modes.normal.button.grab_focus() 


func show():
	main.ui.container.add_child(self)
	container_welcome.visible = !State.profile.welcome
	container_menu.visible = State.profile.welcome
	if !ident_played:
		$Title.play()
		ident_played = true
		yield(get_tree().create_timer(0.25), "timeout")
	update_labels()
	# Handle demo labels
	if OS.has_feature('demo'):
		build.text = 'T_DEMO'
		build.visible = true
		if OS.get_name() == 'iOS':
			build.text = 'Lite'
		if OS.has_feature('prologue'):
			build.text = 'Prologue'
	visible = true
	$Voice.play()
	$AnimationPlayer.play("FadeIn")
	yield($AnimationPlayer, "animation_finished")
	ui_focus(Controls.needs_focus())


func hide():
	$Timer.stop()
	yield(.hide(), 'completed')
	container_menu.visible = true
	main.ui.container.remove_child(self)


func update_labels():
	# Normal mode
	if State.save_normal == null:
		modes.normal.label.text = 'T_NORMAL_DESCRIPTION'
	else:
		var info = tr('T_LEVEL') + ' ' + String(State.save_normal.difficulty.current)
		modes.normal.label.text = info
	# Ladder mode
	var locked = State.profile.difficulty_record < 25
	if State.save_normal != null && State.save_normal.difficulty.record >= 25:
		locked = false
	modes.ladder.button.disabled = locked
	if locked:
		modes.ladder.label.text = 'T_LADDER_LOCKED'
	elif State.save_ladder == null:
		modes.ladder.label.text = 'T_LADDER_DESCRIPTION'
	else:
		modes.ladder.label.text = tr('T_LEVEL') + ' ' + String(State.save_ladder.difficulty.current)


func show_container(container):
	$AnimationPlayer.play_backwards('FadeUI')
	yield($AnimationPlayer, "animation_finished")
	$Timer.stop()
	container_menu.visible = false
	container_welcome.visible = false
	container.visible = true
	$AnimationPlayer.play('FadeUI')
	ui_focus(Controls.needs_focus())


func _show_menu():
	main.ui.menu.show()


func _on_Play_button_down():
	if State.save_normal == null:
		newgame.show()
	else:
		yield(hide(), 'completed')
		State.continue_game(Config.GAME_NORMAL)


func _quit():
	get_tree().quit()


func _on_Ladder_button_down():
	if State.save_ladder == null:
		main.ui.ladder.show()
	else:
		yield(hide(), 'completed')
		State.continue_game(Config.GAME_LADDER)


func _on_Discord_button_down():
	# warning-ignore:return_value_discarded
	OS.shell_open('https://discord.gg/y9hjQndJS2')


func _on_ident_finished():
	Music.next()


func _on_HideWelcome_button_down():
	show_container(container_menu)
	State.profile.welcome = true
	State.save_profile()
