class_name EstadoJuego
extends RefCounted

var puntos_reduccion: int = 0
var contaminacion_actual: int = 0
var limite_contaminacion: int = 21
var limite_mano: int = 10
var cartas_a_robar: int = 4
var turno: int = 1
var comodines_usados: Array[Carta] = []
var estado_partida: String = "JUGANDO" # "JUGANDO", "VICTORIA", "DERROTA
var logs: Array[String] = []

func _init(p_limite: int = 21) -> void:
	limite_contaminacion = p_limite
	puntos_reduccion = 0
	contaminacion_actual = 0
	limite_mano = 10
	cartas_a_robar = 4
	turno = 1
	comodines_usados = []
	estado_partida = "JUGANDO"
	logs = ["[INICIO] Partida iniciada. Limpia el entorno sin alcanzar el límite de contaminación."]

func actualizar_puntos(puntos: int) -> void:
	puntos_reduccion = max(0, puntos_reduccion + puntos)

func incrementar_contaminacion(cantidad: int) -> void:
	contaminacion_actual += cantidad
	if contaminacion_actual >= limite_contaminacion:
		estado_partida = "DERROTA"

func reducir_contaminacion(cantidad: int) -> void:
	contaminacion_actual = max(0, contaminacion_actual - cantidad)

func registrar_log(mensaje: String) -> void:
	logs.append(mensaje)
	print("[LOG] ", mensaje)

func get_ultimos_logs(cantidad: int = 4) -> Array[String]:
	var inicio = max(0, logs.size() - cantidad)
	return logs.slice(inicio)

func es_derrota() -> bool:
	return contaminacion_actual >= limite_contaminacion or estado_partida == "DERROTA"

func es_victoria() -> bool:
	return estado_partida == "VICTORIA"

func get_puntos_reduccion() -> int:
	return puntos_reduccion

func get_contaminacion_actual() -> int:
	return contaminacion_actual