extends DirectionalLight3D

@export var day_duration: float = 100.0 # seconds for a full day/night cycle
@export var normal_time_scale: float = 1.0
@export var speed_up_scale: float = 10.0

@export var day_light_color: Color = Color(1, 1, 1)
@export var night_light_color: Color = Color(0.1, 0.1, 0.2)
@export var day_sky_color: Color = Color(0.6, 0.8, 1.0)
@export var night_sky_color: Color = Color(0.02, 0.04, 0.1)

var time_of_day: float = 0.0 # 0.0 = midnight, 0.5 = noon, 1.0 = next midnight
var time_scale: float = 1.0

func _ready():
	time_of_day = 0.25 # Start at 6AM
	time_scale = normal_time_scale

func _process(delta):
	time_of_day += (delta * time_scale) / day_duration
	if time_of_day > 1.0:
		time_of_day -= 1.0
	update_lighting()
	print(get_viewport().get_mouse_position())

func _input(event):
	if Input.is_action_just_pressed("speed_up"):
		time_scale = speed_up_scale
	elif Input.is_action_just_released("speed_up"):
		time_scale = normal_time_scale

func update_lighting():
	# Sun rotation: -90 at midnight, 90 at noon, 270 at next midnight
	var angle = lerp(-90.0, 270.0, time_of_day)
	rotation_degrees.x = angle

	# Light intensity and color
	var light_strength = clamp(sin(time_of_day * PI * 2.0) * 0.5 + 0.5, 0.05, 1.0)
	light_energy = light_strength
	light_color = day_light_color.lerp(night_light_color, 1.0 - light_strength)

	# Update ambient and procedural sky via Environment's Sky resource
	var env := get_viewport().get_world_3d().environment
	if env:
		env.ambient_light_energy = light_strength

		var sky = env.sky
		if sky and sky.sky_material and sky.sky_material is ProceduralSkyMaterial:
			var sky_material = sky.sky_material
			var sky_col = day_sky_color.lerp(night_sky_color, 1.0 - light_strength)
			sky_material.sky_top_color = sky_col
			sky_material.sky_horizon_color = sky_col.lerp(Color(1,1,1), 0.08)
			sky_material.sky_curve = 0.4 + 0.3 * (1.0 - light_strength)
