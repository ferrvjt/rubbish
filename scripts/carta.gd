class_name Carta
extends RefCounted

enum Tipo {
	RESIDUO,
	TRATAMIENTO,
	COMODIN
}

enum Categoria {
	ORGANICO,
	RECICLABLE,
	EWASTE,
	TOXICO,
	AS,
	COMODIN
}

var id: String
var nombre: String
var tipo: Tipo
var categoria: Categoria
var comodin_subtipo: String = "" # "J", "Q", "K"
var valor: int
var base_texture_path: String
var icon_texture_path: String

func _init(p_id: String = "", p_nombre: String = "", p_tipo: Tipo = Tipo.RESIDUO, p_valor: int = 0, p_base_path: String = "", p_icon_path: String = "") -> void:
	id = p_id
	nombre = p_nombre
	tipo = p_tipo
	valor = p_valor
	base_texture_path = p_base_path
	icon_texture_path = p_icon_path
	
	# Detectar categoría según el id de la carta sin alterar cartas_base.json
	if id.begins_with("org_"):
		categoria = Categoria.ORGANICO
	elif id.begins_with("rec_"):
		categoria = Categoria.RECICLABLE
	elif id.begins_with("ewaste_"):
		categoria = Categoria.EWASTE
	elif id.begins_with("toxic_"):
		categoria = Categoria.TOXICO
	elif id.begins_with("wild_ace_"):
		categoria = Categoria.AS
	elif id.begins_with("wild_j_"):
		categoria = Categoria.COMODIN
		comodin_subtipo = "J"
	elif id.begins_with("wild_q_"):
		categoria = Categoria.COMODIN
		comodin_subtipo = "Q"
	elif id.begins_with("wild_k_"):
		categoria = Categoria.COMODIN
		comodin_subtipo = "K"
	else:
		categoria = Categoria.ORGANICO

func es_organico() -> bool:
	return categoria == Categoria.ORGANICO

func es_reciclable() -> bool:
	return categoria == Categoria.RECICLABLE

func es_ewaste() -> bool:
	return categoria == Categoria.EWASTE

func es_toxico() -> bool:
	return categoria == Categoria.TOXICO

func es_as() -> bool:
	return categoria == Categoria.AS

func es_comodin() -> bool:
	return categoria == Categoria.COMODIN

func contaminar() -> void:
	categoria = Categoria.ORGANICO
	if not nombre.contains("(Contam.)"):
		nombre = nombre + " (Contam.)"
	base_texture_path = "res://assets/BaseCard_organic.png"

func get_id() -> String:
	return id

func get_nombre() -> String:
	return nombre

func get_tipo() -> Tipo:
	return tipo

func get_valor() -> int:
	return valor