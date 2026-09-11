class_name GameManager
extends Node

var estado: EstadoJuego
var mazo: Mazo

func _ready() -> void:
    iniciar_partida()

func iniciar_partida() -> void:
    # 1. Instanciar Partida
    estado = EstadoJuego.new(21)

    # 2. Instaciar mazo
    mazo = Mazo.new()

    # 3. Cargar cartas y barajar
    mazo.cargar_desde_json("res://assets/cartas_base.json")

    # 4. Robar mano inicial
    robar_mano_inicial(5)

func robar_mano_inicial(cantidad: int) -> void:
    for i in range(cantidad):
        var carta_robada = mazo.robar_carta()
        if carta_robada != null:
            print("Carta en mano: ", carta_robada.get_nombre())