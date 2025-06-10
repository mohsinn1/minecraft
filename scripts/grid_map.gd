extends GridMap

# Dictionary to store block damage state: { "x,y,z": hits }
var damaged_blocks := {}

# Optional: assign AudioStreamPlayer3D nodes or preload sounds
@onready var hit_sound = preload("res://assets/music/hit sound.mp3")
@onready var break_sound = preload("res://assets/music/break_sound.mp3")

func damage_block(world_position: Vector3) -> void:
	var map_coords = local_to_map(world_position)
	var block_id = get_cell_item(map_coords)

	if block_id == -1:
		return  # No block here to damage

	var key = str(map_coords)  # Unique string key for dictionary

	if damaged_blocks.has(key):
		damaged_blocks[key] += 1
	else:
		damaged_blocks[key] = 1

	# Check if it's time to destroy
	if damaged_blocks[key] >= 2:
		set_cell_item(map_coords, -1)  # Destroy block
		damaged_blocks.erase(key)

		# Add block to player's inventory
		var player = get_tree().get_first_node_in_group("player")
		if player:
			player.add_to_inventory(block_id)

		# Play break sound
		if break_sound:
			break_sound.play()

	else:
		# First hit sound
		if hit_sound:
			hit_sound.play()



func destroy_block(world_coordinate: Vector3) -> int:
	var map_coordinate = local_to_map(world_coordinate)
	var block_id = get_cell_item(map_coordinate)
	set_cell_item(map_coordinate, -1)
	return block_id


func place_block(world_position: Vector3, block_id: int) -> void:
	var map_coords = local_to_map(world_position)
	if get_cell_item(map_coords) == -1:
		set_cell_item(map_coords, block_id)
