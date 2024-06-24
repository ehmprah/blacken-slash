extends PanelContainer

onready var main = get_node('/root/Main')
onready var animation = $AnimationPlayer
onready var meta_name = $Container/Normal/V/Meta/V/H/Labels/Name
onready var meta_desc = $Container/Normal/V/Meta/V/Description
onready var meta_lock = $Container/Normal/V/Meta/Lock
onready var story_mode = $Container/Normal/V/Story/H/Labels/Setting
onready var btn_start = $Container/Normal/V/HBoxContainer/Start

var meta = -1
var reset_story = false
var season = Util.get_season()

func show():
	# Reset meta and default value
	meta_lock.visible = State.profile.difficulty_record < 5
	meta = -1
	reset_story = false
	update_meta()
	# Toggle visibility and show
	visible = true
	animation.play("Enter")
	if Controls.needs_focus():
		btn_start.grab_focus()

func hide():
	animation.play_backwards("Enter")
	yield(animation, "animation_finished")
	Controls.change_focus()
	visible = false


func start_normal():
	hide()
	if reset_story:
		State.profile.story = {}
	yield(main.ui.title.hide(), 'completed')
	State.start_game(Config.GAME_NORMAL, meta)


func cycle_meta(direction):
	var meta_options = Config.meta_labels.keys()
	var start = meta_options.min()
	var end = meta_options.max()
	meta += direction
	if meta < start:
		meta = end
	if meta > end:
		meta = start
	update_meta()


func update_meta():
	meta_name.text = Config.meta_labels[meta].name
	meta_desc.text = Config.meta_labels[meta].desc
	meta_desc.visible = meta_desc.text.length() > 0


func toggle_story_reset():
	reset_story = !reset_story
	story_mode.text = 'T_STORY_EVERYTHING' if reset_story else 'T_STORY_UNREAD'
