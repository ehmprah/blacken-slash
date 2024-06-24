extends VBoxContainer

const Attribute = preload("res://components/help_attribute/help_attribute.tscn")
const Skill = preload("res://components/help_skill/help_skill.tscn")
const Item = preload("res://components/item_base/item_base.tscn")
const Enemy = preload("res://components/help_enemy/help_enemy.tscn")

onready var scroll = $Tabs/Scroll
onready var tabs = {
	'attributes': $Tabs/Scroll/Margin/Attributes,
	'skills': $Tabs/Scroll/Margin/Skills,
	'items': $Tabs/Scroll/Margin/Items,
	'enemies': $Tabs/Scroll/Margin/Enemies,
}

func _ready():
	# warning-ignore:return_value_discarded
	RNG.connect('new_item_found', self, 'update_items')
	
	$TabControls/Container/Attributes.pressed = true
	
	for data in Config.attributes.values():
		if !data.key.begins_with('flag'):
			var attribute = Attribute.instance()
			attribute.data = data
			attribute.self_modulate = Color.black
			tabs.attributes.add_child(attribute)

	for data in Config.skills.values():
		# We use the _item_types key to discern "hardcoded" vs rollable skills
		if data.has('_item_types'):
			var skill = Skill.instance()
			skill.data = data
			skill.self_modulate = Color.black
			tabs.skills.add_child(skill)

	for data in Config.enemies.values():
		var enemy = Enemy.instance()
		enemy.data = data
		enemy.self_modulate = Color.black
		tabs.enemies.add_child(enemy)

	for data in Config.items:
		if data.rarity > Config.RARITY_RARE:
			var item = Item.instance()
			item.data = data
			item.mask_name = true
			tabs.items.add_child(item)


func _physics_process(_delta):
	if visible:
		var value = Input.get_axis("ui_page_up", "ui_page_down")
		if value != 0:
			scroll.scroll_vertical += value * 20


func update_items():
	for item in tabs.items.get_children():
		var key = item.data.prefix + item.data.name + item.data.suffix
		if State.profile.found.has(key):
			item.mask_name = false
			item.build_name()


func show_tab(new):
	for tab in tabs.values():
		tab.visible = false
	new.visible = true
	scroll.scroll_vertical = 0


func _on_Attributes_toggled(button_pressed):
	if button_pressed:
		show_tab(tabs.attributes)


func _on_Skills_toggled(button_pressed):
	if button_pressed:
		show_tab(tabs.skills)


func _on_Items_toggled(button_pressed):
	if button_pressed:
		show_tab(tabs.items)


func _on_Enemies_toggled(button_pressed):
	if button_pressed:
		show_tab(tabs.enemies)
