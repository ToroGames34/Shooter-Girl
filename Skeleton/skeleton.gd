extends CharacterBody2D


enum {IDLE, RUN, ATTACK, DEATH, SHIELD}

@onready var Nav = $NavigationAgent2D
@onready var Anim = $AnimatedSprite2D
@onready var AreaAttack = $AreaAttack/CollisionShape2D
@onready var RayAttack1 = $AreaAttack/RayCastAttack1
@onready var RayAttack2 = $AreaAttack/RayCastAttack2
@onready var RayAttack3 = $AreaAttack/RayCastAttack3
@onready var HealthBar = $HealthBar
@onready var CollisionShape = $CollisionShape2D
@onready var SoundLast = $AudioLastOne

var TimerAttack = Timer.new()
var TimerCDShield = Timer.new()
var TimerTrueAttack = Timer.new()
var PlayerToChase = null
var Speed = 170 #Before 140
var Acceleration = 7
var AttackSpeed = 1.3
var StartChasingAt = 1#Sec
var Live = 170 # Boost -> x2
var DamageToPlayer = 25 # Boost -> 15
var TimeForDeath = 0.45
var TimeCDforShield = 4.5 # Boost -> -2
var TimeOfShield = 2 # Boost -> 3.5
var DamageToBlock = 2 # Boost -> +0.5
var BonusSpeedLastOne = 55
var BonusDamageLastOne = 15
var BonusDamageBlock = 0.5
var BonusCDShield = 2
var BonusShieldUp = 1.5
var BonusLiveLast = 2 #the same amount of live multiplicate by 'BonusLiveLast' never below to 1.0
var FirstStrikeTime = 0.4
var TimeForTrueAttack = 0.02 # Before 0.25
var CurrentAnim
var NewAnim
var State
var StartChasing = false
var OneTimeAttack = true
var Death = false
var OneTimeChaseSelfPos = true
var OneTimeLastOne = true
var CanBeHurt = true
var IsShielding = false
var CanUseShield = true
var TrulyAttacking = false
var IsShieldUp = false
var OneTimeFirstStrikeLastOne = true
var Attacking = false


func _ready():
	Anim_Play(IDLE)
	HealthBar.max_value = Live
	HealthBar.value = Live
	RlyStartChasing()
	TimerAttackSettings()
	TimerCDShieldSettings()
	TimerTrueAttackSettings()


func TimerAttackSettings():
	TimerAttack.wait_time = AttackSpeed
	TimerAttack.connect("timeout", self._on_TimerAttack_timeout)
	add_child(TimerAttack)


func TimerCDShieldSettings():
	TimerCDShield.wait_time = TimeCDforShield
	TimerCDShield.one_shot = true
	TimerCDShield.connect("timeout", self._on_TimerCDShield_timeout)
	add_child(TimerCDShield)


func TimerTrueAttackSettings():
	TimerTrueAttack.wait_time = TimeForTrueAttack
	TimerTrueAttack.one_shot = true
	TimerTrueAttack.connect("timeout", self._on_TimerTrueAttack_timeout)
	add_child(TimerTrueAttack)


@warning_ignore("unused_parameter")
func _process(delta):
	UpdateAnim()


func _physics_process(_delta: float):
	var direction = Vector2()
	
	if !Death:
		
		if PlayerToChase != null:
			if position.x < PlayerToChase.position.x:
				SetTargetToChase(PlayerToChase.FollowLeft.global_position)
			else:
				SetTargetToChase(PlayerToChase.FollowRight.global_position)
		
		if Nav.distance_to_target() > 30 and !RayAttack1.is_colliding() and !RayAttack2.is_colliding() and !RayAttack3.is_colliding():
			if StartChasing:
				OneTimeFirstStrikeLastOne = true
				OneTimeAttack = true
				TimerAttack.stop()
				AreaAttack.set_deferred("disabled", true)
				if !IsShielding:
					Anim_Play(RUN)
				direction = Nav.get_next_path_position() - global_position
				direction = direction.normalized()
				velocity = velocity.lerp(direction * Speed, Acceleration * _delta)
				move_and_slide()
		else:
			if RayAttack2.is_colliding():
				if OneTimeAttack:
					OneTimeAttack = false
					if OneTimeLastOne:
						Anim_Play(IDLE)
					if OneTimeLastOne:
						FirstStrike()
					TimerAttack.start()
				
				if !OneTimeLastOne:
					if TrulyAttacking:
						if OneTimeFirstStrikeLastOne:
							OneTimeFirstStrikeLastOne = false
							Anim_Play(IDLE)
							FirstStrike()
				
		if PlayerToChase != null:
			if position.x < PlayerToChase.position.x:
				Anim.offset.x = 0
				Anim.flip_h = false
				AreaAttack.position.x = 58
				RayAttack1.target_position.x = 55
				RayAttack2.target_position.x = 55
				RayAttack3.target_position.x = 55
			else:
				Anim.offset.x = 10
				Anim.flip_h = true
				AreaAttack.position.x = -58
				RayAttack1.target_position.x = -55
				RayAttack2.target_position.x = -55
				RayAttack3.target_position.x = -55
		
		ExactlyFrameForAttack()
		IsPlayerDeath()
		RlyInRangeToAttack()
		PutOrNotShield()


