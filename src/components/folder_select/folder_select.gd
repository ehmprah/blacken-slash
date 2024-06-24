extends PanelContainer

onready var main = get_node('/root/Main')
onready var entername = $Panel/V
onready var name_field = $Panel/V/Name
onready var btn_save = $Panel/V/Save
onready var select = $Panel/V/Folder
onready var warning = $Panel/V/OnlyAlphanumeric

var regex
var data
var folders = ['T_NEW_FOLDER']

func _ready():
	regex = RegEx.new()
	regex.compile("[^A-Za-z0-9]")
	# Get all available folders
	for item in State.profile.vault:
		if item.has('folder') && !folders.has(item.folder):
			folders.append(item.folder)
	# Add them to the option button
	for label in folders:
		select.add_item(label)
	var index = folders.size() - 1
	select.select(index)
	select.grab_focus()
	_on_Folder_item_selected(index)


func _unhandled_input(_event):
	# We make sure no input escapes below while this overlay is active
	accept_event()


func _on_Name_text_changed(text):
	var is_alphanumeric = regex.search(text) == null
	btn_save.disabled = text.length() == 0 || !is_alphanumeric
	warning.visible = !is_alphanumeric


func _on_Name_text_entered(_new_text):
	save()


func _on_Folder_item_selected(index):
	name_field.text = folders[select.selected]
	name_field.visible = index == 0
	if index == 0:
		name_field.text = ''
		name_field.grab_focus()


func save():
	SFX.play(SFX.sounds.ITEM_DROP)
	data.folder = name_field.text
	State.save_profile()
	main.ui.inventory.refresh_archive()
	main.ui.inventory.ui_focus(Controls.needs_focus())
	visible = false
	queue_free()

