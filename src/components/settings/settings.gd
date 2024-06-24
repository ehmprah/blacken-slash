extends ScrollContainer

onready var bus_master := AudioServer.get_bus_index('Master')
onready var bus_music := AudioServer.get_bus_index('Music')
onready var bus_sound := AudioServer.get_bus_index('SFX')
onready var label_master = $Margin/List/VolumeMaster/Text/Amount
onready var label_music = $Margin/List/VolumeMusic/Text/Amount
onready var label_sound = $Margin/List/VolumeSound/Text/Amount
onready var volume_master = $Margin/List/VolumeMaster/VolumeMaster
onready var volume_music = $Margin/List/VolumeMusic/VolumeMusic
onready var volume_sound = $Margin/List/VolumeSound/VolumeSound
onready var fullscreen_toggle = $Margin/List/Fullscreen
onready var mute_in_background = $Margin/List/MuteInBackground
onready var skip_level_clear = $Margin/List/SkipLevelClear
onready var skip_confirmation_buttons = $Margin/List/SkipConfirmationButtons
onready var disable_grayscale = $Margin/List/DisableGrayscale
onready var language = $Margin/List/Language

func _ready():
	Settings.load_config()
	
	for locale in Config.locales:
		language.add_item(locale.name)
	language.select(Settings.user.general.language)
	TranslationServer.set_locale(
		Config.locales[Settings.user.general.language].key
	)
	
	set_volume(label_master, bus_master, Settings.user.audio.volume_master)
	set_volume(label_music, bus_music, Settings.user.audio.volume_music)
	set_volume(label_sound, bus_sound, Settings.user.audio.volume_sound)
	volume_master.value = Settings.user.audio.volume_master
	volume_music.value = Settings.user.audio.volume_music
	volume_sound.value = Settings.user.audio.volume_sound
	
	mute_in_background.pressed = Settings.user.audio.mute_in_background
	skip_level_clear.pressed = Settings.user.gameplay.skip_level_clear
	skip_confirmation_buttons.pressed = Settings.user.gameplay.skip_confirmation_buttons
	disable_grayscale.pressed = Settings.user.gameplay.disable_grayscale

	var platform = OS.get_name()
	if platform == 'Android' || platform == 'iOS':
		fullscreen_toggle.visible = false
	else:
		fullscreen_toggle.pressed = Settings.user.video.fullscreen
		OS.window_fullscreen = Settings.user.video.fullscreen


func _physics_process(_delta):
	if visible:
		var scroll = Input.get_axis("ui_page_up", "ui_page_down")
		if scroll != 0:
			scroll_vertical += scroll * 20


func set_volume(label, bus, value):
	label.text = String(value * 100) + "%"
	AudioServer.set_bus_volume_db(bus, linear2db(value))


func _unhandled_input(event):
	if event.is_action_pressed("toggle_fullscreen"):
		fullscreen_toggle.pressed = !fullscreen_toggle.pressed


func _notification(what):
	if Settings.user.audio.mute_in_background:
		if what == MainLoop.NOTIFICATION_WM_FOCUS_IN:
			AudioServer.set_bus_mute(bus_master, false)
		elif what == MainLoop.NOTIFICATION_WM_FOCUS_OUT:
			AudioServer.set_bus_mute(bus_master, true)


func _on_VolumeMaster_value_changed(value):
	Settings.user.audio.volume_master = value
	set_volume(label_master, bus_master, value)
	Settings.save_config()


func _on_VolumeMusic_value_changed(value):
	Settings.user.audio.volume_music = value
	set_volume(label_music, bus_music, value)
	Settings.save_config()


func _on_VolumeSound_value_changed(value):
	Settings.user.audio.volume_sound = value
	set_volume(label_sound, bus_sound, value)
	SFX.play(SFX.sounds.CLICK)
	Settings.save_config()


func _on_Fullscreen_toggled(button_pressed):
	Settings.user.video.fullscreen = button_pressed
	OS.window_fullscreen = button_pressed
	Settings.save_config()


func _on_MuteInBackground_toggled(button_pressed:bool):
	Settings.user.audio.mute_in_background = button_pressed
	Settings.save_config()


func _on_SkipLevelClear_toggled(button_pressed):
	Settings.user.gameplay.skip_level_clear = button_pressed
	Settings.save_config()


func _on_SkipConfirmationButtons_toggled(button_pressed):
	Settings.user.gameplay.skip_confirmation_buttons = button_pressed
	Settings.save_config()


func _on_DisableGrayscale_toggled(button_pressed):
	Settings.user.gameplay.disable_grayscale = button_pressed
	if button_pressed == true:
		get_node('/root/Main/FilterGrayscale').reset_grayscale()
	Settings.save_config()


func _on_ExpandLoot_item_selected(index):
	Settings.user.gameplay.expand_loot = index
	Settings.save_config()


func _on_UnlockCode_text_changed(new_text):
	if new_text == 'xep624':
		Config.debug.create_item = 	{
			'_add_attributes': ['action_points_max', 'resistance', 'shields' ],
			'rarity': Config.RARITY_LEGENDARY,
			'type': Config.ITEM_TOOL,
			'skill': 'shields_half',
			'attributes': [],
			'name': 'T_EHMPERIAL_GUARD',
			'prefix': '',
			'suffix': '',
			'augments': 0,
			'rerolls': 0,
		}
		SFX.play(SFX.sounds.ITEM_DROP_UNIQUE)
		$Margin/List/UnlockCode.text = ''
		get_node('/root/Main/UI').notification.show('T_EHMPERIAL_GUARD', 'T_UNLOCKED')


func select_language(index):
	TranslationServer.set_locale(Config.locales[index].key)
	Settings.user.general.language = index
	Settings.language_changed()
	Settings.save_config()
