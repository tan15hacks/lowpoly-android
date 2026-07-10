extends Node
class_name ProceduralHumanoidAnimator

@export var run_reference_speed: float = 5.6
@export var animation_speed: float = 8.0
@export var arm_down_angle: float = 1.30

var skeleton: Skeleton3D
var bone_indices: Dictionary = {}
var base_rotations: Dictionary = {}
var base_positions: Dictionary = {}
var movement_blend: float = 0.0
var air_blend: float = 0.0
var cycle: float = 0.0
var elapsed: float = 0.0
var initialized: bool = false

func setup(character_root: Node) -> bool:
	skeleton = _find_skeleton(character_root)
	if skeleton == null:
		print("ProceduralHumanoidAnimator: no Skeleton3D found.")
		return false

	_map_bones()
	_cache_base_pose()
	initialized = not bone_indices.is_empty()

	if initialized:
		print("ProceduralHumanoidAnimator mapped bones: ", bone_indices)
		_apply_animation_pose(0.0, 0.0, true)
	else:
		print("ProceduralHumanoidAnimator: no compatible humanoid bones found.")

	return initialized

func update_animation(delta: float, horizontal_speed: float, vertical_velocity: float, on_floor: bool) -> void:
	if not initialized or skeleton == null:
		return

	elapsed += delta
	var target_movement: float = clamp(horizontal_speed / max(run_reference_speed, 0.01), 0.0, 1.0)
	movement_blend = move_toward(movement_blend, target_movement, delta * 6.5)
	air_blend = move_toward(air_blend, 0.0 if on_floor else 1.0, delta * 10.0)
	cycle += delta * lerp(2.0, animation_speed, movement_blend)
	_apply_animation_pose(vertical_velocity, delta, on_floor)

func _apply_animation_pose(vertical_velocity: float, _delta: float, on_floor: bool) -> void:
	var stride: float = sin(cycle)
	var opposite_stride: float = sin(cycle + PI)
	var breathing: float = sin(elapsed * 2.2)
	var run_weight: float = movement_blend * (1.0 - air_blend)
	var jump_weight: float = air_blend

	var hips_bob: float = abs(sin(cycle * 2.0)) * 0.035 * run_weight
	hips_bob += breathing * 0.008 * (1.0 - movement_blend) * (1.0 - jump_weight)
	_set_position("hips", Vector3(0.0, hips_bob, 0.0))

	var hips_yaw: float = stride * 0.10 * run_weight
	_set_rotation("hips", Vector3(0.0, hips_yaw, 0.0))

	var spine_pitch: float = -0.10 * run_weight + breathing * 0.025 * (1.0 - movement_blend)
	spine_pitch = lerp(spine_pitch, -0.08, jump_weight)
	_set_rotation("spine", Vector3(spine_pitch, -hips_yaw * 0.45, 0.0))
	_set_rotation("chest", Vector3(breathing * 0.018 * (1.0 - movement_blend), -hips_yaw * 0.35, 0.0))
	_set_rotation("neck", Vector3(-spine_pitch * 0.25, 0.0, 0.0))
	_set_rotation("head", Vector3(-spine_pitch * 0.20, 0.0, 0.0))

	var left_arm_swing: float = opposite_stride * 0.55 * run_weight
	var right_arm_swing: float = stride * 0.55 * run_weight
	left_arm_swing = lerp(left_arm_swing, -0.38, jump_weight)
	right_arm_swing = lerp(right_arm_swing, -0.38, jump_weight)

	_set_compound_rotation("left_upper_arm", Vector3(left_arm_swing, 0.0, arm_down_angle))
	_set_compound_rotation("right_upper_arm", Vector3(right_arm_swing, 0.0, -arm_down_angle))

	var left_elbow: float = 0.18 + max(0.0, stride) * 0.32 * run_weight
	var right_elbow: float = 0.18 + max(0.0, opposite_stride) * 0.32 * run_weight
	left_elbow = lerp(left_elbow, 0.38, jump_weight)
	right_elbow = lerp(right_elbow, 0.38, jump_weight)
	_set_rotation("left_forearm", Vector3(left_elbow, 0.0, 0.0))
	_set_rotation("right_forearm", Vector3(right_elbow, 0.0, 0.0))

	var left_leg_swing: float = stride * 0.62 * run_weight
	var right_leg_swing: float = opposite_stride * 0.62 * run_weight
	var jump_thigh: float = 0.28 if vertical_velocity >= -0.2 else 0.18
	left_leg_swing = lerp(left_leg_swing, jump_thigh, jump_weight)
	right_leg_swing = lerp(right_leg_swing, jump_thigh, jump_weight)
	_set_rotation("left_thigh", Vector3(left_leg_swing, 0.0, 0.0))
	_set_rotation("right_thigh", Vector3(right_leg_swing, 0.0, 0.0))

	var left_knee: float = max(0.0, -stride) * 0.72 * run_weight
	var right_knee: float = max(0.0, -opposite_stride) * 0.72 * run_weight
	var jump_knee: float = 0.52 if not on_floor else 0.0
	left_knee = lerp(left_knee, jump_knee, jump_weight)
	right_knee = lerp(right_knee, jump_knee, jump_weight)
	_set_rotation("left_shin", Vector3(left_knee, 0.0, 0.0))
	_set_rotation("right_shin", Vector3(right_knee, 0.0, 0.0))

	_set_rotation("left_foot", Vector3(-left_leg_swing * 0.22, 0.0, 0.0))
	_set_rotation("right_foot", Vector3(-right_leg_swing * 0.22, 0.0, 0.0))

