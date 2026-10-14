extends Control

const BASE_CRIT_CHANCE := 0.10
const BASE_CRIT_MULT := 1.5
const PLAYER_BASE_INTERVAL := 1.0
# Fraction of max HP healed on every kill. Tune this for difficulty.
const KILL_HEAL_FRACTION := 0.10
const SHOCK_DAMAGE_FRACTION := 0.25
const GROUND_Y := 160.0     # the line the characters stand on
const FIGHTER_GAP := 170.0  # distance from the arena's center to each fighter's center
const PLAYER_SIZE := 96.0
const ENEMY_SCALE := 2.5    # the "size" in enemies.gd times this


@onready var player_bar: ProgressBar = $PlayerBar
@onready var enemy_bar: ProgressBar = $EnemyBar
@onready var player_rect: ColorRect = $PlayerRect
@onready var enemy_rect: ColorRect = $EnemyRect
@onready var background: ColorRect = $Background

var basic: Dictionary  # the basic attack's result

var player: Combatant
var enemy: Combatant
var enemy_data: Dictionary
var staff: Dictionary  # result of Pipeline.evaluate()

var stage_data: Dictionary
var waves: Array
var wave_index := 0
var enemy_in_wave := 0

var player_home: Vector2
var enemy_home: Vector2
var time := 0.0


func _ready() -> void:
	player_rect.size = Vector2.ONE * PLAYER_SIZE
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	resized.connect(_layout_fighters)
	_layout_fighters()

	player = Combatant.new("Artificer", GameState.max_hp(), 0, PLAYER_BASE_INTERVAL)
	GameState.player = player
	_apply_staff()

	player.hp_changed.connect(_on_player_hp_changed)
	player.died.connect(_on_player_died)
	_on_player_hp_changed(player.hp, player.max_hp)

	_start_stage()
	_spawn_enemy()

	# The battle keeps running while you edit the staff in the menu.
	GameState.build_changed.connect(_apply_staff)
	GameState.leveled_up.connect(_on_leveled_up)
	GameState.travel_requested.connect(_on_travel_requested)


func _apply_staff() -> void:
	var result := Pipeline.evaluate(GameState.build, GameState.slot_limit)
	if result.is_empty():
		return
	staff = result
	basic = Pipeline.evaluate_basic(GameState.build, GameState.slot_limit)
	player.attack_interval = GameState.attack_interval_for(staff["weight"], PLAYER_BASE_INTERVAL)
	player.set_skill(Pipeline.skill_cooldown(staff))

func _center_x() -> float:
	# custom_minimum_size covers the first frame, before the layout has run.
	return maxf(size.x, custom_minimum_size.x) / 2.0


func _layout_fighters() -> void:
	var cx := _center_x()

	player_home = Vector2(cx - FIGHTER_GAP - player_rect.size.x / 2.0, GROUND_Y - player_rect.size.y)
	player_rect.position.x = player_home.x
	_place_bar(player_bar, player_rect, player_home)

	enemy_home = Vector2(cx + FIGHTER_GAP - enemy_rect.size.x / 2.0, GROUND_Y - enemy_rect.size.y)
	enemy_rect.position.x = enemy_home.x
	_place_bar(enemy_bar, enemy_rect, enemy_home)


# The HP bar sits above its character and is as wide as the character.
func _place_bar(bar: ProgressBar, rect: ColorRect, home: Vector2) -> void:
	bar.size = Vector2(rect.size.x, 14)
	bar.position = Vector2(home.x, home.y - 22.0)
# --- Stages and waves ---

func _start_stage() -> void:
	stage_data = Stages.get_stage(GameState.stage)
	waves = stage_data["waves"]
	wave_index = 0
	enemy_in_wave = 0
	_publish_progress()


func _publish_progress() -> void:
	var total := 0
	var done := 0
	for w in waves.size():
		total += waves[w].size()
		if w < wave_index:
			done += waves[w].size()
	done += enemy_in_wave
	GameState.set_progress(wave_index + 1, waves.size(), float(done) / maxf(total, 1))


# Called after each kill: next enemy, next wave, or phase cleared.
func _advance() -> void:
	enemy_in_wave += 1
	if enemy_in_wave >= waves[wave_index].size():
		enemy_in_wave = 0
		wave_index += 1
		if wave_index >= waves.size():
			_stage_cleared()
			return
		_spawn_popup("Wave %d" % (wave_index + 1), Vector2(_center_x() - 45.0, 12), Color.WHITE, true, 10.0, 1.2)
	_publish_progress()
	_spawn_enemy()


