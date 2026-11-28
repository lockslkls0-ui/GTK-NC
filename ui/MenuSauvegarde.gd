extends ColorRect

var main_ref = null
var lbl_etat : Label
var liste_box : VBoxContainer

func _ready():
    color = Color(0.05, 0.08, 0.13, 0.97); rect_position = Vector2(290, 110); rect_size = Vector2(700, 460); visible = false
    var t := Label.new(); t.text = "💾 SAUVEGARDES GTK-NC (Dossier : sauvegardes/)"; t.rect_position = Vector2(24, 16); add_child(t)
    lbl_etat = Label.new(); lbl_etat.rect_position = Vector2(24, 48); add_child(lbl_etat)
    var b_save := Button.new(); b_save.text = "💾 Sauvegarder maintenant"; b_save.rect_position = Vector2(24, 82); b_save.rect_size = Vector2(310, 40); b_save.focus_mode = Control.FOCUS_NONE
    b_save.connect("pressed", self, "_on_save"); add_child(b_save)
    var b_close := Button.new(); b_close.text = "❌ Fermer [F5/F9]"; b_close.rect_position = Vector2(356, 82); b_close.rect_size = Vector2(320, 40); b_close.focus_mode = Control.FOCUS_NONE
    b_close.connect("pressed", self, "_on_close"); add_child(b_close)
    var sc := ScrollContainer.new(); sc.rect_position = Vector2(24, 136); sc.rect_size = Vector2(652, 300); add_child(sc)
    liste_box = VBoxContainer.new(); liste_box.size_flags_horizontal = SIZE_EXPAND_FILL; sc.add_child(liste_box)

func lister_sauvegardes() -> Array:
    var res := Array()
    var dir = Directory.new()
    if not dir.dir_exists("user://sauvegardes"): dir.make_dir_recursive("user://sauvegardes")
    if dir.open("user://sauvegardes") != OK: return res
    dir.list_dir_begin(true, true)
    var fn = dir.get_next()
    while fn != "":
        if fn.ends_with(".json"): res.append(fn)
        fn = dir.get_next()
    dir.list_dir_end()
    res.sort(); res.invert()
    return res

func lire_infos(nom_f : String) -> Dictionary:
    var f = File.new()
    if f.open("user://sauvegardes/" + nom_f, File.READ) != OK: return {}
    var d = parse_json(f.get_as_text()); f.close()
    return d if typeof(d) == TYPE_DICTIONARY else {}

func rafraichir():
    for c in liste_box.get_children(): c.queue_free()
    var fichiers := lister_sauvegardes()
    lbl_etat.text = str(fichiers.size()) + " sauvegarde(s) enregistrée(s) — Clique pour charger :"
    for nom_f in fichiers:
        var d := lire_infos(nom_f)
        var txt_btn := "📂 " + str(d.get("date_txt", nom_f)) + " | Niv." + str(int(d.get("niveau", 1))) + " | " + str(int(d.get("pv", 100))) + " PV | " + str(int(d.get("bois", 0))) + " Bois"
        var b := Button.new(); b.text = txt_btn; b.rect_min_size = Vector2(620, 40); b.focus_mode = Control.FOCUS_NONE
        var args := Array(); args.append(nom_f)
        b.connect("pressed", self, "_charger_fichier", args)
        liste_box.add_child(b)

func _on_save():
    var m = main_ref if main_ref != null else get_tree().get_root().get_node_or_null("Main")
    if m == null: return
    var dir = Directory.new()
    if not dir.dir_exists("user://sauvegardes"): dir.make_dir_recursive("user://sauvegardes")
    var dt := OS.get_datetime()
    var an := str(dt["year"]); var mo := str(dt["month"]).pad_zeros(2); var jr := str(dt["day"]).pad_zeros(2)
    var hr := str(dt["hour"]).pad_zeros(2); var mn := str(dt["minute"]).pad_zeros(2); var sc := str(dt["second"]).pad_zeros(2)
    var nom := "save_" + an + "-" + mo + "-" + jr + "_" + hr + "h" + mn + "m" + sc + "s.json"
    var date_lisible := jr + "/" + mo + "/" + an + " à " + hr + "h" + mn
    var cons_save := Array()
    for c_it in m.constr.constructions:
        cons_save.append({"type": c_it["type"], "x": c_it["pos"].x, "y": c_it["pos"].y, "vert": c_it.get("vert", false)})
    var d := {
        "date_txt": date_lisible, "x": m.joueur.position.x, "y": m.joueur.position.y,
        "pv": m.joueur.pv, "pv_max": m.joueur.pv_max, "energie": m.joueur.energie,
        "armure": m.armure, "niveau": m.niveau, "xp": m.xp, "xp_max": m.xp_max,
        "vague": m.vague, "argent": m.eco.argent, "bois": m.bois, "metal": m.metal,
        "bidons": m.bidons, "vivres": m.vivres, "reserve": m.armes.reserve, "armes_deb": m.armes.debloquees,
        "abri_ok": m.constr.a_un_abri, "ax": m.constr.dernier_abri.x, "ay": m.constr.dernier_abri.y,
        "constructions": cons_save
    }
    var f = File.new()
    if f.open("user://sauvegardes/" + nom, File.WRITE) == OK:
        f.store_string(to_json(d)); f.close()
        rafraichir(); m.hud.msg_label.text = "💾 Partie enregistrée (" + date_lisible + ") !"

func _charger_fichier(nom_f : String):
    var m = main_ref if main_ref != null else get_tree().get_root().get_node_or_null("Main")
    var d := lire_infos(nom_f)
    if m == null or d.empty(): return
    m.joueur.position = Vector2(float(d.get("x", 0)), float(d.get("y", 0)))
    m.joueur.pv_max = float(d.get("pv_max", 100.0))
    m.joueur.pv = clamp(float(d.get("pv", 100.0)), 25.0, m.joueur.pv_max)
    m.joueur.energie = float(d.get("energie", 100.0))
    m.armure = float(d.get("armure", 35.0)); m.niveau = int(d.get("niveau", 1))
    m.xp = float(d.get("xp", 0.0)); m.xp_max = float(d.get("xp_max", 500.0))
    m.vague = int(d.get("vague", 1)); m.eco.argent = int(d.get("argent", 2500))
    m.bois = int(d.get("bois", 140)); m.metal = int(d.get("metal", 60))
    m.bidons = int(d.get("bidons", 2)); m.vivres = int(d.get("vivres", 5))
    m.armes.reserve = int(d.get("reserve", 180))
    if d.has("armes_deb") and typeof(d["armes_deb"]) == TYPE_ARRAY:
        for ia in range(min(m.armes.debloquees.size(), d["armes_deb"].size())): m.armes.debloquees[ia] = bool(d["armes_deb"][ia])
    m.constr.a_un_abri = bool(d.get("abri_ok", false))
    m.constr.dernier_abri = Vector2(float(d.get("ax", 0)), float(d.get("ay", 0)))
    visible = false
    if m.get("menu_accueil") != null: m.menu_accueil.visible = false
    m.get_tree().paused = false
    m.hud.msg_label.text = "📂 Partie chargée (" + str(d.get("date_txt", nom_f)) + " | Niv." + str(m.niveau) + ") !"

func _on_close(): visible = false
