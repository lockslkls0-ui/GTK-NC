extends ColorRect

var lbl_info : Label

func _ready():
    color = Color(0.05, 0.09, 0.14, 0.96)
    rect_position = Vector2(340, 160); rect_size = Vector2(600, 340); visible = false
    var titre := Label.new(); titre.text = "📱 RADIO & TÉLÉPHONE DU CLAN — GTK-NC"; titre.rect_position = Vector2(24, 18); add_child(titre)
    lbl_info = Label.new(); lbl_info.rect_position = Vector2(24, 52); lbl_info.text = "Choisis une action radio avec ton clan :"; add_child(lbl_info)
    _btn("📦 Parachutage Clan (1000 F : +1 Bombe, +30 Balles, +1 Bidon)", Vector2(24, 100), "_on_para")
    _btn("🚙 Appeler Cousins en Renfort (800 F : +2 Alliés armés)", Vector2(24, 155), "_on_renfort")
    _btn("📡 Nouvelle Mission d'Urgence Radio (Gratuit)", Vector2(24, 210), "_on_mission")
    _btn("❌ Fermer la Radio [P]", Vector2(24, 275), "_on_fermer")

func _btn(txt : String, pos : Vector2, fn : String):
    var b := Button.new(); b.text = txt; b.rect_position = pos; b.rect_size = Vector2(550, 42); b.focus_mode = Control.FOCUS_NONE
    b.connect("pressed", self, fn); add_child(b)

func _on_para():
    var m = get_tree().get_root().get_node_or_null("Main")
    if m.eco.argent >= 1000:
        m.eco.argent -= 1000; m.eco.explosifs += 1; m.armes.reserve += 30; m.bidons += 1; m.audio.p_ok.play()
        lbl_info.text = "✅ Parachutage livré ! Solde : " + str(m.eco.argent) + " F"
    else: lbl_info.text = "❌ Solde insuffisant (" + str(m.eco.argent) + " F / 1000 F)"

func _on_renfort():
    var m = get_tree().get_root().get_node_or_null("Main")
    if m.eco.argent >= 800:
        m.eco.argent -= 800; m.audio.p_ok.play(); var aj := 0
        for k in range(2):
            var a = KinematicBody2D.new()
            a.position = m.joueur.position + Vector2(85 + k * 45, 55)
            a.add_child(m.pop.creer_humain_style(Color(0.30, 0.17, 0.10), Color(0.18, 0.68, 0.36), false))
            var col = CollisionShape2D.new(); var sh = CircleShape2D.new(); sh.radius = 15.0; col.shape = sh; a.add_child(col)
            a.set_meta("recrute", true); a.set_meta("cd", 0.0); a.set_meta("dir", Vector2(1, 0))
            m.pop.add_child(a); m.pop.allies.append(a); aj += 1
        lbl_info.text = "✅ " + str(aj) + " cousin(s) recruté(s) ! Solde : " + str(m.eco.argent) + " F"
    else: lbl_info.text = "❌ Solde insuffisant (" + str(m.eco.argent) + " F / 800 F)"

func _on_mission():
    var m = get_tree().get_root().get_node_or_null("Main")
    m.monde.mission_num += 1; m.monde.generer_nouvelle_mission(m.joueur.position)
    m.pnj.creer_pnj_mission(m.monde.mission_cible); m.audio.p_ok.play()
    lbl_info.text = "📡 Nouvelle mission : " + m.monde.mission_titre

func _on_fermer(): visible = false
