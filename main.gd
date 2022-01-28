extends Spatial

const TAP_TIME_THRESHOLD = 0.2

var tap_delay_timer = Timer.new()

# 回転の初期値（カメラの正面）は兵庫県明石市 北緯35度、東経135度に設定
var rot_y = deg2rad(135)
var rot_x = deg2rad(35)

onready var cam_rot = $StaticBody/CameraRot
onready var camera = $StaticBody/CameraRot/SpringArm/Camera


func _ready():
	tap_delay_timer.one_shot = true
	self.add_child(tap_delay_timer)


func _input(event):

	if event is InputEventScreenDrag:
		rot_y -= event.speed.x * 0.0001
		rot_x += event.speed.y * 0.0001
		rot_x = clamp(rot_x, deg2rad(-90), deg2rad(90))

	elif event is InputEventScreenTouch:
		if event.index == 0:
			if event.pressed:
				if tap_delay_timer.is_stopped():
					tap_delay_timer.start(TAP_TIME_THRESHOLD)
			else:
				if !tap_delay_timer.is_stopped():
					_camera_raycast(event.position)
					tap_delay_timer.stop()


func _physics_process(_delta):
	cam_rot.rotation.y = rot_y
	cam_rot.rotation.x = rot_x


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