var OneTimeRlyAttack = true
func RlyInRangeToAttack():
	if RayAttack2.is_colliding():
		if OneTimeRlyAttack:
			OneTimeRlyAttack = false
			TimerTrueAttack.start()
	else:
		OneTimeRlyAttack = true
		TimerTrueAttack.stop()
		TrulyAttacking = false
	
	if OneTimeLastOne:
		TrulyAttacking = true


func Anim_Play(state):
	State = state
	match State:
		IDLE:
			NewAnim = "idle"
		RUN:
			NewAnim = "run"
		ATTACK:
			NewAnim = "attack"
		DEATH:
			NewAnim = "death"
		SHIELD:
			NewAnim = "shield"


func UpdateAnim():
	if NewAnim != CurrentAnim:
		Anim.play(NewAnim)
		CurrentAnim = NewAnim
	
	if NewAnim == "shield":
			IsShieldUp = true
	
	if !NewAnim == "attack":
			Attacking = false


func SetTargetToChase(t: Vector2):
	Nav.target_position = t


func IsPlayerDeath():
	if PlayerToChase == null:
		if OneTimeChaseSelfPos:
			OneTimeChaseSelfPos = false
			TimerAttack.stop()
			AreaAttack.set_deferred("disabled", true)
			SetTargetToChase(position)
			Anim_Play(IDLE)
	else:
		OneTimeChaseSelfPos = true


func _on_TimerTrueAttack_timeout():
	TrulyAttacking = true


func RlyStartChasing():
	await get_tree().create_timer(StartChasingAt).timeout
	StartChasing = true


func _on_TimerAttack_timeout():
	if !Death and OneTimeChaseSelfPos:
		Attacking = true
		Anim_Play(ATTACK)


func FirstStrike():
	await get_tree().create_timer(FirstStrikeTime).timeout
	if !Death:
		Attacking = true
		Anim_Play(ATTACK)


func _on_animated_sprite_2d_animation_finished():
	if Anim.animation == "attack":
		AreaAttack.set_deferred("disabled", true)
		Anim_Play(IDLE)
	if Anim.animation == "death":
		await get_tree().create_timer(TimeForDeath).timeout
		call_deferred("queue_free")


func ExactlyFrameForAttack():
	if Anim.animation == "attack":# and (RayAttack1.is_colliding() or RayAttack2.is_colliding() or RayAttack3.is_colliding())
		if Anim.frame == 4:
			AreaAttack.set_deferred("disabled", false)


func _on_area_attack_body_entered(body):
	if body.is_in_group("player"):
		body.Hurt(DamageToPlayer)


func Hurt(damage):
	Anim.modulate = Color(1, 0, 0, 1)
	if CanBeHurt:
		if !IsShielding:
			HealthBar.value += -damage
		else:
			HealthBar.value += -(damage / DamageToBlock)
	if HealthBar.value <= 0:
		DeathF()
	await get_tree().create_timer(0.3).timeout
	Anim.modulate = Color(1, 1, 1, 1)


func DeathF():
	CollisionShape.set_deferred("disabled", true)
	Death = true
	TimerAttack.stop()
	Anim_Play(DEATH)


func LastOne():
	if OneTimeLastOne:
		OneTimeLastOne = false
		CanBeHurt = false
		
		HealthBar.max_value = HealthBar.max_value * BonusLiveLast
		HealthBar.value = HealthBar.value * BonusLiveLast
		Speed += BonusSpeedLastOne
		DamageToPlayer += BonusDamageLastOne
		TimeCDforShield += -BonusCDShield
		TimerCDShield.wait_time = TimeCDforShield
		TimeOfShield += BonusShieldUp
		DamageToBlock += BonusDamageBlock
		
		SoundLast.play()
		ChangeColor()


func ChangeColor():
	var tween = create_tween()
	
	if !Death:
		var InterChangeColor = 0.5
		var FinistCol = InterChangeColor * 2
		
		tween.tween_property(Anim, "modulate", Color(1, 0, 1, 1), InterChangeColor
		).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		
		tween.tween_property(Anim, "modulate", Color(1, 1, 1, 1), InterChangeColor
		).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		
		await create_tween().tween_interval(FinistCol).finished
		if !Death:
			ChangeColor()
	else:
		tween.stop()
		Anim.modulate = Color(1, 1, 1, 1)


func _on_area_shield_area_entered(area):
	if area.is_in_group("bullet"):
		if CanUseShield:
			CanUseShield = false
			IsShielding = true
			
			TimerCDShield.start()
			await get_tree().create_timer(TimeOfShield).timeout
			IsShielding = false
			IsShieldUp = false


func _on_TimerCDShield_timeout():
	CanUseShield = true


func PutOrNotShield():
	if PlayerToChase != null:
		if IsShielding and !Death and !Attacking:
			Anim_Play(SHIELD)


func _on_audio_last_one_finished():
	CanBeHurt = true

