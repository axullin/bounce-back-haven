extends CharacterBody2D

signal health_changed(new_health)
signal phase_changed(phase: int)
signal defeated

enum Pattern {
	CHASE,
	DASH,
	FAN_SHOT,
	SLAM,
	RING_SHOT,
	DEFLECT,
}

@export var max_health = 3000
@export var contact_damage: int = 15
@export var move_speed = 70.0
@export var dash_speed = 220.0
@export var hover_height = 48.0

@onready var anim = $AnimatedSprite2D
@onready var hitbox = $Hitbox
@onready var boss_bullet = preload("res://scenes/boss_bullet.tscn")

var health = 3000
var player: CharacterBody2D
var phase := 1
var busy := false
var deflecting := false
var pattern_index := 0
var home_y := 0.0
var arena_min_x := -120.0
var arena_max_x := 140.0
var base_scale := Vector2.ONE

var phase1_patterns: Array[Pattern] = [
	Pattern.CHASE,
	Pattern.FAN_SHOT,
	Pattern.DASH,
	Pattern.CHASE,
	Pattern.SLAM,
]

var phase2_patterns: Array[Pattern] = [
	Pattern.DASH,
	Pattern.RING_SHOT,
	Pattern.DEFLECT,
	Pattern.SLAM,
	Pattern.FAN_SHOT,
	Pattern.CHASE,
]

var phase3_patterns: Array[Pattern] = [
	Pattern.DASH,
	Pattern.SLAM,
	Pattern.RING_SHOT,
	Pattern.DEFLECT,
	Pattern.DASH,
	Pattern.FAN_SHOT,
	Pattern.SLAM,
]

func _ready() -> void:
	add_to_group("enemy")
	add_to_group("boss")
	base_scale = scale
	health = max_health
	home_y = global_position.y
	player = get_tree().get_first_node_in_group("player")
	health_changed.emit(health)
	_run_pattern_loop()

func _physics_process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
		velocity = Vector2.ZERO
		return

	if not busy:
		_hover_toward_player(delta)

	move_and_slide()
	_update_animation()
	_update_visual_state()

func _hover_toward_player(_delta: float) -> void:
	var target = Vector2(player.global_position.x, home_y - hover_height)
	var dir = (target - global_position)
	if dir.length() > 4.0:
		velocity = dir.normalized() * move_speed * (1.25 if phase >= 3 else 1.0)
	else:
		velocity = Vector2.ZERO
	global_position.x = clampf(global_position.x, arena_min_x, arena_max_x)

func _run_pattern_loop() -> void:
	await get_tree().create_timer(0.8).timeout
	while is_instance_valid(self) and health > 0:
		var patterns := _current_patterns()
		var pattern: Pattern = patterns[pattern_index % patterns.size()]
		pattern_index += 1
		await _execute_pattern(pattern)
		await get_tree().create_timer(_recovery_time()).timeout

func _current_patterns() -> Array[Pattern]:
	match phase:
		1:
			return phase1_patterns
		2:
			return phase2_patterns
		_:
			return phase3_patterns

func _recovery_time() -> float:
	match phase:
		1:
			return 0.55
		2:
			return 0.35
		_:
			return 0.2

func _execute_pattern(pattern: Pattern) -> void:
	busy = true
	velocity = Vector2.ZERO
	match pattern:
		Pattern.CHASE:
			await _pattern_chase()
		Pattern.DASH:
			await _pattern_dash()
		Pattern.FAN_SHOT:
			await _pattern_fan_shot()
		Pattern.SLAM:
			await _pattern_slam()
		Pattern.RING_SHOT:
			await _pattern_ring_shot()
		Pattern.DEFLECT:
			await _pattern_deflect()
	busy = false
	deflecting = false

func _pattern_chase() -> void:
	var duration = 1.4 if phase == 1 else 1.0
	var elapsed = 0.0
	while elapsed < duration and health > 0:
		if player:
			var target = Vector2(player.global_position.x, home_y - hover_height * 0.6)
			velocity = (target - global_position).normalized() * move_speed * 1.4
		elapsed += get_physics_process_delta_time()
		await get_tree().physics_frame

func _pattern_dash() -> void:
	if player == null:
		return
	# Telegraph
	modulate = Color(1.4, 0.7, 0.7)
	await get_tree().create_timer(0.35).timeout
	modulate = Color.WHITE

	var dir = (player.global_position - global_position).normalized()
	var dash_time = 0.35
	var elapsed = 0.0
	while elapsed < dash_time and health > 0:
		velocity = dir * dash_speed * (1.0 + 0.25 * (phase - 1))
		elapsed += get_physics_process_delta_time()
		await get_tree().physics_frame
	velocity = Vector2.ZERO
	await get_tree().create_timer(0.15).timeout

func _pattern_fan_shot() -> void:
	if player == null:
		return
	modulate = Color(1.2, 0.9, 0.5)
	await get_tree().create_timer(0.25).timeout
	modulate = Color.WHITE

	var shots = 3 + phase
	var spread = 0.55
	for i in range(shots):
		if player == null or health <= 0:
			return
		var t = 0.0 if shots == 1 else float(i) / float(shots - 1)
		var angle = lerp(-spread, spread, t)
		var aim = (player.global_position - global_position).normalized().rotated(angle)
		_spawn_bullet(global_position, global_position + aim * 200.0, 160.0 + phase * 20.0)
		await get_tree().create_timer(0.08).timeout

