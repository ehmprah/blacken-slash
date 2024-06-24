extends PanelContainer

onready var main = get_node('/root/Main')
onready var expand_icon = $Container/Top/Container/Expand/TextureRect
onready var folder_name = $Container/Top/Container/Labels/Name
onready var list = $Container/Margin
onready var items = $Container/Margin/Items
onready var btn_install = $Container/Top/Container/Install

var expanded = false
var label

func _ready():
	folder_name.text = label
	update()


func update():
	btn_install.visible = State.game.phase == Config.PHASE_FROM_VAULT


func add_item(item):
	items.add_child(item)


func install():
	main.ui.inventory.processing = true
	SFX.play(SFX.sounds.ITEM_DROP)
	var amount = items.get_child_count()
	for item in items.get_children():
		item._on_Equip_button_down()
	main.ui.notification.show('T_DIFFICULTY', "+%d" % amount)
	main.ui.inventory.processing = false
	queue_free()


func _on_Expand_button_down():
	expanded = !expanded
	expand_icon.flip_v = expanded
	list.visible = expanded
