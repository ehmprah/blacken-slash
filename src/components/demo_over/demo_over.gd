extends Control

func _ready():
	show()
	SFX.play(SFX.sounds.OPEN_TREASURE)


func show():
	$AnimationPlayer.play("Enter")
	yield($AnimationPlayer, "animation_finished")
	$Container/Scroll/V/Beeper.show()


func hide():
	$AnimationPlayer.stop()
	$AnimationPlayer.play_backwards("Enter")
	yield($AnimationPlayer, "animation_finished")
	queue_free()


func show_buttons():
	$Container/Scroll/V/Beeper.visible = false
	$Container/Scroll/V/Continue.visible = false
	$Container/Scroll/V/Buttons.visible = true

func _on_Discord_button_down():
	# warning-ignore:return_value_discarded
	OS.shell_open('https://discord.gg/y9hjQndJS2')


func _on_Wishlist_button_down():
	if OS.has_feature('prologue'):
		# warning-ignore:return_value_discarded
		OS.shell_open('steam://store/1746560')
		return

	match OS.get_name():
		'Android':
			# warning-ignore:return_value_discarded
			OS.shell_open('https://play.google.com/store/apps/details?id=com.ehmprah.blackenslash')
		'iOS':
			# warning-ignore:return_value_discarded
			OS.shell_open('itms-apps://apps.apple.com/app/id1604646442')
		_:
			# warning-ignore:return_value_discarded
			OS.shell_open('https://store.steampowered.com/app/1746560/Blacken_Slash/')


func _on_Subscribe_button_down():
	# warning-ignore:return_value_discarded
	OS.shell_open('http://eepurl.com/huNop1')

