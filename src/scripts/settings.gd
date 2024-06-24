extends Node

signal settings_changed
signal language_changed

const FILE_PATH = 'user://config.cfg'
var config_file = ConfigFile.new()
var user = {
	'general': {
		'language': 0,
	},
	'audio': {
		'volume_master': 0.5,
		'volume_music': 1,
		'volume_sound': 1,
		'mute_in_background': false,
	},
	'video': {
		'fullscreen': true,
	},
	'gameplay': {
		'skip_level_clear': false,
		'skip_confirmation_buttons': false,
		'disable_grayscale': false,
	}
}

func save_config():
	for section in user.keys():
		for key in user[section].keys():
			config_file.set_value(section, key, user[section][key])
	config_file.save(FILE_PATH)
	emit_signal('settings_changed')


func load_config():
	var err = config_file.load(FILE_PATH)
	if err == OK:
		for section in user.keys():
			for key in user[section].keys():
				user[section][key] = config_file.get_value(section, key, user[section][key])
		emit_signal('settings_changed')


func language_changed():
	emit_signal("language_changed")
