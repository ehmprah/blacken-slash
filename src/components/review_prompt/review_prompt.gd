extends PanelContainer

var data
var closable = false

onready var tween = $Tween
onready var bits = $Scroll/V/Bits
onready var btn_continue = $Scroll/V/Btns/Continue

func _ready():
	modulate = Color(0, 0, 0, 0)
	tween.interpolate_property(self, 'modulate', modulate, Color.white, 0.2)
	tween.start()
	yield(tween, 'tween_all_completed')
	for child in bits.get_children():
		yield(child.show(), 'completed')
	btn_continue.disabled = false


func yes():
	match OS.get_name():
		'Android':
			# warning-ignore:return_value_discarded
			OS.shell_open('https://play.google.com/store/apps/details?id=com.ehmprah.blackenslash')
		'iOS':
			# warning-ignore:return_value_discarded
			OS.shell_open('itms-apps://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?id=1604646442&onlyLatestVersion=true&pageNumber=0&sortOrdering=1&type=Purple+Software&action=write-review')
	close()


func close():
	State.add_materials(5000)
	State.profile.reviewed = true
	State.save_profile()
	tween.stop_all()
	tween.interpolate_property(self, "modulate", modulate, Color(0, 0, 0, 0), 0.2)
	tween.start()
	yield(tween, "tween_all_completed")
	queue_free()
