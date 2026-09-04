class_name Mazo
extends RefCounted

var cartas: Array[Carta] = []
var descarte: Array[Carta] = []

func barajar() -> void:
	cartas.shuffle()

func robar_carta() -> Carta:
	if cartas.is_empty():
		if descarte.is_empty():
			return null # No hay cartas disponibles
		# Si el mazo se acaba, rebarajamos el descarte
		cartas = descarte.duplicate()
		descarte.clear()
		barajar()
	
	return cartas.pop_back()

func agregar_a_descarte(carta: Carta) -> void:
	if carta != null:
		descarte.append(carta)