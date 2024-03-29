extends KinematicBody2D

# Porsche Boxter S specific variables. Can be changed to arrays to account for more than one car:
var gearRatios = [3.82, 2.20, 1.52, 1.22, 1.02, 0.84] # gk
var currentGear = 0
var numberOfGears = 6
var G = 3.44 # Final drive ratio
var wheelRadius = 0.3186 # rw
var omegaRedline = 7200 # Highest possible rpm.
var currentOmega = 0 # RPM, 0 at start
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
var accelerationBraking = -10.4 # m/s^2. Calculated with existing data and a = -v0^2 / 2x. Though estimated for he car.
var maxBackingSpeed = -20

# ATT FIXA:
# * determineTopSpeed()

func determineTorque(rpm): #OK!
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
		
func determineTopSpeed(currentGearRatio, currentOmega): #INTE OK!
	determineTorque(currentOmega)
	# Float variablerna strular och avrundas till 0...
	var c1 = -0.5 * (Cd * airDensity * area) / mass
	var c2 = (60 * (currentGearRatio * currentGearRatio) * (G * G) * b) / (2 * PI * mass * (wheelRadius * wheelRadius))
	var c3 = ((currentGearRatio * G * d) / (mass * wheelRadius)) - (mu * gravitation)
	
	var root = sqrt((c2 * c2) - 4 * (c1 * c3))
	var speed1 = (-c2 + root) / (2 * c1)
	var speed2 = (-c2 - root) / (2 * c1)
	
	currentTopSpeed = max(speed1, speed2)
	
	# currentTopSpeed = max(((-c2 + sqrt((c2 * c2) - 4 * (c1 * c3))) / (2 * c1)), ((-c2 - sqrt((c2 * c2) - 4 * (c1 * c3))) / (2 * c1)))
	# Keep an eye on this... Might be max instead of min...
	
func determineTopSpeedRedline(currentGearRatio): #OK!
	currentTopSpeedRedline = (2 * PI * wheelRadius * omegaRedline) / (60 * currentGearRatio * G)
	
func determineDrag(currentVelocity): #OK!
	Fd = 0.5 * Cd * airDensity * (currentVelocity * currentVelocity) * area

func determineFriction(): #OK!
	Fr = mu * mass * gravitation * cos(0)
	
func determineTw(currentGearRatio): #SEEMS OK, DEPENDS ON RPM
	determineTorque(currentOmega)
	Tw = Te * currentGearRatio * G
	
func determineTotalForce(currentGearRatio, currentVelocity): #OK!
	determineTw(currentGearRatio)
	determineFriction()
	determineDrag(currentVelocity)
	totalForce = (Tw / wheelRadius) - Fr - Fd
	
func determineAcceleration(currentGearRatio, velocityInput): #SEEMS OK, DEPENDS ON RPM DOE?
	determineTotalForce(currentGearRatio, velocityInput)
	currentAcceleration = totalForce / mass
	
func determineWe(rpm): #OK!
	we = (2 * PI * rpm) / 60
	
func determineEnginePower(rpm): #OK!
	determineTorque(rpm)
	determineWe(rpm)
	Pe = Te * we # Power of the engine = Torque of the engine * rotational speed of engine
	
func determineOmegaE(velocity, currentGearRatio): #OK!
	currentOmega = (abs(velocity) * 60 * currentGearRatio * G) / (2 * PI * wheelRadius)

func determineCurrentVelocity(rpm, currentGearRatio): #OK!
	currentVelocity = (wheelRadius * 2 * PI * rpm) / (60 * currentGearRatio * G)
	determineAcceleration(currentGearRatio, currentVelocity)
	
func rpmAfterShift(currentGearRatio, newGearRatio): #OK!
	currentOmega = currentOmega * (newGearRatio / currentGearRatio)
	if (newGearRatio < currentGearRatio):
		currentGear += 1
	elif (currentOmega < 1000):
		print("TOO LOW OMEGA FOR VEXLING, FUCK YOU, NO VEXLING! KEEP OMEGA AND WEXEL")
		currentGear -= 1
	
func determineEngingeBraking(rpm): #OK!
	Teb = muBraking * (rpm / 60)
	
