extends Node2D

onready var preview = $Preview
onready var hover = $Hover
onready var tween = $Tween
onready var camera = $Camera2D
onready var cursor = $ControllerCursor
onready var player = get_parent()
onready var game = get_node('/root/Main/Game')

var hovering_tile

func _physics_process(_delta):
	# TODO: here we should actually turn off the processing as per game phase!
	if State.get_phase() == Config.PHASE_LEVEL_PLAY:
		var velocity = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		if velocity != Vector2.ZERO:
			cursor.visible = true
			cursor.position += Vector2(velocity.x, velocity.y / 2) * 7
			handle_hover(cursor.global_position)
		else:
			if cursor.position.round() != Vector2(0, 32):
				cursor.position = lerp(cursor.position, Vector2(0, 32), 0.1)
			else:
				cursor.visible = false


func _unhandled_input(event):
	if State.get_phase() != Config.PHASE_LEVEL_PLAY:
		return
	
	if event is InputEventMouseButton:
		if event.is_pressed():
			var pos = preview.world_to_map(preview.to_local(get_global_mouse_position()))
			if preview.get_cellv(pos) == -1:
				camera.start_drag()
		else:
			camera.end_drag()
			if event.button_index == BUTTON_RIGHT:
				player.emit_signal('mode_reset')

	if event is InputEventMouseMotion:
		handle_hover(get_global_mouse_position())

	if event.is_action_released('ui_accept'):
		if hovering_tile == null:
			execute_action(preview.world_to_map(preview.to_local(get_global_mouse_position())))
		else:
			execute_action(hovering_tile)


func reset():
	camera.recenter()
	preview.clear()
	hover.clear()
	hovering_tile = null


func execute_action(tile):
	if preview.get_cellv(tile) > -1:
		var vector = preview.map_to_world(tile)
		return player.take_action(vector)


func handle_hover(at_position):
	var pos = preview.world_to_map(preview.to_local(at_position))
	var type = preview.get_cellv(pos)
	if type > -1:
		get_tree().set_input_as_handled()
	if pos != hovering_tile:
		if type > -1:
			get_tree().set_input_as_handled()
			hover.clear()
			if hovering_tile == null:
				tween.stop(hover, "modulate")
				tween.interpolate_property(hover, "modulate", Color(1, 1, 1, 0), Color(1, 1, 1, 1), 0.2)
				tween.start()
			hovering_tile = pos
			# Movement
			if type > 0:
				hover.set_cellv(pos, 0)
			# Attacks
			else:
				hover.set_cellv(pos, 1)
				var skill = player.state.skills[player.mode]
				if skill.type != Config.SKILL_SELF:
					# Beam always goes max range
					if skill.type == Config.PROJECTILE_BEAM && skill.range > 1:
						for n in skill.range:
							hover.set_cellv(pos.normalized() * (n + 1), 1)
					# Add area of effect preview
					if skill.has('aoe'):
						var from = pos if skill.type == Config.PROJECTILE_BALLISTIC else pos.normalized() * skill.range
						for hit_vector in skill.aoe:
							hover.set_cellv(from + hover.world_to_map(hit_vector), 1)
		elif hovering_tile != null:
				hovering_tile = null
				tween.stop(hover, "modulate")
				tween.interpolate_property(hover, "modulate", Color(1, 1, 1, 1), Color(1, 1, 1, 0), 0.2)
				tween.start()


func update():
	modulate = Color(1, 1, 1, 0)
	player.animation.play("ControlFadeIn")
	player.action_icon.visible = false
	preview.clear()
	hover.clear()
	if player.mode == player.modes.MOVING:
		var ap = player.state.attributes.action_points
		var enemies = game.get_positions('enemy')
		for y in range(-ap, ap + 1):
			for x in range(-ap, ap + 1):
				var point_cost = abs(x) + abs(y)
				if (point_cost <= ap && (x != 0 || y != 0)):
					var target = player.position + preview.map_to_world(Vector2(x, y))
					if game.grid.has(target):
						var has_enemy = enemies.has(target)
						var path = Pathfinding.calculate_path(player.position, target)
						var path_cost = path.size() - 1
						if (path_cost > 0 && path_cost <= ap):
							var cell = 0 if has_enemy else path_cost + 1
							preview.set_cell(x, y, cell)
	else:
		var skill = player.state.skills[player.mode]
		var enemies = game.get_positions('enemy')
		if skill.type == Config.SKILL_SELF:
			preview.set_cell(0, 0, 0)
			handle_hover(player.position)
			player.action_icon.visible = true
		elif skill.type == Config.SKILL_TELEPORT:
			for tile in game.grid:
				if !enemies.has(tile) && player.position != tile:
					preview.set_cellv(preview.world_to_map(tile - player.position), 1)
		else:
			if skill.range == 0:
				for vector in skill.aoe:
					preview.set_cellv(preview.world_to_map(vector), 0)
			else:
				for key in Config.cardinal:
					var direction = Config.direction[key]
					for n in skill.range:
						var pos = player.position + direction * (n + 1)
						if (
							(!skill.has('range_min') || n >= skill.range_min) &&
							(!skill.has('only_floor') || game.grid.has(pos)) &&
							# Don't allow dashes where you would end up in the air
							(skill.type != Config.SKILL_DASH || game.grid.has(player.position + direction * n))
						):
							preview.set_cellv(preview.world_to_map(pos - player.position), 0)
						if skill.has('blocking') && enemies.has(pos):
							break
