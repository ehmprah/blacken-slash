extends Node

var regex

func _ready():
	regex = RegEx.new()
	regex.compile("[A-Za-z0-9]")


func mask_string(text):
	return regex.sub(text, '?', true)


static func get_season():
	var season = {
		'first': 1635724800000,
		'duration': 604800000,
		'current': 0,
		'elapsed': 0,
	}
	var time = OS.get_system_time_msecs()
	var meta_count = Config.meta_labels.size() - 1
	season.elapsed = (time - season.first) % season.duration
	season.meta = ((time - season.first) / season.duration) % meta_count
	season.remaining = season.duration - season.elapsed
	season.current = time - season.elapsed
	season.percentage = float(season.elapsed) / float(season.duration)
	return season


static func get_season_progress():
	var season = get_season()
	var remaining = season.duration - season.elapsed
	var days = floor(remaining / 86400000)
	remaining -= days * 86400000
	var hours = floor(remaining / 3600000)
	remaining -= hours * 3600000
	var minutes = floor(remaining / 60000)
	remaining -= minutes * 60000
	var seconds = remaining / 1000
	return {
		'percentage': float(season.elapsed) / float(season.duration),
		'formatted': '%02d:%02d:%02d:%02d' % [days, hours, minutes, seconds]
	}


static func get_effective_health(attributes):
	var health = 100
	if attributes.has('shields'):
		health += 100 * attributes.shields
	if attributes.has('resistance'):
		health *= 1 + attributes.resistance
	return health


static func simplify_gear():
	var gear = []
	for original in State.game.gear:
		var item = {
			'rarity': original.rarity,
			'type': original.type,
			'prefix': original.prefix,
			'name': original.name,
			'suffix': original.suffix,
			'attributes': [],
		}
		for attribute in original.attributes:
			item.attributes.append({ 
				'name': attribute.name, 
				'value': attribute.value,
				'format': attribute.format,
			})
		if original.has('skill'):
			item.skill = original.skill
		gear.append(item)
	return gear

static func global_to_grid(vector):
	return Vector2(
		floor((vector.y / Config.grid_size.y) + (vector.x / Config.grid_size.x)),
		floor((-vector.x / Config.grid_size.x) + (vector.y / Config.grid_size.y))
	)

static func cartesian_to_isometric(cartesian):
	return Vector2(cartesian.x - cartesian.y, (cartesian.x + cartesian.y) / 2)


static func isometric_to_cartesian(isometric):
	return Vector2((isometric.x - isometric.y) / 1.5, isometric.x / 3 + isometric.y / 1.5)


static func is_in_range(point, center, rng):
	# We use a simple square projected onto the isometric grid
	var tl = center - Config.grid_size * rng
	var br = center + Config.grid_size * rng
	return (
		point.x >= tl.x && point.x <= br.x && point.y >= tl.y && point.y <= br.y
	)


# Get one tile step along one of the four cardinal directions
static func get_direction_vector(vector):
	var direction = Vector2(Config.grid_size.x, Config.grid_size.y)
	if (vector.x < 0): direction.x *= -1
	if (vector.y < 0): direction.y *= -1
	return direction


static func get_projectile_colors():
	var chosen = []
	var colors = [Color.aqua, Color.blueviolet, Color.magenta, Color.crimson, Color.gold, Color.greenyellow]
	chosen.append(colors[randi() % colors.size()])
	colors.erase(colors[0])
	chosen.append(colors[randi() % colors.size()])
	return chosen


static func clean_(dict):
	for key in dict.keys():
		if key is String && key.begins_with('_'):
			dict.erase(key)
	return dict


static func round_to_digit(num, digit):
	return round(num * pow(10.0, digit)) / pow(10.0, digit)


static func format_damage(a, b = null):
	if b != null:
		return String(floor(a * 100)) + '-' + String(floor(b * 100))
	return String(floor(a * 100))


static func format_value(value, format):
	if format == Config.FORMAT_PERCENT:
		return Util.format_percent(value)
	elif format == Config.FORMAT_PLAIN:
		return String(value)


static func format_percent(value):
	var result = ("%.2f" % (value * 100)) + '%'
	result = result.replace('.00', '')
	return result


static func format_percent_range(from, to):
	return ("%d" % (from * 100)) + '-' + ("%d" % (to * 100)) + '%'


static func delete_children(node):
	if node.get_child_count() > 0:
		for n in node.get_children():
			node.remove_child(n)
			n.queue_free()


static func sort_enemies(a, b):
	if a.distance_to_player < b.distance_to_player:
		return true
	return false


static func format_k(number):
	if number < 1000:
		return String(number)
	else:
		return "%0.1fk" % floor_to_digit(float(number) / 1000.0, 1)


static func floor_to_digit(num, digit):
	return floor(num * pow(10.0, digit)) / pow(10.0, digit)


static func array_join(arr : Array, glue : String = '') -> String:
	var string : String = ''
	for index in range(0, arr.size()):
			string += str(arr[index])
			if index < arr.size() - 1:
					string += glue
	return string


static func cycle_index(current, direction, last):
	var index = current
	index += direction
	if index < 0:
		index = last
	if index > last:
		index = 0
	return index


func join_array(array, separator = ""):
	var output = "";
	for s in array:
		output += str(s) + separator
	output = output.left(output.length() - separator.length())
	return output


# taken from: https://github.com/binogure-studio/godot-uuid
static func getRandomInt():
  # Randomize every time to minimize the risk of collisions
  randomize()

  return randi() % 256


static func uuidbin():
  # 16 random bytes with the bytes on index 6 and 8 modified
  return [
	getRandomInt(), getRandomInt(), getRandomInt(), getRandomInt(),
	getRandomInt(), getRandomInt(), ((getRandomInt()) & 0x0f) | 0x40, getRandomInt(),
	((getRandomInt()) & 0x3f) | 0x80, getRandomInt(), getRandomInt(), getRandomInt(),
	getRandomInt(), getRandomInt(), getRandomInt(), getRandomInt(),
  ]


static func uuidv4():
  # 16 random bytes with the bytes on index 6 and 8 modified
  var b = uuidbin()

  return '%02x%02x%02x%02x-%02x%02x-%02x%02x-%02x%02x-%02x%02x%02x%02x%02x%02x' % [
	# low
	b[0], b[1], b[2], b[3],

	# mid
	b[4], b[5],

	# hi
	b[6], b[7],

	# clock
	b[8], b[9],

	# clock
	b[10], b[11], b[12], b[13], b[14], b[15]
  ]
