extends "res://components/title_base/title_base.gd"

onready var main = get_node('/root/Main')
onready var btn_continue = $UI/Margin/Container/Continue
onready var details = {
	'level': $UI/Margin/Container/Grid/Level/Amount,
	'difficulty': $UI/Margin/Container/Grid/Difficulty/Amount,
	'score': $UI/Margin/Container/Grid/Score/Amount,
	'keys': $UI/Margin/Container/Grid/Keys/Amount,
}

func show():
	main.ui.container.add_child(self)
	# Update the labels
	details.level.text = String(State.game.difficulty.beaten)
	details.difficulty.text = '+' + Util.format_percent(State.game.score_modifier)
	details.score.text = String(floor(State.game.difficulty.beaten * (State.game.score_modifier + 1)))
	details.keys.text = String(State.game.vaultable)
	btn_continue.text = 'T_VAULT' if State.game.vaultable > 0 else 'T_FINISH'
	$Voice.play()
	yield(.show(), 'completed')
	if Controls.needs_focus():
		btn_continue.grab_focus()


func _on_Continue_button_down():
	yield(hide(), 'completed')
	main.ui.container.remove_child(self)
	main.vault_items()