# TESTING:
func determineGas(delta, input):
	determineTopSpeedRedline(gearRatios[currentGear])
	if (currentGear == 5):
		determineTopSpeed(gearRatios[5], currentOmega)
		currentTopSpeedRedline = currentTopSpeed # In higher gears, aka 5th gear, we use the top speed with drag.
		#print(currentTopSpeedRedline)
	
	if (currentVelocity < currentTopSpeedRedline && input == "ui_up"):
		if(currentVelocity < 0):
			currentAcceleration = -accelerationBraking
		currentVelocity = currentVelocity + currentAcceleration * delta # Acceleration
		determineOmegaE(currentVelocity, gearRatios[currentGear])
		determineAcceleration(gearRatios[currentGear], currentVelocity)
		
	elif (input == "ui_down"):
		determineEngingeBraking(currentOmega) # The engine braking depend on the rpm
		var brakeForce = -Teb / wheelRadius # Like the torque forward of the engine but opposite :) 
		determineDrag(currentVelocity) # Drag affects the braking as well and needs to be updated based on currentVelocity
		var engineBraking = (brakeForce - Fr - Fd) / mass # acceleration of engine braking
		if(currentVelocity > maxBackingSpeed):
			currentAcceleration = accelerationBraking
			currentVelocity = currentVelocity + (currentAcceleration - engineBraking) * delta # Active braking + engine braking
			determineOmegaE(currentVelocity, gearRatios[currentGear])
			determineAcceleration(gearRatios[currentGear], currentVelocity)
		
	else:
		determineEngingeBraking(currentOmega) # The engine braking depend on the rpm
		var brakeForce = -Teb / wheelRadius # Like the torque forward of the engine but opposite :) 
		determineDrag(currentVelocity) # Drag affects the braking as well and needs to be updated based on currentVelocity
		var engineBraking = (brakeForce - Fr - Fd) / mass # acceleration of engine braking
		if (currentVelocity > 0):
			currentVelocity = currentVelocity + engineBraking * delta # Enginebraking
			determineOmegaE(currentVelocity, gearRatios[currentGear])
			determineAcceleration(gearRatios[currentGear], currentVelocity)
		elif (currentVelocity < 0):
			currentVelocity = currentVelocity - engineBraking * delta # Enginebraking
			determineOmegaE(currentVelocity, gearRatios[currentGear])
			determineAcceleration(gearRatios[currentGear], currentVelocity)
		#print("engineBraking: ", engineBraking)
		
	

# Old variables:
var wheelDist = 70
var angle = 15
var power = 800
var friction = -0.9
var drag = -0.001
var breaking = - 450
var speedReverse = 250
var tractionFast = 0.001
var tractionSlow = 0.7
var slipSpeed = 30
var newVelocity = Vector2.ZERO
var acceleration = Vector2.ZERO
var velocity = Vector2.ZERO
var steerAngle

func _physics_process(delta):
	acceleration = Vector2.ZERO
	get_input(delta)
	calculate_steering(delta)
	#get_node(".../CanvasLayer/label").set_text("Velo: " + str(currentVelocity))
	#get_tree().get_root().get_node("CanvasLayer").set_text(str(currentVelocity))
	#print("v = ", currentVelocity, " acc = ", currentAcceleration, " rpm = ", currentOmega, " gear = ", currentGear + 1)
	print(velocity.normalized().length())
	if(velocity.normalized().length() < 1):
		velocity = move_and_slide(8 * currentVelocity * transform.x)# * 12 for more realistic movement in the scale of the sprites
	else: 
		velocity = move_and_slide(8 * currentVelocity * velocity.normalized())# * 12 for more realistic movement in the scale of the sprites
func get_input(delta): #FIX
	#Turn or not turning
	var turn = 0
	if Input.is_action_pressed("ui_right"):
		turn += 1
	if Input.is_action_pressed("ui_left"):
		turn -= 1
	steerAngle = turn * deg2rad(angle)
	
	#Accalerations forward and for breaking
	if Input.is_action_pressed("ui_up"):
		if (currentOmega == 0): # start of engine
			currentOmega = 1000
		determineGas(delta, "ui_up")	
	elif Input.is_action_pressed("ui_down"):
		determineGas(delta, "ui_down")
	else:
		determineGas(delta, "")
	
	# Gear up or down
	if Input.is_action_just_pressed("ui_select"):
		if (currentGear < 5):
			rpmAfterShift(gearRatios[currentGear], gearRatios[currentGear + 1])
			determineTopSpeedRedline(gearRatios[currentGear])
	if Input.is_action_just_pressed("ui_cancel"):
		if (currentGear > 0):
			rpmAfterShift(gearRatios[currentGear], gearRatios[currentGear - 1])
			currentGear = currentGear - 1
			determineTopSpeedRedline(gearRatios[currentGear])
		
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
	# Location of front- & rear wheel
	var rearWheel = position - transform.x * wheelDist / 2.0
	var frontWheel = position + transform.x * wheelDist / 2.0
	rearWheel += velocity * delta
	frontWheel += velocity.rotated(steerAngle) * delta
	
	# Calculating our new velocity
	newVelocity = (frontWheel - rearWheel).normalized()

	var traction = tractionSlow
	if(currentVelocity > slipSpeed):

		traction = tractionFast

	var d = newVelocity.dot(velocity.normalized())
	if d > 0:
		velocity = velocity.linear_interpolate(currentVelocity * newVelocity ,traction)
	if d < 0:
		velocity = -newVelocity *min(currentVelocity, speedReverse)

	rotation = newVelocity.angle()