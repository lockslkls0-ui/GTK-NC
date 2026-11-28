extends ColorRect

var main_ref = null
var lbl_etat : Label
var liste_box : VBoxContainer

func _ready():
    color = Color(0.05, 0.08, 0.13, 0.97); rect_position = Vector2(310, 120); rect_size = Vector2(660, 440); visible = false
    var t := Label.new(); t.text = "💾 GESTIONNAIRE DE SAUVEGARDES (Dossier : sauvegardes/)"; t.rect_position = Vector2(24, 16); add_child(t)
    lbl_etat = Label.new(); lbl_etat.rect_position = Vector2(24, 48); add_child(lbl_etat)
    var b_save := Button.new(); b_save.text = "💾 Créer une nouvelle sauvegarde maintenant"; b_save.rect_position = Vector2(24, 82); b_save.rect_size = Vector2(300, 40); b_save.focus_mode = Control.FOCUS_NONE
    b_save.connect("pressed", self, "_on_save"); add_child(b_save)
    var b_close := Button.new(); b_close.text = "❌ Fermer [F5/F9]"; b_close.rect_position = Vector2(340, 82); b_close.rect_size = Vector2(296, 40); b_close.focus_mode = Control.FOCUS_NONE
    b_close.connect("pressed", self, "_on_close"); add_child(b_close)
    var sc := ScrollContainer.new(); sc.rect_position = Vector2(24, 136); sc.rect_size = Vector2(612, 280); add_child(sc)
    liste_box = VBoxContainer.new(); liste_box.size_flags_horizontal = SIZE_EXPAND_FILL; sc.add_child(liste_box)

func rafraichir():
    for c in liste_box.get_children(): c.queue_free()
    var dir = Directory.new()
    if dir.open("res://sauvegardes") != OK:
        lbl_etat.text = "Dossier sauvegardes/ prêt."; return
    dir.list_dir_begin(true, true)
    var fichiers := Array()
    var fn = dir.get_next()
    while fn != "":
        if fn.ends_with(".json"): fichiers.append(fn)
        fn = dir.get_next()
    dir.list_dir_end()
    fichiers.sort(); fichiers.invert()
    lbl_etat.text = str(fichiers.size()) + " sauvegarde(s) — Clique sur une ligne pour la charger :"
    for nom_f in fichiers:
        var b := Button.new(); b.text = "📂 Charger : " + nom_f; b.rect_min_size = Vector2(580, 38); b.focus_mode = Control.FOCUS_NONE
        b.connect("pressed", self, "_charger_fichier", Array([nom_f]))
        liste_box.add_child(b)

func _on_save():
    var m = main_ref if main_ref != null else get_tree().get_root().get_node_or_null("Main")
    if m == null: return
    var dt := OS.get_datetime()
    var nom := "save_%04d-%02d-%02d_%02dh%02dm%02ds.json" % Array([dt["year"], dt["month"], dt["day"], dt["hour"], dt["minute"], dt["second"]])
    var d := {"x": m.joueur.position.x, "y": m.joueur.position.y, "pv": max(m.joueur.pv, 100.0), "argent": m.eco.argent, "bois": m.bois, "metal": m.metal, "abri_ok": m.constr.a_un_abri, "ax": m.constr.dernier_abri.x, "ay": m.constr.dernier_abri.y}
    var f = File.new()
    if f.open("res://sauvegardes/" + nom, File.WRITE) == OK:
        f.store_string(to_json(d)); f.close()
        rafraichir(); m.hud.msg_label.text = "💾 Sauvegarde créée : " + nom

func _charger_fichier(nom_f : String):
    var m = main_ref if main_ref != null else get_tree().get_root().get_node_or_null("Main")
    var f = File.new()
    if m == null or f.open("res://sauvegardes/" + nom_f, File.READ) != OK: return
    var d = parse_json(f.get_as_text()); f.close()
    if typeof(d) == TYPE_DICTIONARY:
        m.joueur.position = Vector2(float(d["x"]), float(d["y"])); m.joueur.pv = 100.0
        m.eco.argent = int(d["argent"]); m.bois = int(d["bois"]); m.metal = int(d.get("metal", 60))
        m.constr.a_un_abri = bool(d.get("abri_ok", false))
        m.constr.dernier_abri = Vector2(float(d.get("ax", 0)), float(d.get("ay", 0)))
        visible = false; m.hud.msg_label.text = "📂 Partie restaurée depuis " + nom_f

func _on_close(): visible = false
