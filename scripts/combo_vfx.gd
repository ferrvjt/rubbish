class_name ComboVFX
extends Node2D

@onready var texto_vfx: RichTextLabel = $TextoVFX

func configurar(texto: String, pos_inicial: Vector2, color_hex: String = "#FFD700") -> void:
	global_position = pos_inicial

	# Usar BBCode para un efecto de temblor
	var bbcode_texto = "[center][shake rate=30.0 level=15 connected=1][color=" + color_hex + "]" + texto + "[/color][/shake][/center]"
	texto_vfx.text = bbcode_texto

	_reproducir_animacion()

func _reproducir_animacion() -> void:
	scale = Vector2(0.1, 0.1)

	rotation = randf_range(-0.3, 0.3)

	var tween = create_tween()

	tween.set_parallel(true)

	# 1. Crece gigantesco muy rápido y luego regresa (Scale)
	tween.tween_property(self, "scale", Vector2(1.8, 1.8), 0.1).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.2).set_delay(0.1).set_trans(Tween.TRANS_SINE)
	
	# 2. Vuelve a los 0 grados poco a poco (Rotation)
	tween.tween_property(self, "rotation", 0.0, 0.3).set_ease(Tween.EASE_OUT)
	
	# 3. Sube lentamente mientras tiembla (Position)
	var pos_final = position + Vector2(randf_range(-30, 30), -100)
	tween.tween_property(self, "position", pos_final, 0.9).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	# 4. Desaparece suavemente al final (Modulate Alpha)
	tween.tween_property(self, "modulate:a", 0.0, 0.3).set_delay(0.6)
	
	# Detenemos el paralelismo para encolar la destrucción
	tween.set_parallel(false)
	
	# 5. Elimina el nodo cuando todas las animaciones terminan
	tween.tween_callback(self.queue_free)