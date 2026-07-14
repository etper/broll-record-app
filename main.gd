extends Node2D

const SAVE_FILE := "user://library.json"

var brolls: Array = []

var current_index := -1

var dragging := false
var drag_offset := Vector2.ZERO

var base_position := Vector2.ZERO
var base_scale := Vector2.ONE
var base_rotation := 0.0

var anim_time := 0.0


func _ready():
	load_library()
	refresh_list()
	update_animation_label()


func _process(delta):

	update_animation_label()

	if current_index == -1:
		return

	var broll = brolls[current_index]

	if !broll.get("animation_enabled", false):
		return

	anim_time += delta

	var tex = $TextureRect

	# Reset to base transform each frame
	tex.position = base_position
	tex.scale = base_scale
	tex.rotation = base_rotation

	match broll.get("animation", "none"):

		"zoom_in":
			tex.scale = base_scale * (1.0 + anim_time * 0.02)

		"zoom_out":
			tex.scale = base_scale * max(0.1, 1.0 - anim_time * 0.02)

		"pan_left":
			tex.position.x = base_position.x - anim_time * 25

		"pan_right":
			tex.position.x = base_position.x + anim_time * 25

		"float":
			tex.position.y = base_position.y + sin(anim_time * 1.5) * 8

		"pulse":
			var s = 1.0 + sin(anim_time * 3.0) * 0.03
			tex.scale = base_scale * s

		"rotate":
			tex.rotation = base_rotation + sin(anim_time) * deg_to_rad(2)

		"none":
			pass


func _on_import_button_pressed():
	$UI/FileDialog.popup_centered()


func _on_file_dialog_files_selected(paths: PackedStringArray):

	for path in paths:

		var exists := false

		for broll in brolls:
			if broll["path"] == path:
				exists = true
				break

		if exists:
			continue

		brolls.append({
			"name": path.get_file(),
			"path": path,
			"animation": "none",
			"animation_enabled": false
		})

	refresh_list()
	save_library()


func refresh_list():

	var list = $UI/ItemList

	list.clear()

	for broll in brolls:
		list.add_item(broll["name"])


func _on_item_list_item_selected(index):

	current_index = index

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
	
	await get_tree().process_frame

	$TextureRect.pivot_offset = $TextureRect.size / 2

	# Reset transform
	$TextureRect.position = Vector2(790, 349)
	$TextureRect.scale = Vector2.ONE
	$TextureRect.rotation = 0

	base_position = $TextureRect.position
	base_scale = $TextureRect.scale
	base_rotation = $TextureRect.rotation

	anim_time = 0.0


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

		# Upgrade old save files
		for broll in brolls:

			if !broll.has("animation"):
				broll["animation"] = "none"

			if !broll.has("animation_enabled"):
				broll["animation_enabled"] = false


func _unhandled_input(event):

	if event.is_action_pressed("toggle_ui"):
		$UI.visible = !$UI.visible

	if current_index == -1:
		return

	if event is InputEventKey and event.pressed:

		match event.keycode:

			KEY_A:
				brolls[current_index]["animation_enabled"] = !brolls[current_index]["animation_enabled"]
				save_library()

			KEY_1:
				set_animation("none")

			KEY_2:
				set_animation("zoom_in")

			KEY_3:
				set_animation("zoom_out")

			KEY_4:
				set_animation("pan_left")

			KEY_5:
				set_animation("pan_right")

			KEY_6:
				set_animation("float")

			KEY_7:
				set_animation("pulse")

			KEY_8:
				set_animation("rotate")

		save_library()


func _on_texture_rect_gui_input(event):

	if event is InputEventMouseButton:

		if event.button_index == MOUSE_BUTTON_LEFT:

			if event.pressed:
				dragging = true
				drag_offset = $TextureRect.get_global_mouse_position() - $TextureRect.global_position

			else:
				dragging = false
				base_position = $TextureRect.position

		elif event.pressed:

			var scale_step := 0.05

			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				$TextureRect.scale *= 1.0 + scale_step
				base_scale = $TextureRect.scale

			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				$TextureRect.scale *= 1.0 - scale_step
				base_scale = $TextureRect.scale

	elif event is InputEventMouseMotion and dragging:

		$TextureRect.global_position = $TextureRect.get_global_mouse_position() - drag_offset
		base_position = $TextureRect.position


func _on_reset_scale_pressed() -> void:

	$TextureRect.scale = Vector2.ONE
	base_scale = Vector2.ONE

func update_animation_label():

	var label = $UI/AnimationLabel

	if current_index == -1:
		label.text = "Animation: None"
		return

	var broll = brolls[current_index]

	var anim = broll.get("animation", "none").capitalize()

	if broll.get("animation_enabled", false):
		label.text = "Animation: %s (ON)" % anim
	else:
		label.text = "Animation: %s (OFF)" % anim

func set_animation(anim: String):
	brolls[current_index]["animation"] = anim
	anim_time = 0.0
	save_library()
