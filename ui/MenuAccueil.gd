extends CanvasLayer

var main_ref = null
var liste_box : VBoxContainer

func _ready():
    layer = 20
    pause_mode = 2
    var fond = ColorRect.new(); fond.color = Color(0.03, 0.07, 0.11, 0.94); fond.rect_size = Vector2(1280, 720); add_child(fond)
    var cadre = ColorRect.new(); cadre.color = Color(0.06, 0.11, 0.17, 0.98); cadre.rect_position = Vector2(40, 40); cadre.rect_size = Vector2(720, 520); add_child(cadre)
    var titre = Label.new(); titre.text = "🌴 GTK-NC — GRANDE TERRE KANAKY NOUVELLE-CALÉDONIE"; titre.rect_position = Vector2(75, 65); titre.add_color_override("font_color", Color(1.0, 0.88, 0.25)); add_child(titre)
    var sub = Label.new(); sub.text = "Survie, Exploration & Entraide sur la vraie carte du Caillou"; sub.rect_position = Vector2(75, 92); add_child(sub)
    var b_new = Button.new(); b_new.text = "▶️ NOUVELLE PARTIE (Démarrer en Tribu à Houaïlou)"; b_new.rect_position = Vector2(75, 130); b_new.rect_size = Vector2(650, 48); b_new.focus_mode = Control.FOCUS_NONE
    b_new.connect("button_down", self, "_on_nouvelle"); add_child(b_new)
    var lbl_ch = Label.new(); lbl_ch.text = "📂 CHARGER UNE PARTIE ENREGISTRÉE :"; lbl_ch.rect_position = Vector2(75, 195); add_child(lbl_ch)
    var sc = ScrollContainer.new(); sc.rect_position = Vector2(75, 222); sc.rect_size = Vector2(650, 240); add_child(sc)
    liste_box = VBoxContainer.new(); liste_box.size_flags_horizontal = 3; sc.add_child(liste_box)
    var b_quit = Button.new(); b_quit.text = "🚪 Quitter le jeu"; b_quit.rect_position = Vector2(75, 480); b_quit.rect_size = Vector2(650, 42); b_quit.focus_mode = Control.FOCUS_NONE
    b_quit.connect("button_down", self, "_on_quitter"); add_child(b_quit)

func actualiser():
    for c in liste_box.get_children(): c.queue_free()
    if main_ref == null or main_ref.hud == null or main_ref.hud.save_panel == null: return
    var sp = main_ref.hud.save_panel
    var fichiers = sp.lister_sauvegardes()
    if fichiers.empty():
        var l = Label.new(); l.text = "Aucune sauvegarde enregistrée (Construis une Cabane ou appuie sur [F5] en jeu)."; liste_box.add_child(l); return
    for nom_f in fichiers:
        var d = sp.lire_infos(nom_f)
        var txt = "📂 " + str(d.get("date_txt", nom_f)) + " — Niv." + str(int(d.get("niveau", 1))) + " | " + str(int(d.get("pv", 100))) + " PV | " + str(int(d.get("bois", 0))) + " Bois | " + str(int(d.get("argent", 0))) + " F"
        var b = Button.new(); b.text = txt; b.rect_min_size = Vector2(620, 40); b.focus_mode = Control.FOCUS_NONE
        var args = Array(); args.append(nom_f)
        b.connect("button_down", self, "_on_charger", args)
        liste_box.add_child(b)

func _on_nouvelle():
    visible = false
    get_tree().paused = false
    if main_ref != null:
        main_ref.get_tree().paused = false
        main_ref.hud.msg_label.text = "🌴 Nouvelle aventure démarrée à Houaïlou !"

func _on_charger(nom_f : String):
    get_tree().paused = false
    if main_ref != null and main_ref.hud != null and main_ref.hud.save_panel != null:
        main_ref.hud.save_panel._charger_fichier(nom_f)
    visible = false

func _on_quitter():
    get_tree().quit()

func _input(event):
    if visible and ((event is InputEventScreenTouch and event.pressed) or (event is InputEventMouseButton and event.pressed)):
        if event.position.y < 230.0:
            _on_nouvelle()
