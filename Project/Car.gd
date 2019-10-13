extends KinematicBody2D
 
# Porsche Boxter S specific variables. Can be changed to arrays to account for more than one car:
var gearRatios = [3.82, 2.20, 1.52, 1.22, 1.02, 0.84] # gk
var currentGear = 0
var numberOfGears = 6
var G = 3.44 # Final drive ratio
var wheelRadius = 0.3186 # rw
var omegaRedline = 7200 # Highest possible rpm.
var currentOmega = 1000 # RPM
var Cd = 0.31 # Drag-coefficient
var area = 1.94 # Frontal area of Porsche Boxter S
var mu = 0.015 # Coefficient of rolling friction
var Te = 0 # Torque engine
var mass = 1393 # Mass in kg
var currentTopSpeedRedline = 0 # Top speed without friction or drag
var currentTopSpeed = 0 # "Real" top speed
var airDensity = 1.2 # kg / m^3
var b = 0 # Slope of torque-curve
var d = 0 # y = kx + m, this is the m of the torque-curve
var gravitation = 9.82 # m / s^2
var Fd = 0 # Drag-force
var Fr = 0 # Friction-force
var Tw = 0 # Torque wheel
var totalForce = 0
var currentAcceleration = 0
var currentVelocity = 0
var Pe = 0 # Power of the engine
var we = 0 # Rotationspeed of the engine
var Teb = 0 # Torque engine braking
var muBraking = 0.74 # Engine braking coefficient
var accelerationBraking = -5.0 # m/s^2. Calculated with existing data and a = -v0^2 / 2x. Though estimated for he car.
 
func determineTorque(rpm):
	if (rpm <= 1000):
		Te = 220
		b = 0
		d = 220
	elif (rpm < 4600):
		Te = 0.025 * rpm + 195
		b = 0.025
		d = 195
	else:
		Te = -0.032 * rpm + 457.2
		b = -0.032
		d = 457.2
 
func determineTopSpeedRedline(currentGearRatio):
	currentTopSpeedRedline = (2 * PI * wheelRadius * omegaRedline) / (60 * currentGearRatio * G)
   
func determineTopSpeed(currentGearRatio):
	determineTorque(currentOmega)
# Float variablerna strular och avrundas till 0...
	var c1 = -(1 / 2) * (Cd * airDensity * area) / mass
	var c2 = (60 * (currentGearRatio * currentGearRatio) * (G * G) * b) / (2 * PI * mass * (wheelRadius * wheelRadius))
	var c3 = ((currentGearRatio * G * d) / (mass * wheelRadius)) - (mu * gravitation)
	currentTopSpeed = min((-c2 + sqrt((c2 * c2) - 4 * (c1 * c3))), (-c2 - sqrt((c2 * c2) - 4 * (c1 * c3)))) / (2 * c1)
# Keep an eye on this... Might be max instead of min...
   
func determineDrag(currentVelocity):
	Fd = 0.5 * Cd * airDensity * (currentVelocity * currentVelocity) * area 
 
func determineFriction():
	Fr = mu * mass * gravitation * cos(0)
   
func determineTw(currentGearRatio):
	determineTorque(currentOmega)
	Tw = Te * currentGearRatio * G
   
func determineTotalForce(currentGearRatio, currentVelocity):
	determineTw(currentGearRatio)
	determineFriction()
	determineDrag(currentVelocity)
	totalForce += (Tw / wheelRadius) - Fr - Fd
	print("Tot F : ", totalForce)
   
func determineAcceleration(currentGearRatio, velocityInput):
	determineTotalForce(currentGearRatio, velocityInput)
	currentAcceleration = totalForce / mass
   
func determineWe(rpm):
	we = (2 * PI * rpm) / 60
   
func determineEnginePower(rpm):
	determineTorque(rpm)
	determineWe(rpm)
	Pe = Te * we # Poweer of the engine = Torque of the engine * rotational speed of engine
   