func _pattern_slam() -> void:
	modulate = Color(0.7, 0.85, 1.4)
	await get_tree().create_timer(0.3).timeout

	var rise_target = Vector2(global_position.x if player == null else player.global_position.x, home_y - hover_height - 40.0)
	await _move_to(rise_target, 0.35)
	await get_tree().create_timer(0.15).timeout

	var slam_x = player.global_position.x if player else global_position.x
	var ground = Vector2(slam_x, home_y + 8.0)
	await _move_to(ground, 0.2)

	_spawn_shockwave()
	modulate = Color.WHITE
	await get_tree().create_timer(0.25).timeout
	await _move_to(Vector2(global_position.x, home_y - hover_height), 0.3)

func _pattern_ring_shot() -> void:
	modulate = Color(1.3, 0.5, 1.1)
	await get_tree().create_timer(0.2).timeout
	modulate = Color.WHITE

	var count = 8 + phase * 2
	for i in range(count):
		var angle = TAU * float(i) / float(count)
		var aim = Vector2.RIGHT.rotated(angle)
		_spawn_bullet(global_position, global_position + aim * 100.0, 120.0 + phase * 15.0)
	await get_tree().create_timer(0.35).timeout

func _pattern_deflect() -> void:
	deflecting = true
	modulate = Color(0.45, 0.95, 1.35)
	await get_tree().create_timer(1.6 if phase < 3 else 2.0).timeout
	deflecting = false
	scale = base_scale
	modulate = Color.WHITE

func _spawn_shockwave() -> void:
	for dir_x in [-1.0, 1.0]:
		var start = Vector2(global_position.x, home_y + 10.0)
		call_deferred(
			"_spawn_bullet_now",
			start,
			start + Vector2(dir_x * 200.0, 0.0),
			180.0,
			contact_damage,
			Color(1.0, 0.85, 0.2),
			Vector2(1.6, 1.0)
		)

func _spawn_bullet(from: Vector2, to: Vector2, speed: float) -> void:
	call_deferred(
		"_spawn_bullet_now",
		from,
		to,
		speed,
		10 + phase * 2,
		Color.WHITE,
		Vector2.ONE
	)

func _spawn_bullet_now(
	from: Vector2,
	to: Vector2,
	speed: float,
	dmg: int,
	mod: Color = Color.WHITE,
	scl: Vector2 = Vector2.ONE
) -> void:
	if not is_instance_valid(self) or get_parent() == null:
		return
	var bullet = boss_bullet.instantiate()
	get_parent().add_child(bullet)
	bullet.setup(from, to, speed, dmg)
	bullet.modulate = mod
	bullet.scale = scl

func _move_to(target: Vector2, duration: float) -> void:
	var start = global_position
	var elapsed = 0.0
	while elapsed < duration and health > 0:
		elapsed += get_physics_process_delta_time()
		var t = clampf(elapsed / duration, 0.0, 1.0)
		global_position = start.lerp(target, t)
		velocity = Vector2.ZERO
		await get_tree().physics_frame

func take_damage(amount: int) -> void:
	if health <= 0:
		return

	if deflecting:
		_reflect_toward_player()
		return

	health = max(health - amount, 0)
	health_changed.emit(health)
	_flash_hit()
	_check_phase()

	if health <= 0:
		die()

func _reflect_toward_player() -> void:
	if player == null:
		return
	_spawn_bullet(global_position, player.global_position, 200.0)
	modulate = Color(1.5, 1.5, 1.5)
	await get_tree().create_timer(0.05).timeout
	if deflecting:
		modulate = Color(0.45, 0.95, 1.35)
	elif is_instance_valid(self):
		modulate = Color.WHITE

func _flash_hit() -> void:
	if deflecting:
		return
	modulate = Color(1.6, 0.4, 0.4)
	await get_tree().create_timer(0.06).timeout
	if is_instance_valid(self) and not deflecting:
		modulate = Color.WHITE

func _check_phase() -> void:
	var ratio = float(health) / float(max_health)
	var new_phase = 1
	if ratio <= 0.33:
		new_phase = 3
	elif ratio <= 0.66:
		new_phase = 2

	if new_phase != phase:
		phase = new_phase
		phase_changed.emit(phase)
		pattern_index = 0
		move_speed = 70.0 + (phase - 1) * 18.0

func die() -> void:
	defeated.emit()
	busy = true
	deflecting = false
	velocity = Vector2.ZERO
	modulate = Color(1, 1, 1, 0.4)
	await get_tree().create_timer(0.4).timeout
	queue_free()

func _update_animation() -> void:
	if anim.animation != "idle":
		anim.play("idle")
	if velocity.x > 8.0:
		anim.flip_h = true
	elif velocity.x < -8.0:
		anim.flip_h = false
	elif player:
		anim.flip_h = player.global_position.x > global_position.x

func _update_visual_state() -> void:
	if deflecting:
		var pulse = 1.08 + sin(Time.get_ticks_msec() * 0.02) * 0.06
		scale = base_scale * pulse
	else:
		scale = base_scale

func _on_hitbox_area_entered(area: Area2D) -> void:
	var target = area.get_parent()
	if target and target != self and target.has_method("take_damage"):
		target.call_deferred("take_damage", contact_damage)
