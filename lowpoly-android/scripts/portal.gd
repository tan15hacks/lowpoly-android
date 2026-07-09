extends Area3D

signal entered

@export var spin_speed: float = 1.8
var active: bool = false

@onready var visual: Node3D = $Visual

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	set_active(false)

func _process(delta: float) -> void:
	if active:
		visual.rotate_y(spin_speed * delta)

func set_active(value: bool) -> void:
	active = value
	visible = value
	monitoring = value

func _on_body_entered(body: Node3D) -> void:
	if active and body is CharacterBody3D:
		entered.emit()