func _stage_cleared() -> void:
	_spawn_popup("PHASE CLEAR!", Vector2(_center_x() - 75.0, 12), Color.GOLD, true, 10.0, 1.6)
	GameState.advance_stage()
	_start_stage()
	_spawn_enemy()


# The player picked a phase on the map.
func _on_travel_requested() -> void:
	_start_stage()
	_spawn_enemy()


func _spawn_enemy() -> void:
	var id: String = waves[wave_index][enemy_in_wave]
	enemy_data = Enemies.scaled(id, stage_data["mult"])
	enemy = Combatant.new(enemy_data["name"], enemy_data["hp"], enemy_data["damage"], enemy_data["interval"])
	enemy.hp_changed.connect(_on_enemy_hp_changed)
	enemy.died.connect(_on_enemy_died)
	_on_enemy_hp_changed(enemy.hp, enemy.max_hp)

	enemy_rect.color = enemy_data["color"]
	enemy_rect.size = Vector2.ONE * float(enemy_data["size"]) * ENEMY_SCALE
	
	_layout_fighters()  # new size, so re-center and re-ground it

	# Slide in and fade in.
	enemy_rect.modulate = Color(1, 1, 1, 0)
	enemy_rect.position.x = enemy_home.x + 30.0
	var tween := create_tween().set_parallel(true)
	tween.tween_property(enemy_rect, "modulate:a", 1.0, 0.25)
	tween.tween_property(enemy_rect, "position:x", enemy_home.x, 0.25)


func _process(delta: float) -> void:
	time += delta
	# Idle bobbing (only the y axis, so it never fights the attack lunge on x).
	player_rect.position.y = player_home.y + sin(time * 3.0) * 2.0
	enemy_rect.position.y = enemy_home.y + sin(time * 3.0 + 1.5) * 2.0

	if player.tick(delta):
		_player_attack()
	if enemy.tick(delta):
		_enemy_attack()


func _player_attack() -> void:
	var resist := GameState.armor_totals()
	var use_skill := player.skill_ready()
	var result: Dictionary = staff if use_skill else basic

	# No igniter means no flame: just a weak shove.
	var dmg: int = 1 if result["mode"] == "fizzle" else result["power"]
	if use_skill:
		dmg = roundi(dmg * GameData.SKILL_DAMAGE_MULT)
		player.start_skill_cooldown()

	var is_crit := randf() < BASE_CRIT_CHANCE
	if is_crit:
		var mult: float = BASE_CRIT_MULT + staff["crit_bonus"] * 2.0
		dmg = roundi(dmg * mult)

	_lunge(player_rect, player_home.x, 1.0)
	_throw_flame(use_skill)
	_flash(enemy_rect)
	if use_skill:
		_spawn_popup(staff["mode"].capitalize() + "!", player_rect.position + Vector2(-20, -34),
			Color.ORANGE_RED, false, 15.0, 0.9)

	var color := Color.WHITE
	if is_crit:
		color = Color.YELLOW
	elif use_skill:
		color = Color.ORANGE_RED
	_spawn_popup(str(dmg) + ("!" if is_crit else ""), enemy_rect.position + Vector2(20, -10),
		color, is_crit or use_skill)
	enemy.take_damage(dmg)

	# Instability is the chance (in %) that this attack backfires.
	if randf() * 100.0 < result["instability"]:
		var backfire := roundi(result["power"] * 0.5 * (1.0 - resist["backfire"]))
		_flash(player_rect)
		if backfire > 0:
			_spawn_popup(str(backfire), player_rect.position + Vector2(20, -10), Color.ORANGE)
			player.take_damage(backfire)

	# Current running through the staff hurts the mage. Grips and armor cut it.
	var zap := roundi(result["shock"] * SHOCK_DAMAGE_FRACTION * (1.0 - resist["shock"]))
	if zap > 0:
		_spawn_popup(str(zap), player_rect.position + Vector2(-10, -10), Color.CYAN)
		player.take_damage(zap)

# The mage throws the flame. Cosmetic only: the damage is already applied.
func _throw_flame(big: bool) -> void:
	var flame := ColorRect.new()
	var s := 14.0 if big else 6.0
	flame.size = Vector2(s, s)
	flame.color = Color.ORANGE_RED if big else Color.ORANGE
	var from := player_rect.position + player_rect.size / 2.0 - flame.size / 2.0
	var to := enemy_rect.position + enemy_rect.size / 2.0 - flame.size / 2.0
	flame.position = from
	add_child(flame)

	var tween := create_tween()
	tween.tween_property(flame, "position", to, 0.15)
	tween.tween_callback(flame.queue_free)

	# Instability is the chance (in %) that the staff backfires.
	if randf() * 100.0 < staff["instability"]:
		var backfire := roundi(player.damage * 0.5)
		_flash(player_rect)
		_spawn_popup(str(backfire), player_rect.position + Vector2(20, -10), Color.ORANGE)
		player.take_damage(backfire)


