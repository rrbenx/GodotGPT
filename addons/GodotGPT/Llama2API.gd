class_name Llama2API

extends Node

var replicate_api = ProjectSettings.get_setting("application/config/replicate_api")

export (String) var prompt = ""
var timer

var url
var url2
var headers
var data
var output_data = ""
var output = ""
var output_response : Dictionary

onready var _prompt : HTTPRequest = HTTPRequest.new()

# Make the GET request
onready var response2 : HTTPRequest = HTTPRequest.new()

# Headers
var _headers = PoolStringArray()



func _enter_tree():
	"""
	REPLICATE API
	"""
	#print_debug(replicate_api)
	
	if replicate_api != null:
		
		# Define the API endpoint and headers
		url = "https://api.replicate.com/v1/predictions"
		
		# Append the Authorization header
		_headers.append("Authorization: Token " + replicate_api)

		# Append the Content-Type header
		_headers.append("Content-Type: application/json")


		# Define the data for the POST request
		data = {
			"version": "8e6975e5ed6174911a6ff3d60540dfd4844201974602551e10e9e87ab143d81e", #7B parameter
			"input": {
				"prompt": prompt 
			}
		}
	
	"""
	MY AWS API
	"""
	# Repo : https://github.com/Sam2much96/llama2web/blob/main/main.py
	if replicate_api == null:
		url = "http://ec2-51-20-53-10.eu-north-1.compute.amazonaws.com:8080/v1/"
		#_headers.append('Accept : application/json')
		#_headers.append('Content-Type : application/json')
		
		data = {"prompt": prompt,'msg': null, 'type': "dict"}


func _ready():
	
	add_child(_prompt)
	add_child(response2)
	
	if replicate_api != null:
		# For making direct api calls to replicate api
		# POST method
		_prompt.connect("request_completed",self, "_request_callback")
	
		# GET method
		response2.connect("request_completed", self, "_output")
	
	if replicate_api == null:
		# POST method
		_prompt.connect("request_completed",self, "_output")



#func chat(text):
	send_prompt(_prompt)



func _request_callback(result, response_code, headers, body) -> void:
	#print_debug("headers", headers)
	if response_code == HTTPClient.RESPONSE_OK or HTTPClient.RESPONSE_CREATED :
		var response = str2var(body.get_string_from_utf8())
		
		
		print_debug("response", response)
		
		
		
		url2 = response["urls"]["get"]

		print_debug(url2)

		
		yield(get_tree().create_timer(4), "timeout")
		
		# Get request
		response2.request(url2, _headers, false, HTTPClient.METHOD_GET)
		
	elif response_code == HTTPClient.STATUS_DISCONNECTED:
		print_debug("not connected to server")
	else:
		var response = str2var(body.get_string_from_utf8())
		print_debug("ERROR: " + str(response_code))
		print_debug("response", response)


func _output(result, response_code, headers, body) -> String:
	print("Prompt Fetched ", response_code)
	
	
	
	if response_code == HTTPClient.RESPONSE_OK:
		output_response = str2var(body.get_string_from_utf8())
		
		output_data = output_response["output"]

		for item in output_data:
			output += item
		
		#print_debug(output)
	else:
		#print(body)
		var response = str2var(body.get_string_from_utf8())
		print_debug("ERROR: " + str(response_code))
		print_debug("response: ", response)
	return output


func send_prompt(request: HTTPRequest) -> void:


	if prompt != "" :
		print("sending prompt >>>>")
		request.request(url,_headers , false, HTTPClient.METHOD_POST, JSON.print(data))
	else:
		push_error("prompt cannot be empty")




