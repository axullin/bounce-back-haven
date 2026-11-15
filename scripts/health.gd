extends ProgressBar

var player: CharacterBody2D

func _ready() -> void:
	await get_tree().process_frame

	player = get_tree().get_first_node_in_group("player")
	if player == null:
		player = get_node_or_null("../../Player")

	if player:
		max_value = player.max_health
		value = player.health
		player.health_changed.connect(_on_player_health_changed)
	else:
		push_error("Health bar: nie znaleziono gracza")

func _on_player_health_changed(new_health: int) -> void:
	value = new_health
