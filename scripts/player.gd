extends CharacterBody3D

const SPEED = 8.0
const JUMP_VELOCITY = 12

var sensitivity = 0.005
var gravity = 24.0
var available_blocks = []
var selected_block_index = 0

var inventory = {
	2: 0, 
	3: 0,  
	6: 0,  
	7: 0 
}


func _ready():
	# Starting items for testing
	inventory[2] = 5  # 5 Dirt
	inventory[3] = 3  # 3 Grass
	inventory[6] = 2  # 2 Stone

	update_available_blocks()
	update_inventory_ui()
	update_selected_block_ui()


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

	# Block breaking
	if Input.is_action_just_pressed("remove_block"):
		if $Camera3D/RayCast3D.is_colliding():
			var collider = $Camera3D/RayCast3D.get_collider()
			if collider.has_method("destroy_block"):
				var collision_point = $Camera3D/RayCast3D.get_collision_point()
				var collision_normal = $Camera3D/RayCast3D.get_collision_normal()
				var block_pos = collision_point - collision_normal
				var broken_block_id = collider.destroy_block(block_pos)
				
				# Add broken block to inventory if you got the id
				if broken_block_id != null and broken_block_id >= 0:
					add_to_inventory(broken_block_id)
				
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

			# Update inventory
			inventory[block_id] -= 1
			update_available_blocks()
			update_selected_block_ui()
			update_inventory_ui()
		else:
			print("Not enough blocks!")

	move_and_slide()


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
		_: return "Unknown"
