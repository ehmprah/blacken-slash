extends PanelContainer

onready var main = get_node('/root/Main')
onready var animation = $AnimationPlayer
onready var overview = $Container/Overview
onready var container = $Container/Pages
onready var pages = {
	'settings': $Container/Pages/Container/Settings,
	'achievements': $Container/Pages/Container/Achievements,
	'stats': $Container/Pages/Container/Stats,
	'changelog': $Container/Pages/Container/Changelog,
	'help': $Container/Pages/Container/Help,
	'credits': $Container/Pages/Container/Credits,
}
onready var btns = {
	'save': $Container/Overview/Panel/Buttons/Save,
	'abandon': $Container/Overview/Panel/Buttons/Abandon,
	'settings': $Container/Overview/Panel/Buttons/Settings,
	'close': $Container/Pages/Container/Buttons/Container/Close
}


func show():
	main.ui.overlays.add_child(self)
	main.game.player.camera.set_physics_process(false)
	container.visible = false
	overview.visible = true
	var is_playing = main.is_playing
	btns.save.visible = is_playing && State.game.phase < Config.PHASE_GAME_OVER
	btns.abandon.visible = is_playing && State.game.phase < Config.PHASE_GAME_OVER
	animation.play("Enter")
	visible = true
	overview.find_next_valid_focus().grab_focus()
	yield(animation, "animation_finished")


func hide():
	animation.play_backwards("Enter")
	yield(animation, "animation_finished")
	visible = false
	main.ui.overlays.remove_child(self)
	main.game.player.camera.set_physics_process(true)
	Controls.change_focus()


func show_page(new):
	animation.play_backwards("ShowPage")
	yield(animation, "animation_finished")
	container.visible = true
	overview.visible = false
	for page in pages.values():
		page.visible = false
	new.visible = true
	if Controls.needs_focus():
		btns.close.grab_focus()
	animation.play("ShowPage")
	yield(animation, "animation_finished")


func _unhandled_input(event):
	if (
		event.is_action_pressed('ui_cancel') ||
		event.is_action_pressed('ui_menu')
	):
		return hide()
	accept_event()


func _on_Menu_gui_input(event):
	# Hide the menu if you click outside the menu container
	if event is InputEventMouseButton && event.button_index == BUTTON_LEFT && !event.is_pressed():
		hide()


func _on_Abandon_button_down():
	yield(hide(), 'completed')
	main.end_run()


func _save():
	main.save_and_quit()


func _settings():
	show_page(pages.settings)


func _achievements():
	pages.achievements.update()
	show_page(pages.achievements)


func _stats():
	pages.stats.update()
	show_page(pages.stats)


func _help():
	show_page(pages.help)


func _changelog():
	show_page(pages.changelog)


func _credits():
	show_page(pages.credits)


func _menu():
	animation.play_backwards("ShowPage")
	yield(animation, "animation_finished")
	container.visible = false
	overview.visible = true
	overview.find_next_valid_focus().grab_focus()
	animation.play("ShowPage")


func _discord():
	# warning-ignore:return_value_discarded
	OS.shell_open('https://discord.gg/y9hjQndJS2')
