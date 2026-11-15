extends CanvasLayer

## Fake BSOD fitted to the game viewport (320x180 → window stretch).

signal finished

var _closing := false

@onready var texture_rect: TextureRect = $TextureRect

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 128
	get_tree().paused = true

	if texture_rect.texture == null:
		texture_rect.texture = _load_bsod_texture()
	if texture_rect.texture == null:
		_build_fallback()

	await get_tree().create_timer(4.5, true, false, true).timeout
	if not _closing:
		_close_and_restart()

func _load_bsod_texture() -> Texture2D:
	var res = load("res://assets/bluescreen.jpg")
	if res is Texture2D:
		return res

	var img := Image.new()
	var path := ProjectSettings.globalize_path("res://assets/bluescreen.jpg")
	if img.load(path) == OK:
		return ImageTexture.create_from_image(img)
	return null

func _build_fallback() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color("0078D7")
	add_child(bg)

	var face := Label.new()
	face.text = ":("
	face.add_theme_font_size_override("font_size", 32)
	face.add_theme_color_override("font_color", Color.WHITE)
	face.position = Vector2(12, 16)
	add_child(face)

	var body := Label.new()
	body.text = "Your PC ran into a problem.\nStop code: BOUNCE_BACK_EXCEPTION"
	body.add_theme_font_size_override("font_size", 8)
	body.add_theme_color_override("font_color", Color.WHITE)
	body.position = Vector2(12, 60)
	add_child(body)

func _input(event: InputEvent) -> void:
	if _closing:
		return
	if event.is_pressed() and (event is InputEventKey or event is InputEventMouseButton):
		get_viewport().set_input_as_handled()
		_close_and_restart()

func _close_and_restart() -> void:
	if _closing:
		return
	_closing = true
	var tree := get_tree()
	tree.paused = false
	finished.emit()
	# Free before reload so the overlay does not linger as a root sibling.
	if is_inside_tree():
		get_parent().remove_child(self)
	tree.reload_current_scene()
	queue_free()
