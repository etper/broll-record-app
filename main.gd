extends Node2D

const SAVE_FILE := "user://library.json"

var brolls: Array = []


func _ready():
	load_library()
	refresh_list()


func _on_import_button_pressed():
	$UI/FileDialog.popup_centered()


func _on_file_dialog_files_selected(paths: PackedStringArray):

	for path in paths:

		# Prevent duplicates
		var exists := false
		
		print("Selected: ", path)

		for broll in brolls:
			if broll["path"] == path:
				exists = true
				break

		if exists:
			continue

		brolls.append({
			"name": path.get_file(),
			"path": path
		})

	refresh_list()
	save_library()


func refresh_list():

	var list = $UI/ItemList

	list.clear()

	for broll in brolls:
		list.add_item(broll["name"])


func _on_item_list_item_selected(index):

	var path = brolls[index]["path"]

	if !FileAccess.file_exists(path):
		push_error("File not found: " + path)
		return

	var image = Image.load_from_file(path)

	if image == null:
		push_error("Couldn't load image.")
		return

	var texture = ImageTexture.create_from_image(image)

	$TextureRect.texture = texture


func save_library():

	var file = FileAccess.open(SAVE_FILE, FileAccess.WRITE)

	if file == null:
		push_error("Couldn't save library.")
		return

	file.store_string(JSON.stringify(brolls))


func load_library():

	if !FileAccess.file_exists(SAVE_FILE):
		return

	var file = FileAccess.open(SAVE_FILE, FileAccess.READ)

	if file == null:
		return

	var text = file.get_as_text()

	var parsed = JSON.parse_string(text)

	if parsed is Array:
		brolls = parsed


func _unhandled_input(event):
	if event.is_action_pressed("toggle_ui"):
		$UI.visible = !$UI.visible