func determineOmegaE(velocity, currentGearRatio):
	currentOmega = (velocity * 60 * currentGearRatio * G) / (2 * PI * (wheelRadius * wheelRadius))
	if (currentOmega > 7200):
		currentOmega = 7200
 
func determineCurrentVelocity(rpm, currentGearRatio, velocity, delta):
	if (currentVelocity > currentTopSpeedRedline):
		currentVelocity = currentTopSpeedRedline
		currentAcceleration = 0
	else:
		determineAcceleration(currentGearRatio, velocity)
		currentVelocity = currentVelocity + currentAcceleration * delta
       
	determineOmegaE(currentVelocity, currentGearRatio)
    #currentVelocity = (wheelRadius * 2 * PI * rpm) / (60 * currentGearRatio * G)
   
func rpmAfterShift(currentGearRatio, newGearRatio):
	currentOmega = currentOmega * (newGearRatio / currentGearRatio)
	if (newGearRatio < currentGearRatio):
		currentGear += 1
	else:
		currentGear -= 1
   
func determineEngingeBraking(rpm):
	Teb = muBraking * (rpm / 60)
 
# Old variables:
var wheelDist = 70
var angle = 15
var power = 800
var friction = -0.9
var drag = -0.001
var breaking = - 450
var speedReverse = 250
 
var acceleration = Vector2.ZERO
var velocity = Vector2.ZERO
var steerAngle
 
func _physics_process(delta):
	acceleration = Vector2.ZERO
	get_input(delta)
    # apply_friction()
	calculate_steering(delta)
	velocity += acceleration * delta
	
	determineEngingeBraking(currentOmega)
	determineTopSpeedRedline(gearRatios[currentGear])
	print("Current acc: ", currentAcceleration)
	print("Current velocity: ", currentVelocity)
	print("Current RPM: ", currentOmega)
	print("Engine braking: ", Teb)
	print("Current gear: ", currentGear)
	print("Current top speed: ", currentTopSpeedRedline)
	print("FD : " , Fd)
	print("Ff : " , Fr ) 
	velocity = move_and_slide(velocity)
	print("----- ", global_position, " -----")
 
func apply_friction():
#Slow the car down (add friction- and drag force)
	if velocity.length() < 5:
		velocity = Vector2.ZERO
	var frictionForce = velocity * friction
	var dragForce = velocity * velocity.length() * drag
	acceleration += frictionForce #+ dragForce
 
func get_input(delta):
#Turn or not turning
	var turn = 0
	if Input.is_action_pressed("ui_right"):
		turn += 1
	if Input.is_action_pressed("ui_left"):
		turn -= 1
	steerAngle = turn * deg2rad(angle)
   
#Accalerations forward and for breaking
	if Input.is_action_pressed("ui_up"):
		determineCurrentVelocity(currentOmega, gearRatios[currentGear], currentVelocity, delta)
        #determineAcceleration(gearRatios[0], currentVelocity)
		acceleration = transform.x * currentAcceleration #transform.x * power
		determineTopSpeedRedline(gearRatios[currentGear])
		if (currentOmega <= 7200 && currentVelocity <= currentTopSpeedRedline):
			currentOmega += 150
	if Input.is_action_pressed("ui_down"):
		acceleration = transform.x * accelerationBraking
	
	if(currentOmega > 1000):
        # Fake engine braking...
		currentOmega -= 150
		determineCurrentVelocity(currentOmega, gearRatios[currentGear], currentVelocity, delta)
	else:
		currentOmega = 1000
   
	if Input.is_action_just_pressed("ui_select"):
		if (currentGear < 5):
			rpmAfterShift(gearRatios[currentGear], gearRatios[currentGear + 1])
			determineTopSpeedRedline(gearRatios[currentGear])
	if Input.is_action_just_pressed("ui_cancel"):
		if (currentGear > 0):
			rpmAfterShift(gearRatios[currentGear], gearRatios[currentGear - 1])
			determineTopSpeedRedline(gearRatios[currentGear])
	
	#print(" Acceleration : ", acceleration )
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