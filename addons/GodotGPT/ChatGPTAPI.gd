class_name ChatGPTAPI
extends HTTPRequest

var openai_api = ProjectSettings.get_setting("application/config/openai_api")

func _ready():
	pass
	
func chat(text):
	send_prompt(self, text)



func _request_callback(result, response_code, headers, body) -> void:
	if response_code == HTTPClient.RESPONSE_OK:
		var response = str2var(body.get_string_from_utf8())
		print_debug("response", response)
		
		var text = response["choices"][0]["text"].strip_edges()
		emit_signal("received_response", text)
			
		
	elif response_code == HTTPClient.STATUS_DISCONNECTED:
		print_debug("not connected to server")
	else:
		var response = str2var(body.get_string_from_utf8())
		print_debug("ERROR: " + str(response_code))
		print_debug("response", response)


func send_prompt(request: HTTPRequest, text: String) -> void:
	var body = PoolByteArray() #PackedByteArray()
	body.append_array("{".to_utf8());
	body.append_array("\"model\": \"text-davinci-003\",\n".to_utf8());
	body.append_array(("\"prompt\": \"%s\",\n" % text).to_utf8());
	body.append_array("\"max_tokens\": 2048,\n".to_utf8());
	body.append_array("\"temperature\": 0.1,\n".to_utf8());
	body.append_array("\"top_p\": 1.0,\n".to_utf8());
	body.append_array("\"frequency_penalty\": 0.0,\n".to_utf8());
	body.append_array("\"presence_penalty\": 0.0\n".to_utf8());
	body.append_array("}\n".to_utf8());
	

	var headers = [
		"Authorization: Bearer " + openai_api,
		"Content-Type: application/json"
	]

	print_debug(body.get_string_from_utf8())

	var error = request.request("https://api.openai.com/v1/completions", headers, false ,HTTPClient.METHOD_POST, body.get_string_from_utf8()) #, body.get_string_from_utf8()
	if error != OK:
		print_debug("An error occurred in the HTTP request.")
	pass
