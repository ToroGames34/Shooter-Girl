extends Area2D


@onready var AnimBullet = $AnimatedSpriteBullet
@onready var CollisionShape = $CollisionShape2D
@onready var SoundHit = $AudioHit

var Speed = 700
var Impact = false
var FireFrom = ""
var DamageFromPistol = 10
var DamageFromFusil = 20
var DamageFromShotgun = 20


func _ready():
	AnimBullet.play("bullet")


func _process(delta):
	if !Impact:
		position += transform.y * -Speed * delta


func _on_body_entered(body):
	if body.is_in_group("enemy"):
		Impact = true
		GoodPosImpact()
		CollisionShape.set_deferred("disabled", true)
		AnimBullet.play("impact")
		SoundHit.play()
		
		body.Hurt(FromWhichGun(FireFrom))
		
	if body.is_in_group("wall"):
		Impact = true
		GoodPosImpact()
		CollisionShape.set_deferred("disabled", true)
		AnimBullet.play("impact")


func GoodPosImpact():
	if get_transform().x.y > 0:
		position.x += -10
	else:
		position.x += 10


func _on_visible_on_screen_notifier_2d_screen_exited():
	call_deferred("queue_free")


func _on_animated_sprite_bullet_animation_finished():
	call_deferred("queue_free")


func FromWhichGun(gun):
	match gun:
		"pistol":
			return DamageFromPistol
		"fusil":
			return DamageFromFusil
		"shotgun":
			return DamageFromShotgun

