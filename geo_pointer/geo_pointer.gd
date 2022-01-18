extends Spatial

const OWM_URL = "https://api.openweathermap.org/data/2.5/weather"
var OWM_TOKEN = OS.get_environment("OWM_TOKEN")

var lat = 35
var lon = 135


func _ready():
	var error = $HTTPRequest.connect("request_completed", self, "_on_request_completed")

	if !error:
		var req_url = "%s?lat=%s&lon=%s&lang=ja&appid=%s" % [OWM_URL, lat, lon, OWM_TOKEN]
		$HTTPRequest.request(req_url)


func _on_request_completed(_result, response_code, _headers, body):
	var json = JSON.parse(body.get_string_from_utf8())

	if response_code == 200:
		var w = json.result.weather[0]
		$AnimatedSprite3D.set_animation(w.icon)
	else:
		print(json.result)
