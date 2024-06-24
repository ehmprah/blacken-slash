extends Button

signal press_confirmed

export(String, 'CLICK', 'ITEM_AUGMENT', 'ITEM_DROP_UNIQUE', 'ITEM_DROP', 'OPEN_TREASURE', 'BUFF') var sound
export var prevent_doubleclick = true
export var confirm = false

onready var tween = $Tween
onready var toast = $Confirm
onready var progress = $Confirm/Center/Panel/Progress
onready var label_container = $Confirm/Center/Panel/Margin
onready var confirm_icon = $ConfirmIcon

const confirm_duration = 0.5

func _ready():
	toast.visible = false
	confirm_icon.visible = false
	if confirm:
		toggle_confirm()
		# warning-ignore:return_value_discarded
		Settings.connect('settings_changed', self, 'toggle_confirm')


func toggle_confirm():
	confirm_icon.visible = confirm && Settings.user.gameplay.skip_confirmation_buttons == false


func play_sound():
	if !confirm:
		SFX.play(SFX.sounds[sound])


func prevent_double_click():
	if prevent_doubleclick:
		disabled = true
		$Timer.start()


func reenable():
	disabled = false


func confirm_start():
	if confirm:
		if Settings.user.gameplay.skip_confirmation_buttons == false:
			toast.visible = true
			tween.remove_all()
			tween.interpolate_property(toast, "modulate", Color(1, 1, 1, 0), Color.white, 0.1)
			tween.interpolate_property(progress, "rect_scale:x", 0, 1, confirm_duration)
			tween.interpolate_callback(self, confirm_duration, 'confirm_success')
			tween.start()
		else:
			confirm_success()


func confirm_success():
	# Simulate mouse up at that point
	var evt = InputEventMouseButton.new()
	evt.button_index = BUTTON_LEFT
	evt.position = get_viewport().get_mouse_position()
	evt.pressed = false
	get_tree().input_event(evt)
	# Execute the actual callback
	toast.visible = false
	progress.rect_scale.x = 0
	SFX.play(SFX.sounds[sound])
	emit_signal('press_confirmed')


func confirm_cancel():
	if confirm && Settings.user.gameplay.skip_confirmation_buttons == false:
		tween.remove_all()
		tween.interpolate_property(toast, "modulate", Color.white, Color(1, 1, 1, 0), 0.3)
		tween.interpolate_property(progress, "rect_scale:x", progress.rect_scale.x, 0, 0.3)
		tween.start()
