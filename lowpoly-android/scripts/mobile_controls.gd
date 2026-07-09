extends CanvasLayer

signal move_changed(direction: Vector2)
signal look_changed(delta: Vector2)
signal jump_pressed

@export var joystick_radius: float = 95.0
@export var look_sensitivity: float = 0.009

var move_touch_id: int = -1
var look_touch_id: int = -1
var move_center: Vector2 = Vector2.ZERO
var move_vector: Vector2 = Vector2.ZERO
var last_look_pos: Vector2 = Vector2.ZERO

@onready var joystick_base: Control = $JoystickBase
@onready var joystick_knob: Control = $JoystickBase/JoystickKnob
@onready var jump_button: TouchScreenButton = $JumpButton

func _ready() -> void:
	jump_button.pressed.connect(func() -> void:
		jump_pressed.emit()
	)
	_reset_joystick()

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_handle_touch(event)
	elif event is InputEventScreenDrag:
		_handle_drag(event)

func _handle_touch(event: InputEventScreenTouch) -> void:
	var screen_size := get_viewport().get_visible_rect().size
	if event.pressed:
		if event.position.x < screen_size.x * 0.5 and move_touch_id == -1:
			move_touch_id = event.index
			move_center = event.position
			joystick_base.position = move_center - joystick_base.size * 0.5
			joystick_base.visible = true
			_update_joystick(event.position)
		elif event.position.x >= screen_size.x * 0.5 and look_touch_id == -1:
			look_touch_id = event.index
			last_look_pos = event.position
	else:
		if event.index == move_touch_id:
			move_touch_id = -1
			move_vector = Vector2.ZERO
			move_changed.emit(move_vector)
			_reset_joystick()
		elif event.index == look_touch_id:
			look_touch_id = -1

func _handle_drag(event: InputEventScreenDrag) -> void:
	if event.index == move_touch_id:
		_update_joystick(event.position)
	elif event.index == look_touch_id:
		look_changed.emit(event.relative * look_sensitivity)
		last_look_pos = event.position

func _update_joystick(pos: Vector2) -> void:
	var offset := pos - move_center
	if offset.length() > joystick_radius:
		offset = offset.normalized() * joystick_radius
	move_vector = offset / joystick_radius
	joystick_knob.position = joystick_base.size * 0.5 + offset - joystick_knob.size * 0.5
	move_changed.emit(move_vector)

func _reset_joystick() -> void:
	joystick_base.visible = false
	joystick_knob.position = joystick_base.size * 0.5 - joystick_knob.size * 0.5
