extends Control


@onready var Fondo = $ColorFondoPausa
@onready var BotonPausa = $ButtonPausa
@onready var BotonContinuar = $ButtonContinuar
@onready var BotonSalir = $ButtonSalir


func _ready():
	pass


@warning_ignore("unused_parameter")
func _process(delta):
	if BotonPausa.is_hovered():
		GlobalScript.HaveBeenPause = true
	else:
		GlobalScript.HaveBeenPause = false


func _on_button_pausa_pressed():
	get_tree().paused = true
	BotonPausa.visible = false
	Fondo.visible = true
	BotonContinuar.visible = true
	BotonSalir.visible = true


func _on_button_continuar_pressed():
	get_tree().paused = false
	BotonPausa.visible = true
	Fondo.visible = false
	BotonContinuar.visible = false
	BotonSalir.visible = false


func _input(event):
	if event.is_action_released("ui_cancel"):
		get_tree().paused = !get_tree().paused
		if get_tree().paused:
			BotonPausa.visible = false
			Fondo.visible = true
			BotonContinuar.visible = true
			BotonSalir.visible = true
		else:
			BotonPausa.visible = true
			Fondo.visible = false
			BotonContinuar.visible = false
			BotonSalir.visible = false


func _on_button_salir_pressed():
	get_tree().quit()