func _enemy_attack() -> void:
	var taken := maxi(roundi(enemy.damage * (1.0 - GameState.armor_totals()["defense"])), 1)
	_lunge(enemy_rect, enemy_home.x, -1.0)
	_flash(player_rect)
	_spawn_popup(str(taken), player_rect.position + Vector2(20, -10), Color.TOMATO)
	player.take_damage(taken)


# --- Animations ---

func _lunge(rect: ColorRect, home_x: float, direction: float) -> void:
	var tween := create_tween()
	tween.tween_property(rect, "position:x", home_x + 14.0 * direction, 0.06)
	tween.tween_property(rect, "position:x", home_x, 0.10)


func _flash(rect: ColorRect) -> void:
	rect.modulate = Color(2, 2, 2)
	create_tween().tween_property(rect, "modulate", Color.WHITE, 0.15)


func _spawn_death_ghost() -> void:
	var ghost := ColorRect.new()
	ghost.color = enemy_rect.color
	ghost.size = enemy_rect.size
	ghost.position = enemy_rect.position
	ghost.pivot_offset = ghost.size / 2.0
	add_child(ghost)

	var tween := create_tween().set_parallel(true)
	tween.tween_property(ghost, "modulate:a", 0.0, 0.3)
	tween.tween_property(ghost, "scale", Vector2(1.4, 0.2), 0.3)
	tween.chain().tween_callback(ghost.queue_free)


# One function for every floating text: damage, XP, loot, level-up.
func _spawn_popup(text: String, at: Vector2, color := Color.WHITE, big := false,
		rise := 40.0, duration := 0.6) -> void:
	var label := Label.new()
	label.text = text
	label.position = at
	label.modulate = color
	if big:
		label.scale = Vector2(1.5, 1.5)
	add_child(label)

	var tween := create_tween().set_parallel(true)
	tween.tween_property(label, "position:y", at.y - rise, duration)
	tween.tween_property(label, "modulate:a", 0.0, duration)
	tween.chain().tween_callback(label.queue_free)


# --- Signals ---

func _on_player_hp_changed(current: int, maximum: int) -> void:
	player_bar.max_value = maximum
	player_bar.value = current


func _on_enemy_hp_changed(current: int, maximum: int) -> void:
	enemy_bar.max_value = maximum
	enemy_bar.value = current


func _on_enemy_died() -> void:
	_spawn_death_ghost()

	# Rewards pop up to the left of the enemy, stacked downward.
	var reward_pos := enemy_rect.position + Vector2(-110, -40)
	var slot := 0
	GameState.add_xp(enemy_data["xp"])
	_spawn_popup("+%d XP" % enemy_data["xp"], reward_pos + Vector2(0, slot * 18), Color.SKY_BLUE, false, 12.0, 1.2)
	slot += 1
	var gold: int = enemy_data["gold"]
	GameState.add_gold(gold)
	_spawn_popup("+%d gold" % gold, reward_pos + Vector2(0, slot * 18), Color.GOLD, false, 12.0, 1.2)
	slot += 1

	var drops := Loot.roll(enemy_data["drops"])
	for drop in drops:
		GameState.add_item(drop)
		_spawn_popup("+ " + Loot.item_name(drop), reward_pos + Vector2(0, slot * 18), Color.LIGHT_GREEN, false, 12.0, 1.2)
		slot += 1

	player.heal(roundi(player.max_hp * KILL_HEAL_FRACTION))
	_advance()


func _on_player_died() -> void:
	_spawn_popup("DEFEATED", player_rect.position + Vector2(-10, -34), Color.TOMATO, true, 15.0, 1.2)
	player.restore()
	_start_stage()  # back to wave 1 of the current stage
	_spawn_enemy()


func _on_leveled_up(new_level: int) -> void:
	# Bigger HP pool, and a full heal as a reward.
	player.max_hp = GameState.max_hp()
	player.hp = player.max_hp
	_on_player_hp_changed(player.hp, player.max_hp)
	_spawn_popup("LEVEL UP! Lv %d" % new_level, player_rect.position + Vector2(-20, -34),
		Color.GOLD, false, 15.0, 1.2)
