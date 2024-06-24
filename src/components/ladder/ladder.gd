extends HBoxContainer

const Entry = preload("res://components/ladder_entry/ladder_entry.tscn")
const EnterName = preload("res://components/enter_name/enter_name.tscn")

var data = null
var season = null

onready var main = get_node('/root/Main')
onready var status = $Panel/Container/List/Status
onready var ladder = $Panel/Container/List/Scroll
onready var entries = $Panel/Container/List/Scroll/Margin/Content
onready var progress = $Panel/Container/Bottom/V/Progress
onready var time_left = $Panel/Container/Bottom/V/Progress/TimeLeft
onready var meta_name = $Panel/Container/Bottom/V/Meta/H/Name
onready var meta_desc = $Panel/Container/Bottom/V/Meta/Description
onready var warning = $Panel/Container/Bottom/V/Warning
onready var play_btn = $Panel/Container/Bottom/V/Container/Play

func purge_cache():
	if data != null:
		var difficulty = State.profile.ladder.difficulty
		var size = data.size()
		if size == 0 || difficulty > data[size - 1].difficulty:
			data = null


func show():
	main.ui.overlays.add_child(self)
	season = Util.get_season()
	meta_name.text = Config.meta_labels[season.meta].name
	meta_desc.text = Config.meta_labels[season.meta].desc
	var is_in_game = State.game != null && State.game.type == Config.GAME_LADDER
	warning.visible = !is_in_game && State.profile.ladder != null && State.profile.ladder.season == Util.get_season().current
	play_btn.visible = !is_in_game
	if data == null:
		$HTTP.request(
			Config.backend + '/getLadder', 
			["Content-Type: text/plain"], 
			true, 
			HTTPClient.METHOD_POST, 
			to_json({ "version": Config.version })
		)
		ladder.visible = false
		status.visible = true
		status.text = 'T_LOADING'
		Util.delete_children(entries)
	$AnimationPlayer.play("Enter")
	update_progress()
	visible = true
	if Controls.needs_focus():
		warning.find_next_valid_focus().grab_focus()
	$Timer.start()
	yield($AnimationPlayer, "animation_finished")


func hide():
	$AnimationPlayer.play_backwards("Enter")
	yield($AnimationPlayer, "animation_finished")
	visible = false
	main.ui.overlays.remove_child(self)
	Controls.change_focus()
	$Timer.stop()


func _on_HTTP_request_completed(result, response_code, _headers, body):
	if result == $HTTP.RESULT_SUCCESS && response_code == 200:
		data = parse_json(body.get_string_from_utf8())
		if typeof(data) == TYPE_ARRAY && data.size() > 0:
			var number = 0
			for entry in data:
				var child = Entry.instance()
				child.data = entry
				number += 1
				child.data.number = number
				child.data.gear = parse_json(child.data.gear)
				# Because godots json parser only produces floats, we gotta cast back
				for item in child.data.gear:
					item.type = int(item.type)
					item.rarity = int(item.rarity)
				entries.add_child(child)
			status.visible = false
			ladder.visible = true
		else:
			status.text = 'T_LADDER_EMPTY'
	else:
		status.text = 'T_FAILED_LOAD'


func _on_Timer_timeout():
	update_progress()


func update_progress():
	var update = Util.get_season_progress()
	progress.value = update.percentage
	time_left.text = update.formatted


func play():
	if State.profile.name.length() == 0:
		return get_parent().add_child(EnterName.instance())
	main.ui.title.hide()
	yield(hide(), 'completed')
	State.start_game(Config.GAME_LADDER, season.meta)
