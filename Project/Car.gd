extends KinematicBody2D

var wheelDist = 70
var angle = 15
var power = 800
var friction = -0.9
var drag = -0.001
var breaking = - 450
var speedReverse = 250

# new booiiis
var Cd = -0.31
var area = 1.94
var mass = 1393
var wheelRatio = 0.3186
var my = -0.015
var grav = 9.82
var rpm = 1000
var we = 0
var Te = 220
var Tw = 0
var Ft
var Fd
var Ff
var Ftot
var time = 0

var acceleration = Vector2.ZERO
var velocity = Vector2.ZERO
var steerAngle

func _physics_process(delta):
	acceleration = Vector2.ZERO
	get_input(delta)
	apply_friction()
	calculate_steering(delta)
	print("Time : " , time )
	velocity += acceleration * time
	velocity = move_and_slide(velocity)
	print("Velocity (km/h): " ,velocity.length() * 3.6)


func apply_friction():
	#Slow the car down (add friction- and drag force)
	if velocity.length() < 5:
		velocity = Vector2.ZERO
	Ff = velocity.normalized() * my * grav  
	Fd = velocity.normalized() * 1/2 * 1.22* area * Cd * (velocity.length()*velocity.length()) / mass
	acceleration +=  Fd + Ff
	#print("f = ", Ff, "d = " , Fd)

func get_input(delta):
	#Turn or not turning
	var turn = 0
	if Input.is_action_pressed("ui_right"):
		turn = 1
	if Input.is_action_pressed("ui_left"):
		turn = -1
	steerAngle = turn * deg2rad(angle)
	
	#Calculations for Ft, Tw, Te, rpm
	rpm = (velocity.length() * 60 * 3.82 * 3.44) / (2 * PI * wheelRatio)
	print("RPM: ", rpm)
	if(rpm <= 1000):
		rpm = 1000
		Te = 220
	elif(rpm < 4600):
		Te = 0.025 * rpm + 195
	else:
		if(rpm > 7600):
			rpm = 7600
		Te = -0.032 * rpm + 457.2
		
	we = (2*PI*rpm)/60
	
	Tw = Te * 3.2 * 3.44
	Ft = Tw / wheelRatio
	#print("Te : " , Te)
	print("rpm : ",rpm)
	print("Velocity (m/s) : ", velocity.length())
	print("Ft : " , Ft)
	
	#Accalerations forward and for breaking
	if Input.is_action_pressed("ui_up"):
		time += delta
		acceleration += (Ft/mass) * transform.x
	else:
		time = 0

	if Input.is_action_pressed("ui_down"):
		acceleration = transform.x * breaking
		
	print(" Acceleration : ", acceleration )
	#Animations
	if velocity.length() > 0:
		$AnimatedSprite.play("Forward")
	if velocity.length() < 0:
		$AnimatedSprite.play("Backwards")
	if velocity.length() == 0:
		$AnimatedSprite.stop()
	if turn > 0:
		$AnimatedSprite.play("Turn")
		$AnimatedSprite.flip_h = false
	if turn < 0:
		$AnimatedSprite.play("Turn")
		$AnimatedSprite.flip_h = true


func calculate_steering(delta):
	#Location of front- & rear wheel
	var rearWheel = position - transform.x * wheelDist / 2.0
	var frontWheel = position + transform.x * wheelDist / 2.0
	rearWheel += velocity * delta
	frontWheel += velocity.rotated(steerAngle) * delta
	
	#Calculating our new dir
	var newDir = (frontWheel - rearWheel).normalized()
	var d = newDir.dot(velocity.normalized())
	if d > 0:
		velocity = newDir * velocity.length()
	if d < 0:
		velocity -newDir *min(velocity.length(), speedReverse)
	rotation = newDir.angle()