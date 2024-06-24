extends Node

var data = {}

func _ready():
	var path = "res://levels/"
	var dir = Directory.new()
	dir.open(path)
	dir.list_dir_begin()
	while true:
			var file_name = dir.get_next()
			if file_name == "":
					break
			elif !file_name.begins_with("."):
				var scene = load(path + file_name)
				var instance = scene.instance()
				data[file_name] = {
					'scene': scene,
					'difficulty_min': instance.difficulty_min,
					'difficulty_max': instance.difficulty_max,
					'type': instance.level_type,
					'name': file_name,
					'plays': 0,
				}
				if instance.level_type == instance.level_types.NORMAL:
					for flavor in [
						instance.level_types.WEATHER,
						instance.level_types.FRICTION,
						instance.level_types.KEEP_MOVING,
					]:
						data[file_name + String(flavor)] = {
							'scene': scene,
							'difficulty_min': instance.difficulty_min,
							'difficulty_max': instance.difficulty_max,
							'type': flavor,
							'name': file_name,
							'plays': 0,
						}
				instance.queue_free()
	dir.list_dir_end()
