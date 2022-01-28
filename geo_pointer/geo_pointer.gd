extends Spatial

const OWM_URL = "https://api.openweathermap.org/data/2.5/weather"
var OWM_APIKEY = OS.get_environment("OWM_APIKEY")

const UPDATE_SPRITE_OPACITY = 0.002

var lat = 35
var lon = 135

var request_completed = false

onready var weather_icon = $AnimatedSprite3D
onready var thermometer = $Sprite3D
onready var viewport = $Viewport
onready var label = viewport.get_node(@"Label")


func _ready():
	var error = $HTTPRequest.connect("request_completed", self, "_on_request_completed")

	if !error:
		var req_url = "%s?lat=%s&lon=%s&lang=ja&units=metric&appid=%s" % [OWM_URL, lat, lon, OWM_APIKEY]
		$HTTPRequest.request(req_url)


func _process(_delta):

	if request_completed:
		# Zファイト防止のため温度の表示位置を少しだけ手前にセット
		var cam = get_viewport().get_camera()
		thermometer.translation = cam.global_transform.basis.z * 0.02

		label.rect_size = label.get_font("MplusFont").get_string_size(label.text)
		viewport.size = label.rect_size

		_update_sprite_opacity()


func _on_request_completed(_result, response_code, _headers, body):
	var json = JSON.parse(body.get_string_from_utf8())

	if response_code == 200:
		var w = json.result.weather[0]
		weather_icon.set_animation(w.icon)

		label.text = "%0.1f°C" % [json.result.main.temp]
		thermometer.texture = viewport.get_texture()

		_update_sprite_opacity()

		request_completed = true
	else:
		print(json.result)


func _update_sprite_opacity():
	var t = OS.get_ticks_msec() * UPDATE_SPRITE_OPACITY
	weather_icon.opacity = sin(t) * 0.5 + 0.5
	thermometer.opacity = sin(t + deg2rad(180)) * 0.5 + 0.5
