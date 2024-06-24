extends HBoxContainer

const Item = preload("res://components/item_base/item_base.tscn")
const IconTool = preload('res://assets/icons/icon_tool.svg')
const IconModule = preload('res://assets/icons/icon_module.svg')

signal replace

onready var main = get_node('/root/Main')
onready var items = $M/Panel/V/Upper/V/Scroll/Items
onready var replacement = $M/Panel/V/Lower/Replacement
onready var prev = $M/Panel/V/Upper/V/Compare/H/Prev
onready var next = $M/Panel/V/Upper/V/Compare/H/Next
onready var btn_replace = $M/Panel/V/Upper/V/Compare/H/Replace
onready var highlight = $M/Highlight/Button
onready var animation = $AnimationPlayer

var candidate
var selectedIndex = 0

func _unhandled_input(_event):
	accept_event()


func show():
	highlight.visible = false
	animation.play("Enter")
	visible = true
	main.ui.overlays.add_child(self)
	yield(animation, "animation_finished")
	highlight.visible = true
	if Controls.needs_focus():
		btn_replace.grab_focus()


func hide():
	highlight.visible = false
	animation.play_backwards("Enter")
	yield(animation, "animation_finished")
	main.ui.overlays.remove_child(self)
	visible = false
	Controls.change_focus()


func hydrate(item):
	selectedIndex = 0
	candidate = item
	Util.delete_children(items)
	Util.delete_children(replacement)
	add_item(item.data, true)
	for gear in State.game.gear: 
		if gear.type == item.data.type:
			add_item(gear, false)
	var first = items.get_child(0)
	first.visible = true
	move_highlight(first)
	var has_cycle = items.get_child_count() > 1
	prev.visible = has_cycle
	next.visible = has_cycle


func add_item(data, is_new):
	var item = Item.instance()
	item.expanded = true
	item.expandable = false
	item.show_help_icon = false
#	item.show_salvage_overlay = !is_new
	item.data = data
	item.visible = is_new
	if is_new:
		replacement.add_child(item)
	else:
		items.add_child(item)


func cycle(direction):
	var end = items.get_child_count() - 1
	items.get_child(selectedIndex).visible = false
	selectedIndex += direction
	if selectedIndex < 0:
		selectedIndex = end
	if selectedIndex > end:
		selectedIndex = 0
	var item = items.get_child(selectedIndex)
	item.visible = true
	move_highlight(item)


func move_highlight(item):
	var highlight_position = Vector2(14 + 68, -68)
	highlight.icon = IconTool
	if item.data.type == Config.ITEM_MODULE:
		highlight_position.x += 3 * 68
		highlight.icon = IconModule
	highlight_position.x += selectedIndex * 68
	highlight.modulate = Config.rarity_colors[item.data.rarity]
	highlight.rect_position = highlight_position


func _on_Prev_button_down():
	cycle(-1)


func _on_Next_button_down():
	cycle(1)


func _on_Replace_button_down():
	emit_signal("replace", candidate, items.get_child(selectedIndex).data)
	SFX.play(SFX.sounds.ITEM_DROP)
	hide()
