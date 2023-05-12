tool
extends EditorPlugin


var panel
var text_field
var button
var checkbox
var checkbox_all_code
var checkbox_explanation
var response_box
var copy_button
var selection = ""

func _enter_tree():
	add_panel()
	
func _exit_tree():
	remove_panel()
	
func add_panel():

	panel = PanelContainer.new()
	panel.set_custom_minimum_size(Vector2(100, 600))
	panel.set_name("GodotGPT")
	#dock.add_child(panel)
	
	# Add the side panel to the Upper Left (UL) dock slot of the left part of the editor.
	# The editor has 4 dock slots (UL, UR, BL, BR) on each side (left/right) of the main screen.
	#add_control_to_dock(DOCK_SLOT_LEFT_UL, panel)
	add_control_to_dock(DOCK_SLOT_LEFT_UL, panel)
	
	#get_editor_interface().get_editor_viewport().add_child(panel)
	
	var vbox = VBoxContainer.new()
	#vbox.size = Vector2(200, 180)
	vbox.set_size(Vector2(200, 180))
	vbox.set_position ( Vector2(0, 0))
	panel.add_child(vbox)
	
	var label = Label.new()
	label.text = "GPT Request Panel"
	vbox.add_child(label)
	
	text_field = LineEdit.new()
	text_field.set_size(Vector2(180, 20))
	text_field.set_position( Vector2(10, 30))
	vbox.add_child(text_field)
	
	checkbox = CheckBox.new()
	checkbox.set_size( Vector2(180, 20))
	checkbox.set_position(Vector2(10, 60))
	checkbox.text = "Include Context (Scene & Signatures)"
	vbox.add_child(checkbox)
	
	checkbox_all_code = CheckBox.new()
	checkbox_all_code.set_size (Vector2(180, 20))
	checkbox_all_code.set_position (Vector2(10, 60))
	checkbox_all_code.text = "Include All Script"
	vbox.add_child(checkbox_all_code)
	
	checkbox_explanation = CheckBox.new()
	checkbox_explanation.set_size (Vector2(180, 20))
	checkbox_explanation.set_position( Vector2(10, 60))
	checkbox_explanation.text = "Explaination"
	vbox.add_child(checkbox_explanation)
	
	button = Button.new()
	button.set_size (Vector2(80, 20))
	button.set_position(Vector2(60, 90))
	button.text = "Send Request"
	#button.pressed.connect(send_request)
	button.connect("pressed", self, "send_request")
	vbox.add_child(button)
	
	#response_box = CodeEdit.new()
	response_box = TextEdit.new()
	response_box.set_custom_minimum_size(Vector2(180, 500))
	response_box.text = ""
	#response_box.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	
	response_box.set_wrap_enabled(true)
	#response_box.caret_changed.connect(selection_changed)
	vbox.add_child(response_box)
	
	copy_button = Button.new()
	copy_button.set_size(Vector2(80, 20))
	copy_button.set_position(Vector2(60, 90))
	copy_button.text = "EXPERIMENTAL +10: Run Selected snippet"
	#copy_button.pressed.connect(copy_text)
	
	copy_button.connect("pressed", self, "copy_text")
	
	vbox.add_child(copy_button)
	
func selection_changed():
	selection = response_box.get_selected_text()
	
func copy_text():
	var code_editor = get_editor_interface().get_script_editor().get_current_editor().get_base_editor()
	print(selection)
	evaluate(selection)
	
func evaluate(input):
	var script = GDScript.new()
	script.set_source_code("@tool\nextends Node\n\nfunc _enter_tree():\n\teval()\n\tprint_debug(\"executing\")\n\nfunc eval():\n" + input)
	script.reload()
	
	print(script.source_code)

	var obj = Node.new()
	obj.set_script(script)
	
	var root_nodes = get_editor_interface().get_selection().get_selected_nodes()
	
	get_editor_interface().get_edited_scene_root().add_child(obj)
	
	
	#var return_val = obj.eval() # Supposing input is "23 + 2", returns 25
	
	#root_nodes[0].remove_child(obj)

func remove_panel():
	remove_control_from_docks(panel)
	

func compile_function_signatures(sig_in):
	var signatures = ""
	for item in sig_in:
		signatures += "func " + item["name"] + "("
		var nparam = 0
		for param in item["args"]:
			signatures += param["name"]
			nparam += 1
			if nparam < len(item["args"]):
				signatures += ", "
		signatures += ")\n"
		
	return signatures
	
