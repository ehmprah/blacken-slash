extends CanvasLayer

const PopUp = preload('res://components/popup/popup.tscn')

onready var container = $SafeArea
onready var hud = $SafeArea/HUD
onready var title = $SafeArea/Title
onready var level_clear = $SafeArea/LevelClear
onready var inventory = $SafeArea/Inventory
onready var game_over = $SafeArea/GameOver
onready var boss_reward = $SafeArea/BossReward
onready var overlays = $Overlays
onready var compare = $Overlays/Compare
onready var ladder = $Overlays/Ladder
onready var menu = $Overlays/Menu
onready var notification = $Overlays/Notification
onready var difficulty = $Overlays/DifficultySelect
onready var help = $Overlays/HelpOverlay

func _ready():
	# Respect safe area
	var rect = OS.get_window_safe_area()
	var screen_size = OS.get_window_size()
	var view_size = container.get_size()
	var aspect_y = view_size.y / screen_size.y
	var aspect_x = view_size.x / screen_size.x
	var safe_position = Vector2(rect.position.x * aspect_x, rect.position.y * aspect_y)
	var safe_size = Vector2(rect.size.x * aspect_x, rect.size.y * aspect_y)
	container.set_position(safe_position)
	container.set_size(safe_size)
	overlays.set_position(safe_position)
	overlays.set_size(safe_size)

	# Remove children from the scene tree for performance
	for child in container.get_children():
		container.remove_child(child)
	for child in overlays.get_children():
		overlays.remove_child(child)

	# But keep the inventory because we rely on _ready within children
	container.add_child(inventory)


func _unhandled_input(event):
	if event.is_action_released("ui_menu"):
		if menu.visible:
			menu.hide()
		else:
			menu.show()
	if event.is_action_released('ui_stats') && State.get_phase() == Config.PHASE_LEVEL_PLAY:
		help.show()


func popup(type, what = null):
	var popup = PopUp.instance()
	popup.add(type, what)
	overlays.add_child(popup)
