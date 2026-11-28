extends Node2D

func _ready():
    z_index = 15

var argent := 2500
var explosifs := 3
var coffre_pose := false
var coffre_pos := Vector2.ZERO
var coffre_bois := 0
var coffre_metal := 0
var coffre_balles := 0
var bombes_actives := []
var ondes_choc := []

func poser_coffre_qg(pos : Vector2) -> String:
    if coffre_pose:
        coffre_pos = pos + Vector2(45, 0)
        get_child(0).position = coffre_pos
        return "📦 Coffre QG déplacé ici ! ([O] Déposer/Retirer)"
    coffre_pose = true
    coffre_pos = pos + Vector2(45, 0)
    return "🏠 Camp & Coffre QG installés ! ([O] Gérer le coffre)"

func poser_explosif(pos : Vector2) -> String:
    if explosifs <= 0:
        return "❌ Plus d'explosif ! Achètes-en avec le Téléphone/Boutique [P] (1200 F)."
    explosifs -= 1
    var b = Polygon2D.new(); b.position = pos
    add_child(b); bombes_actives.append(b)
    return "💣 Bombe amorcée ! Éloigne-toi (explosion dans 2.0s) !"

func _creer_cratere_et_onde(bp : Vector2):
    var cratere = Polygon2D.new(); cratere.position = bp; cratere.z_index = 2
    var pts_c := PoolVector2Array()
    for k in range(16):
        var a := float(k) * TAU / 16.0
        var r := 95.0 + float((k * 19) % 35)
        pts_c.append(Vector2(cos(a) * r, sin(a) * r))
    var onde = Polygon2D.new(); onde.position = bp; onde.z_index = 22
    var pts_o := PoolVector2Array()
    for k in range(20):
        var a := float(k) * TAU / 20.0
        pts_o.append(Vector2(cos(a) * 320.0, sin(a) * 320.0))
    onde.set_meta("vie", 0.45); add_child(onde); ondes_choc.append(onde)

func maj_bombes(delta : float, ennemis : Array, joueur : KinematicBody2D) -> String:
    for io in range(ondes_choc.size() - 1, -1, -1):
        var o = ondes_choc[io]; var vo = o.get_meta("vie") - delta; o.set_meta("vie", vo)
        var prog = clamp(1.0 - (vo / 0.45), 0.0, 1.0)
        o.scale = Vector2(0.15 + prog * 1.15, 0.15 + prog * 1.15)
        if vo <= 0.0: o.queue_free(); ondes_choc.remove(io)
    var msg := ""
    for i in range(bombes_actives.size() - 1, -1, -1):
        var b = bombes_actives[i]; var t = b.get_meta("timer") - delta; b.set_meta("timer", t)
        b.scale = Vector2(1.0 + 0.25 * sin(t * 24.0), 1.0 + 0.25 * sin(t * 24.0))
        if t <= 0.0:
            var bp = b.position; _creer_cratere_et_onde(bp)
            var tues := 0
            for j in range(ennemis.size() - 1, -1, -1):
                if ennemis[j].position.distance_to(bp) < 320.0:
                    ennemis[j].queue_free(); ennemis.remove(j); argent += 250; tues += 1
            if joueur.position.distance_to(bp) < 130.0: joueur.pv = max(0.0, joueur.pv - 25.0)
            b.queue_free(); bombes_actives.remove(i)
            msg = "💥 BOUM ! Onde de choc (" + str(tues) + " cible(s) neutralisée(s), cratère au sol) !"
    return msg