func send_request():
	response_box.set_text("Request...\n\nWait")
	
	var request_text = text_field.get_text()
	var include_signatures = checkbox.is_pressed()
	
	# Get selected text in editor
	var editor = get_editor_interface().get_script_editor()
	var selected_text = ""
	var context = {}
	var prompt = "You are a GDScript 2.0 and Godot 4 Expert."
	
	#if checkbox_explanation.button_pressed:
	if checkbox_explanation.is_pressed():
		prompt += " Be clear and specific on your explanation. Use examples if needed."
	else:
		prompt += " GDScript Code only with comments!."
	
	prompt += "\n\n" + text_field.text
	if editor:
		var script = editor.get_current_script()
		
		if include_signatures:
			# Get function signatures from script resources
			context["constants"] = script.get_script_constant_map()
			context["signals"] = script.get_script_signal_list()
			context["properties"] = script.get_script_property_list()
			context["methods"] = compile_function_signatures(script.get_script_method_list())
			
			prompt += "\n\nConsider the complete and existing function signatures: \n" + compile_function_signatures(script.get_script_method_list())
			prompt += compile_scene_tree(get_scene_tree())
			
	#sdfhdshfsd
	#var code_editor = get_editor_interface().get_script_editor().get_current_editor().get_base_editor()
	var code_editor = RichTextLabel.new() #get_editor_interface().get_script_editor()
	var sel_text = code_editor.get_selected_text()
	
	#if checkbox_all_code.button_pressed:
	if checkbox_all_code.is_pressed():
		sel_text = get_editor_interface().get_script_editor().get_current_script().source_code
	
	if sel_text != "":
		prompt += "\n\nOriginal snippet:\n'" + sel_text + "'\n"
		
		if checkbox_explanation.button_pressed:
			prompt += "\n\nSnippet explanation:\n"
		else:
			prompt += "\n\nNew snippet:\n"
	else:
		#if checkbox_explanation.button_pressed:
		if checkbox_explanation.is_pressed():
			prompt += "\n\nAnswer:\n"
		else:
			prompt += "\n\nCode Snippet:\n"
		
	prompt = prompt.replace("\n", "\\n")
	prompt = prompt.replace("\t", "\\t")
	prompt = prompt.replace("\"", "\\\"")
	
	# Send request to GPT API
	var gptapi = ChatGPTAPI.new()
	#gptapi.request_completed.connect(on_response)
	
	gptapi.connect("request_completed", self, "on_response")
	
	add_child(gptapi)
	
	print_debug(context)
	
	#adecuate context
	gptapi.chat(prompt)

func on_response(result, response_code, headers, body) -> void:
	if response_code == HTTPClient.RESPONSE_OK:
		var response = str2var(body.get_string_from_utf8())
		print_debug("response", response)
		
		var text = response["choices"][0]["text"].strip_edges()
		response_box.text = text
		
		var code_editor = get_editor_interface().get_script_editor().get_current_editor().get_base_editor()
		var sel_text = code_editor.get_selected_text()
		
		print_debug(text)
		
	elif response_code == HTTPClient.STATUS_DISCONNECTED:
		print_debug("not connected to server")
	else:
		var response = str2var(body.get_string_from_utf8())
		print_debug("ERROR: " + str(response_code))
		print_debug("response", response)
		
func compile_scene_tree(tree_structure):
	var structure_text = "\n\nConsider the current scene tree:"
	for item in tree_structure:
		if tree_structure[item] != null:
			print("$'" + str(item) + "' with type '" + str(tree_structure[item]) + "'")
			structure_text += "\n'" + str(item) + "' with type '" + str(tree_structure[item]) + "'"
	return structure_text

# Function to get the open scene tree structure
func get_scene_tree():
	# Create a dictionary to store the tree structure
	var tree_structure = {}
	
	# Get the root node of the open scene tree
	var root_nodes = get_editor_interface().get_selection().get_selected_nodes()
	
	for root_node in root_nodes:
		# Recursively traverse the tree and store the paths and types
		_traverse_tree("/", root_node, tree_structure)
	
	# Return the tree structure
	return tree_structure

# Recursive function to traverse the tree
func _traverse_tree(prefix, node, tree_structure):
	# Get the path and type of the current node
	var node_path = prefix + node.get_name()
	var node_type = node.get_class()
	
	# Store the path and type in the tree structure
	tree_structure[node_path] = node_type
	
	# Iterate through the children of the current node
	for child in node.get_children():
		# Recursively traverse the tree
		_traverse_tree(node_path + "/", child, tree_structure)
	

