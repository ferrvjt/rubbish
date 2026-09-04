class_name Carta
extends RefCounted

enum Tipo {
    RESIDUO,
    TRATAMIENTO,
    COMODIN
}

var id: String
var nombre: String
var tipo: Tipo
var valor: int

func _init(p_id: String = "", p_nombre: String = "", p_tipo: Tipo = Tipo.RESIDUO, p_valor: int = 0) -> void:
	id = p_id
	nombre = p_nombre
	tipo = p_tipo
	valor = p_valor

func aplicar_efecto(estado: EstadoJuego) -> void:
	match tipo:
		Tipo.RESIDUO:
			estado.incrementar_contaminacion(valor)
		Tipo.TRATAMIENTO:
			estado.actualizar_puntos(valor)
		Tipo.COMODIN:
			pass

func get_id() -> String:
	return id

func get_nombre() -> String:
	return nombre

func get_tipo() -> Tipo:
	return tipo

func get_valor() -> int:
	return valor