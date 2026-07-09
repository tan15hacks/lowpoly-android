extends CanvasLayer

signal move_changed(direction: Vector2)
signal look_changed(delta: Vector2)
signal jump_pressed
signal record_pressed
signal reset_pressed

@export var joystick_radius: float = 105.0
@export var look_sensitivity: float = 0.0075

var move_touch_id: int = -1
var look_touch_id: int = -1
var move_center: Vector2 = Vector2.ZERO
var move_vector: Vector2 = Vector2.ZERO
var last_look_pos: Vector2 = Vector2.ZERO
var jump_rect: Rect2 = Rect2()
var record_rect: Rect2 = Rect2()
var reset_rect: Rect2 = Rect2()

@onready var joystick_base: Control = $JoystickBase
@onready var joystick_knob: Control = $JoystickBase/JoystickKnob
@onready var jump_panel: ColorRect = $JumpPanel
@onready var record_panel: ColorRect = $RecordPanel
@onready var jump_label: Label = $JumpPanel/Label
@onready var record_label: Label = $RecordPanel/Label

var reset_panel: ColorRect
var reset_label: Label

func _ready() -> void:
	_create_reset_panel()
	get_viewport().size_changed.connect(_position_buttons)
	_position_buttons()
	_reset_joystick()

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_handle_touch(event)
	elif event is InputEventScreenDrag:
		_handle_drag(event)

func _handle_touch(event: InputEventScreenTouch) -> void:
	var screen_size := get_viewport().get_visible_rect().size
	if event.pressed:
		if jump_rect.has_point(event.position):
			jump_pressed.emit()
			return
		if record_rect.has_point(event.position):
			record_pressed.emit()
			return
		if reset_rect.has_point(event.position):
			reset_pressed.emit()
			return
		if event.position.x < screen_size.x * 0.52 and move_touch_id == -1:
			move_touch_id = event.index
			move_center = event.position
			joystick_base.position = move_center - joystick_base.size * 0.5
			joystick_base.visible = true
			_update_joystick(event.position)
		elif event.position.x >= screen_size.x * 0.45 and look_touch_id == -1:
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

func _position_buttons() -> void:
	var screen_size := get_viewport().get_visible_rect().size
	var button_size := Vector2(178, 82)
	var pad := 30.0
	jump_rect = Rect2(Vector2(screen_size.x - button_size.x - pad, screen_size.y - button_size.y - 50), button_size)
	record_rect = Rect2(Vector2(screen_size.x - button_size.x - pad, screen_size.y - (button_size.y * 2.0) - 82), button_size)
	reset_rect = Rect2(Vector2(screen_size.x - button_size.x - pad, screen_size.y - (button_size.y * 3.0) - 114), button_size)
	_apply_panel_rect(jump_panel, jump_label, jump_rect, "JUMP")
	_apply_panel_rect(record_panel, record_label, record_rect, "REC")
	_apply_panel_rect(reset_panel, reset_label, reset_rect, "RESET")

func _apply_panel_rect(panel: ColorRect, label: Label, rect: Rect2, text: String) -> void:
	panel.position = rect.position
	panel.size = rect.size
	panel.color = Color(0.03, 0.04, 0.05, 0.78)
	label.position = Vector2.ZERO
	label.size = rect.size
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

func _create_reset_panel() -> void:
	reset_panel = ColorRect.new()
	reset_panel.name = "ResetPanel"
	add_child(reset_panel)
	reset_label = Label.new()
	reset_label.name = "Label"
	reset_panel.add_child(reset_label)
