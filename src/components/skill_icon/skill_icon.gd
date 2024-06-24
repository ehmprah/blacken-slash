extends Control

func hydrate(skill):
	$Icon.texture = skill.icon
	for index in $Cost.get_child_count():
		$Cost.get_child(index).visible = index < skill.cost
