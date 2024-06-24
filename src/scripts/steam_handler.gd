extends Node

var SDK = null

func _ready():
	if OS.has_feature("steam"):
		SDK = load("res://scripts/steam_api.gd").new()
		SDK.init()


func unlock_achievement(key):
	if SDK != null:
		SDK.unlock_achievement(key)
