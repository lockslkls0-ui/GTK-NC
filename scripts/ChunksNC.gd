extends Node2D

var chunks_generes := {}

func verifier_chunks(pos_joueur : Vector2):
    var cx = int(floor(pos_joueur.x / 2000.0))
    var cy = int(floor(pos_joueur.y / 2000.0))
    var cle = str(cx) + "_" + str(cy)
    if not chunks_generes.has(cle):
        chunks_generes[cle] = true
