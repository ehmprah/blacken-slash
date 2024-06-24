extends Node

func init():
	if Steam.restartAppIfNecessary(1746560):
		get_tree().quit()
	else:
		# warning-ignore:return_value_discarded
		Steam.steamInit()


func unlock_achievement(key):
	# warning-ignore:return_value_discarded
	Steam.setAchievement(key)
	# warning-ignore:return_value_discarded
	Steam.storeStats()