func _map_bones() -> void:
	bone_indices.clear()
	_map_role("hips", ["hips", "pelvis"], [])
	_map_role("spine", ["spine", "spine1", "lowerchest"], ["spine2", "spine3", "upperchest"])
	_map_role("chest", ["upperchest", "chest", "spine2", "spine3"], [])
	_map_role("neck", ["neck"], [])
	_map_role("head", ["head"], ["headtop", "headend"])

	_map_role("left_upper_arm", ["leftupperarm", "leftarm", "upperarml", "lupperarm", "armleft"], ["forearm", "lowerarm", "hand"])
	_map_role("right_upper_arm", ["rightupperarm", "rightarm", "upperarmr", "rupperarm", "armright"], ["forearm", "lowerarm", "hand"])
	_map_role("left_forearm", ["leftforearm", "leftlowerarm", "forearml", "lowerarml", "lforearm"], ["hand"])
	_map_role("right_forearm", ["rightforearm", "rightlowerarm", "forearmr", "lowerarmr", "rforearm"], ["hand"])

	_map_role("left_thigh", ["leftupleg", "leftthigh", "upperlegl", "thighl", "lthigh"], ["lowerleg", "calf", "shin"])
	_map_role("right_thigh", ["rightupleg", "rightthigh", "upperlegr", "thighr", "rthigh"], ["lowerleg", "calf", "shin"])
	_map_role("left_shin", ["leftlowerleg", "leftleg", "lowerlegl", "calfl", "shinl"], ["upleg", "upperleg", "thigh", "foot"])
	_map_role("right_shin", ["rightlowerleg", "rightleg", "lowerlegr", "calfr", "shinr"], ["upleg", "upperleg", "thigh", "foot"])
	_map_role("left_foot", ["leftfoot", "footl", "lfoot"], ["toe"])
	_map_role("right_foot", ["rightfoot", "footr", "rfoot"], ["toe"])

	if bone_indices.has("spine") and bone_indices.has("chest") and bone_indices["spine"] == bone_indices["chest"]:
		bone_indices.erase("chest")

func _map_role(role: String, aliases: Array[String], excludes: Array[String]) -> void:
	var bone_index: int = _find_best_bone(aliases, excludes)
	if bone_index >= 0:
		bone_indices[role] = bone_index

func _find_best_bone(aliases: Array[String], excludes: Array[String]) -> int:
	var best_index: int = -1
	var best_score: int = -1
	for index in range(skeleton.get_bone_count()):
		var normalized_name: String = _normalize_name(skeleton.get_bone_name(index))
		var excluded: bool = false
		for excluded_token in excludes:
			if _normalize_name(excluded_token) in normalized_name:
				excluded = true
				break
		if excluded:
			continue

		for alias in aliases:
			var normalized_alias: String = _normalize_name(alias)
			if normalized_alias in normalized_name:
				var score: int = normalized_alias.length()
				if normalized_name == normalized_alias:
					score += 100
				if score > best_score:
					best_score = score
					best_index = index
	return best_index

func _cache_base_pose() -> void:
	base_rotations.clear()
	base_positions.clear()
	for role_variant in bone_indices.keys():
		var role: String = String(role_variant)
		var index: int = int(bone_indices[role])
		base_rotations[role] = skeleton.get_bone_pose_rotation(index)
		base_positions[role] = skeleton.get_bone_pose_position(index)

func _set_rotation(role: String, euler_delta: Vector3) -> void:
	if not bone_indices.has(role) or not base_rotations.has(role):
		return
	var index: int = int(bone_indices[role])
	var base_rotation: Quaternion = base_rotations[role]
	var delta_rotation: Quaternion = Quaternion.from_euler(euler_delta)
	skeleton.set_bone_pose_rotation(index, base_rotation * delta_rotation)

func _set_compound_rotation(role: String, euler_delta: Vector3) -> void:
	_set_rotation(role, euler_delta)

func _set_position(role: String, offset: Vector3) -> void:
	if not bone_indices.has(role) or not base_positions.has(role):
		return
	var index: int = int(bone_indices[role])
	var base_position: Vector3 = base_positions[role]
	skeleton.set_bone_pose_position(index, base_position + offset)

func _find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node as Skeleton3D
	for child in node.get_children():
		var found: Skeleton3D = _find_skeleton(child)
		if found != null:
			return found
	return null

func _normalize_name(value: String) -> String:
	return value.to_lower().replace("_", "").replace("-", "").replace(".", "").replace(":", "").replace(" ", "")
