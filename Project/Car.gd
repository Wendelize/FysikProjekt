extends KinematicBody2D

var wheelDist = 100
var angle = 15

var dir = Vector2.ZERO
var steerAngle

func _physics_process(delta):
	get_input()
	calculate_steering(delta)
	dir = move_and_slide(dir)

func get_input():
	var turn = 0
	if Input.is_action_pressed("steer_right"):
		turn += 1
	if Input.is_action_pressed("steer_left"):
		turn -= 1
	steerAngle = turn * deg2rad(angle)
	dir = Vector2.ZERO
	if Input.is_action_pressed("accalerate"):
		dir = transform.x * 500;

func calculate_steering(delta):
	var rearWheel = position - transform.x * wheelDist / 2.0
	var frontWheel = position + transform.x * wheelDist / 2.0
	rearWheel += dir * delta
	frontWheel += dir.rotated(angle) * delta
	var newDir = (frontWheel - rearWheel).normalized()
	dir = newDir * dir.length()
	rotation = newDir.angle()