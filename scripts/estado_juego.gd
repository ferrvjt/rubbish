class_name EstadoJuego
extends RefCounted

var puntos_reduccion: int = 0
var contaminacion_actual: int = 0
var limite_contaminacion: int = 21

func _init(p_limite: int = 21) -> void:
	limite_contaminacion = p_limite

func actualizar_puntos(puntos: int) -> void:
	puntos_reduccion += puntos

func incrementar_contaminacion(cantidad: int) -> void:
	contaminacion_actual += cantidad

func es_derrota() -> bool:
	return contaminacion_actual > limite_contaminacion

func get_puntos_reduccion() -> int:
	return puntos_reduccion

func get_contaminacion_actual() -> int:
	return contaminacion_actual