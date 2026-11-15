extends ProgressBar

@onready var label: Label = $Label

var boss: CharacterBody2D

func _ready() -> void:
	await get_tree().process_frame
	boss = get_tree().get_first_node_in_group("boss")
	if boss == null:
		visible = false
		return

	max_value = boss.max_health
	value = boss.health
	_update_label()
	boss.health_changed.connect(_on_boss_health_changed)
	if boss.has_signal("phase_changed"):
		boss.phase_changed.connect(_on_phase_changed)
	if boss.has_signal("defeated"):
		boss.defeated.connect(_on_defeated)

func _on_boss_health_changed(new_health: int) -> void:
	value = new_health
	_update_label()

func _on_phase_changed(phase: int) -> void:
	if label:
		label.text = "BOSS  ·  PHASE %d" % phase
	# brief flash on phase change
	modulate = Color(1.4, 0.6, 0.6)
	await get_tree().create_timer(0.2).timeout
	modulate = Color.WHITE

func _on_defeated() -> void:
	if label:
		label.text = "BOSS DEFEATED"
	value = 0

func _update_label() -> void:
	if label == null or boss == null:
		return
	label.text = "BOSS  ·  PHASE %d" % boss.phase
