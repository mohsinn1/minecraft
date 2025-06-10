extends CharacterBody3D

const SPEED = 8.0
const JUMP_VELOCITY = 12

var sensitivity = 0.005
var gravity = 24.0
var available_blocks = []
var selected_block_index = 0

var inventory = {
	2: 0,   # Dirt
	3: 0,   # Grass
	6: 0,   # Stone
	7: 0,   # Wood
	8: 0,    # Wood Planks (for crafting)
	10:0    # Stick (for crafting)
}

# --- Crafting System ---
const RECIPES = {
	"Wood Planks": {"ingredients": {7: 1}, "result": 8, "count": 4}, # 1 Wood -> 4 Wood Planks
	"Stick": {"ingredients": {8: 2}, "result": 10, "count": 4}       # 2 Wood Planks -> 4 Sticks
}
var recipe_names = []
var selected_recipe_index = 0

func _ready():
	# Starting items for testing
	inventory[2] = 5  # 5 Dirt
	inventory[3] = 3  # 3 Grass
	inventory[6] = 2  # 2 Stone
	inventory[7] = 2  # 2 Wood

	update_available_blocks()
	update_inventory_ui()
	update_selected_block_ui()

	# Crafting system
	recipe_names = RECIPES.keys()
	update_recipe_display()

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		rotation.y -= event.relative.x * sensitivity
		$Camera3D.rotation.x -= event.relative.y * sensitivity
		$Camera3D.rotation.x = clamp($Camera3D.rotation.x, deg_to_rad(-70), deg_to_rad(80))

func _physics_process(delta):
	# Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Block selection input
	if Input.is_action_just_pressed("next_block"):
		next_block()
	if Input.is_action_just_pressed("prev_block"):
		prev_block()

	# Jumping
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Movement
	var input_dir = Input.get_vector("left", "right", "forward", "back")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	# Block breaking (2-hit system)
	if Input.is_action_just_pressed("remove_block"):
		if $Camera3D/RayCast3D.is_colliding():
			var collider = $Camera3D/RayCast3D.get_collider()
			if collider.has_method("damage_block"):
				var collision_point = $Camera3D/RayCast3D.get_collision_point()
				var collision_normal = $Camera3D/RayCast3D.get_collision_normal()
				var block_pos = collision_point - collision_normal
				collider.damage_block(block_pos)

	# Block placement
	if Input.is_action_just_pressed("place_block"):
		var block_id = get_current_block_id()
		if block_id != -1 and has_block(block_id):
			if $Camera3D/RayCast3D.is_colliding():
				var collider = $Camera3D/RayCast3D.get_collider()
				if collider.has_method("place_block"):
					var collision_point = $Camera3D/RayCast3D.get_collision_point()
					var collision_normal = $Camera3D/RayCast3D.get_collision_normal()
					collider.place_block(collision_point + collision_normal, block_id)

			inventory[block_id] -= 1
			update_available_blocks()
			update_selected_block_ui()
			update_inventory_ui()
		else:
			print("Not enough blocks!")

	move_and_slide()

# Crafting input and navigation
func _input(event):
	if event.is_action_pressed("craft"):
		craft_selected_recipe()
	elif event.is_action_pressed("next_recipe"):
		select_next_recipe()
	elif event.is_action_pressed("prev_recipe"):
		select_prev_recipe()

# --- Crafting System methods ---
func can_craft(recipe_name: String) -> bool:
	var recipe = RECIPES[recipe_name]
	for block_id in recipe["ingredients"]:
		var required = recipe["ingredients"][block_id]
		if not inventory.has(block_id) or inventory[block_id] < required:
			return false
	return true

func craft_selected_recipe():
	var recipe_name = recipe_names[selected_recipe_index]
	if can_craft(recipe_name):
		var recipe = RECIPES[recipe_name]
		# Remove ingredients
		for block_id in recipe["ingredients"]:
			inventory[block_id] -= recipe["ingredients"][block_id]
		# Add results
		var result_id = recipe["result"]
		var result_count = recipe["count"]
		if inventory.has(result_id):
			inventory[result_id] += result_count
		else:
			inventory[result_id] = result_count
		update_available_blocks()
		update_inventory_ui()
		update_selected_block_ui()
		update_recipe_display()

func update_recipe_display():
	for i in range(recipe_names.size() -1 ):
		var label = $CanvasLayer/CraftLabel
		if label:
			var recipe_name = recipe_names[selected_recipe_index]
			var recipe = RECIPES[recipe_name]
			var can_craft_status = "✓" if can_craft(recipe_name) else "✗"
			label.text = "%s: %s" % [recipe_name, can_craft_status]

func select_next_recipe():
	selected_recipe_index += 1
	update_recipe_display()

func select_prev_recipe():
	selected_recipe_index -= 1
	update_recipe_display()

# --- Inventory and Selection ---
func add_to_inventory(block_id: int):
	if inventory.has(block_id):
		inventory[block_id] += 1
	else:
		inventory[block_id] = 1
	update_available_blocks()
	update_inventory_ui()
	update_selected_block_ui()

func has_block(block_id: int) -> bool:
	return inventory.has(block_id) and inventory[block_id] > 0

func get_current_block_id() -> int:
	if available_blocks.size() == 0:
		return -1
	return available_blocks[selected_block_index]

func next_block():
	if available_blocks.size() == 0:
		return
	selected_block_index = (selected_block_index + 1) % available_blocks.size()
	update_selected_block_ui()

func prev_block():
	if available_blocks.size() == 0:
		return
	selected_block_index = (selected_block_index - 1 + available_blocks.size()) % available_blocks.size()
	update_selected_block_ui()

func update_available_blocks():
	available_blocks.clear()
	for block_id in inventory.keys():
		if inventory[block_id] > 0:
			available_blocks.append(block_id)
	if selected_block_index >= available_blocks.size():
		selected_block_index = 0

func update_inventory_ui():
	$CanvasLayer/InventoryLabel.text = "Inventory:"
	$CanvasLayer/DirtLabel.text = "Dirt: %d" % inventory[2]
	$CanvasLayer/GrassLabel.text = "Grass: %d" % inventory[3]
	$CanvasLayer/StoneLabel.text = "Stone: %d" % inventory[6]
	$CanvasLayer/WoodLabel.text = "Wood: %d" % inventory[7]
	$CanvasLayer/PlankLabel.text = "Wood Planks: %d" % inventory[8]
	$CanvasLayer/StickLabel.text = "Stick: %d" % inventory[10]
	# Optionally show wood planks or sticks if you add more block types

func update_selected_block_ui():
	if available_blocks.size() == 0:
		$CanvasLayer/SelectedLabel.text = "Selected: None"
		return
	var block_id = get_current_block_id()
	var block_name = get_block_name(block_id)
	$CanvasLayer/SelectedLabel.text = "Selected: %s" % block_name

func get_block_name(block_id: int) -> String:
	match block_id:
		2: return "Dirt"
		3: return "Grass"
		6: return "Stone"
		7: return "Wood"
		8: return "Wood Planks"
		10: return "Stick"
		_: return "Unknown"
