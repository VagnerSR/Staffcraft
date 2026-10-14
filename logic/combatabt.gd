class_name Combatant
extends RefCounted

signal hp_changed(current: int, maximum: int)
signal died

var display_name: String
var max_hp: int
var hp: int
var damage: int
var attack_interval: float  # seconds between attacks
var _attack_timer := 0.0

# The skill replaces a basic attack whenever its cooldown is done.
var skill_cooldown := 0.0  # total seconds. 0 means no skill.
var skill_timer := 0.0     # seconds left


func _init(p_name: String, p_max_hp: int, p_damage: int, p_interval: float) -> void:
	display_name = p_name
	max_hp = p_max_hp
	hp = p_max_hp
	damage = p_damage
	attack_interval = p_interval


func is_dead() -> bool:
	return hp <= 0


func take_damage(amount: int) -> void:
	hp = maxi(hp - amount, 0)
	hp_changed.emit(hp, max_hp)
	if hp == 0:
		died.emit()


func heal(amount: int) -> void:
	if hp <= 0:
		return
	hp = mini(hp + amount, max_hp)
	hp_changed.emit(hp, max_hp)


func restore() -> void:
	hp = max_hp
	hp_changed.emit(hp, max_hp)
	skill_timer = 0.0


func has_skill() -> bool:
	return skill_cooldown > 0.0


func skill_ready() -> bool:
	return has_skill() and skill_timer <= 0.0


func start_skill_cooldown() -> void:
	skill_timer = skill_cooldown


# Called whenever the staff changes. A brand new skill starts ready.
func set_skill(p_cooldown: float) -> void:
	skill_cooldown = p_cooldown
	skill_timer = minf(skill_timer, skill_cooldown)


# Advance time. Returns true when this combatant is ready to attack.
func tick(delta: float) -> bool:
	skill_timer = maxf(skill_timer - delta, 0.0)
	_attack_timer += delta
	if _attack_timer >= attack_interval:
		_attack_timer -= attack_interval
		return true
	return false
