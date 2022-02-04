extends Spatial

const CAMERA_ROTATE_SPEED = 0.0001
const TAP_TIME_THRESHOLD = 0.2

var tap_delay_timer = Timer.new()

# 回転の初期値（カメラの正面）は兵庫県明石市 北緯35度、東経135度に設定
var rot_y = deg2rad(135)
var rot_x = deg2rad(35)

onready var cam_rot = $StaticBody/CameraRot
onready var spring_arm = $StaticBody/CameraRot/SpringArm
onready var camera = $StaticBody/CameraRot/SpringArm/Camera

# カメラのズーム関連のパラメータ
var is_screen_touching_index0: bool
var is_screen_touching_index1: bool
var screen_touching_pos_index0: Vector2
var screen_touching_pos_index1: Vector2
var distance_of_multi_touch_position: float

# 目標となる SpringArm の長さ
var target_spring_length: float


func _ready():
	tap_delay_timer.one_shot = true
	self.add_child(tap_delay_timer)

	target_spring_length = spring_arm.spring_length


func _input(event):

	if event is InputEventScreenDrag:
		if is_screen_touching_index0 && is_screen_touching_index1:
			# ピンチイン、ピンチアウト
			if event.index == 0:
				screen_touching_pos_index0 = event.position
			elif event.index == 1:
				screen_touching_pos_index1 = event.position
			var new_distance = (screen_touching_pos_index0 - screen_touching_pos_index1).length()
			target_spring_length += (distance_of_multi_touch_position - new_distance) * 0.01
			distance_of_multi_touch_position = new_distance
		else:
			# カメラの旋回
			rot_y -= event.speed.x * CAMERA_ROTATE_SPEED
			rot_x += event.speed.y * CAMERA_ROTATE_SPEED
			rot_x = clamp(rot_x, deg2rad(-90), deg2rad(90))

	elif event is InputEventScreenTouch:
		if event.index == 0:
			# touch or click
			is_screen_touching_index0 = event.pressed
			screen_touching_pos_index0 = event.position
			if event.pressed:
				if tap_delay_timer.is_stopped():
					tap_delay_timer.start(TAP_TIME_THRESHOLD)
			else:
				if !tap_delay_timer.is_stopped():
					_camera_raycast(event.position)
					tap_delay_timer.stop()
		elif event.index == 1:
			# 2本目の指のtouchイベント
			is_screen_touching_index1 = event.pressed
			screen_touching_pos_index1 = event.position
			distance_of_multi_touch_position = (screen_touching_pos_index0 - screen_touching_pos_index1).length()

	elif event is InputEventMouseButton:
		if event.pressed:
			# マウスホイールによる拡縮
			if event.button_index == BUTTON_WHEEL_UP:
				target_spring_length -= 0.5
			elif event.button_index == BUTTON_WHEEL_DOWN:
				target_spring_length += 0.5

	target_spring_length = clamp(target_spring_length, 11, 20)


func _physics_process(_delta):
	cam_rot.rotation.y = rot_y
	cam_rot.rotation.x = rot_x

	spring_arm.spring_length = lerp(spring_arm.spring_length, target_spring_length, 0.1)


func _camera_raycast(pos):
	var from = camera.project_ray_origin(pos)
	var to = from + camera.project_ray_normal(pos) * 100

	var space_state = get_world().direct_space_state
	var result = space_state.intersect_ray(from, to)
	if result:
		var n = result.normal
		var h = Vector3(n.x, 0, n.z)
		var v0 = Vector2(0, -1)
		var v1 = Vector2(n.x, n.z)
		var lat = rad2deg(acos(h.dot(n) / (h.length() * n.length())))		# 緯度
		var lon = rad2deg(acos(v0.dot(v1) / (v0.length() * v1.length())))	# 経度

		if n.y < 0: lat *= -1
		if n.x > 0: lon *= -1

		var g = load("res://geo_pointer/geo_pointer.tscn").instance()
		g.translation = result.position + (result.normal * 0.2)
		g.lat = lat
		g.lon = lon
		add_child(g)
