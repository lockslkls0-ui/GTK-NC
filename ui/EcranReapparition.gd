extends ColorRect

func _ready():
    color = Color(0.04, 0.06, 0.10, 0.92); rect_position = Vector2(340, 190); rect_size = Vector2(600, 280); visible = false
    var t := Label.new(); t.text = "💀 TU ES TOMBÉ — CHOISIS TON POINT DE RÉAPPARITION"; t.rect_position = Vector2(45, 25); add_child(t)
    var b1 := Button.new(); b1.text = "🛖 Revivre dans ma Cabane construite (Par défaut)"; b1.rect_position = Vector2(45, 85); b1.rect_size = Vector2(510, 48); b1.focus_mode = Control.FOCUS_NONE
    b1.connect("pressed", self, "_on_cabane"); add_child(b1)
    var b2 := Button.new(); b2.text = "🌴 Revivre à la Tribu de départ (Houaïlou)"; b2.rect_position = Vector2(45, 155); b2.rect_size = Vector2(510, 48); b2.focus_mode = Control.FOCUS_NONE
    b2.connect("pressed", self, "_on_tribu"); add_child(b2)

func _revivre(pos_cible : Vector2, msg : String):
    var m = get_parent().get_parent()
    m.joueur.hp = 100.0; m.joueur.faim = 80.0; m.joueur.soif = 80.0; m.joueur.position = pos_cible; visible = false; m.hud.msg_label.text = msg

func _on_cabane():
    var m = get_parent().get_parent()
    if m.construc.a_un_abri: _revivre(m.construc.dernier_abri, "🛖 Réapparition dans ta Cabane avec 100 PV !")
    else: _revivre(Vector2(1800, -14200), "⚠️ Aucune cabane construite — Réapparition à Houaïlou !")

func _on_tribu(): _revivre(Vector2(1800, -14200), "🌴 Réapparition à la Tribu de Houaïlou avec 100 PV !")
