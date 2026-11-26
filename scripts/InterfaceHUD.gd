extends CanvasLayer

var barre_pv : ColorRect
var barre_energie : ColorRect
var barre_essence : ColorRect
var hud_label : Label
var msg_label : Label
var carte_panel : ColorRect
var aide_panel : ColorRect
var lunette_panel : ColorRect
var btn_aide : Button
var btn_carte : Button
var btn_zoom_in : Button
var btn_zoom_out : Button
var cur_m_s := PoolVector2Array()
var cur_m_c := PoolColorArray()

func _ready():
    var fond = ColorRect.new(); fond.color = Color(0.05, 0.08, 0.12, 0.84); fond.rect_position = Vector2(12, 10); fond.rect_size = Vector2(810, 122); add_child(fond)
    barre_pv = creer_jauge(Vector2(22, 18), 190, Color(0.90, 0.20, 0.22))
    barre_energie = creer_jauge(Vector2(225, 18), 190, Color(0.95, 0.78, 0.18))
    barre_essence = creer_jauge(Vector2(428, 18), 190, Color(0.20, 0.78, 0.95))
    hud_label = Label.new(); hud_label.rect_position = Vector2(22, 42); hud_label.add_color_override("font_color", Color(1, 0.96, 0.80)); add_child(hud_label)
    msg_label = Label.new(); msg_label.rect_position = Vector2(22, 138); msg_label.add_color_override("font_color", Color(0.35, 1.0, 0.65)); add_child(msg_label)
    btn_aide = Button.new(); btn_aide.text = "⚙️ Commandes [H]"; btn_aide.focus_mode = Control.FOCUS_NONE; btn_aide.rect_position = Vector2(835, 14); btn_aide.rect_size = Vector2(165, 34); add_child(btn_aide)
    btn_carte = Button.new(); btn_carte.text = "🗺️ Carte NC [M]"; btn_carte.focus_mode = Control.FOCUS_NONE; btn_carte.rect_position = Vector2(835, 54); btn_carte.rect_size = Vector2(165, 34); add_child(btn_carte)
    btn_zoom_in = Button.new(); btn_zoom_in.text = "🔍+"; btn_zoom_in.focus_mode = Control.FOCUS_NONE; btn_zoom_in.rect_position = Vector2(1008, 14); btn_zoom_in.rect_size = Vector2(48, 34); add_child(btn_zoom_in)
    btn_zoom_out = Button.new(); btn_zoom_out.text = "🔭-"; btn_zoom_out.focus_mode = Control.FOCUS_NONE; btn_zoom_out.rect_position = Vector2(1008, 54); btn_zoom_out.rect_size = Vector2(48, 34); add_child(btn_zoom_out)
    var rbg = ColorRect.new(); rbg.color = Color(0.02, 0.18, 0.12, 0.88); rbg.rect_position = Vector2(835, 100); rbg.rect_size = Vector2(165, 165); add_child(rbg)
    var r_h = ColorRect.new(); r_h.color = Color(0.1, 0.45, 0.3); r_h.rect_position = Vector2(835, 182); r_h.rect_size = Vector2(165, 1); add_child(r_h)
    var r_v = ColorRect.new(); r_v.color = Color(0.1, 0.45, 0.3); r_v.rect_position = Vector2(917, 100); r_v.rect_size = Vector2(1, 165); add_child(r_v)
    var rj = ColorRect.new(); rj.color = Color(1.0, 1.0, 1.0); rj.rect_position = Vector2(915, 180); rj.rect_size = Vector2(5, 5); add_child(rj)
    creer_panneaux()

func creer_jauge(pos : Vector2, w : float, coul : Color) -> ColorRect:
    var bg = ColorRect.new(); bg.color = Color(0.15, 0.15, 0.18); bg.rect_position = pos; bg.rect_size = Vector2(w, 16); add_child(bg)
    var bar = ColorRect.new(); bar.color = coul; bar.rect_position = pos; bar.rect_size = Vector2(w, 16); add_child(bar)
    return bar

func ajouter_ile(pts : PoolVector2Array):
    if pts.size() < 3:
        return
    var arr := Array(pts)
    var p0 = arr.pop_front()
    var p1 = arr.pop_front()
    var p2 = arr.pop_front()
    if abs((p1 - p0).cross(p2 - p0)) > 1.2:
        var col_m := Color(0.28, 0.65, 0.34)
        cur_m_s.append(p0); cur_m_s.append(p1); cur_m_s.append(p2)
        cur_m_c.append(col_m); cur_m_c.append(col_m); cur_m_c.append(col_m)

func ajouter_ville(nom : String, pos : Vector2):
    var l = Label.new(); l.text = nom; l.rect_position = pos; l.add_color_override("font_color", Color(1, 0.92, 0.5)); carte_panel.add_child(l)

func creer_panneaux():
    lunette_panel = ColorRect.new(); lunette_panel.color = Color(0.0, 0.05, 0.02, 0.18); lunette_panel.rect_position = Vector2(180, 140); lunette_panel.rect_size = Vector2(920, 480); lunette_panel.visible = false; lunette_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var vise_h = ColorRect.new(); vise_h.color = Color(1.0, 0.15, 0.15, 0.85); vise_h.rect_position = Vector2(10, 240); vise_h.rect_size = Vector2(900, 2); lunette_panel.add_child(vise_h)
    var vise_v = ColorRect.new(); vise_v.color = Color(1.0, 0.15, 0.15, 0.85); vise_v.rect_position = Vector2(460, 10); vise_v.rect_size = Vector2(2, 460); lunette_panel.add_child(vise_v)
    var lbl_s = Label.new(); lbl_s.text = "🔭 LUNETTE SNIPER x4 (VUE DE FACE) — [B] Quitter la lunette | [Clic D / Espace] Tirer"; lbl_s.rect_position = Vector2(220, 18); lunette_panel.add_child(lbl_s)
    add_child(lunette_panel)

    aide_panel = ColorRect.new(); aide_panel.color = Color(0.06, 0.09, 0.14, 0.96); aide_panel.rect_position = Vector2(190, 140); aide_panel.rect_size = Vector2(640, 360); aide_panel.visible = false
    var txt = Label.new(); txt.rect_position = Vector2(24, 20)
    txt.text = "⚙️ COMMANDES — CAILLOU SURVIVAL\n\n🏃 [ZQSD] Bouger | ⚡ [Maj] Sprint | 🔫 [Clic D / Espace] Tirer | 🔄 [R] Recharger / Revivre\n🔀 [Tab] Changer d'arme (5 armes dont Sniper) | 🔭 [B] Lunette Sniper de face\n🪜 [L] Monter à l'échelle (Toit) | 🏠 [V] Entrer Bâtiment | 📦 [E] Fouiller | 🥫 [C] Vivres\n🚙 [F] Véhicule | ⛽ [T] Plein | 🤝 [G] Recruter | 💾 [F5/F9] Sauvegarde | 🗺️ [M] Carte NC"
    aide_panel.add_child(txt); add_child(aide_panel)

    carte_panel = ColorRect.new(); carte_panel.color = Color(0.04, 0.24, 0.36, 0.95); carte_panel.rect_position = Vector2(160, 120); carte_panel.rect_size = Vector2(700, 440); carte_panel.visible = false
    var f_m = File.new()
    if f_m.open("res://nc_carte_rapide.json", File.READ) == OK:
        var jm = JSON.parse(f_m.get_as_text())
        f_m.close()
        if jm.error == OK and typeof(jm.result) == TYPE_DICTIONARY:
            var col_m := Color(0.28, 0.65, 0.34)
            for t in jm.result.get("tris_map", []):
                var a := Array(t)
                cur_m_s.append(Vector2(a.pop_front(), a.pop_front()))
                cur_m_s.append(Vector2(a.pop_front(), a.pop_front()))
                cur_m_s.append(Vector2(a.pop_front(), a.pop_front()))
                cur_m_c.append(col_m); cur_m_c.append(col_m); cur_m_c.append(col_m)
    if cur_m_s.size() >= 3:
        var scr_m := GDScript.new()
        scr_m.source_code = "extends Control\nvar s := PoolVector2Array()\nfunc _draw():\n\tvar col := Color(0.28, 0.65, 0.34)\n\tvar i := 0\n\twhile i + 2 < s.size():\n\t\tvar p0 = s[i]; var p1 = s[i+1]; var p2 = s[i+2]\n\t\tif abs((p1 - p0).cross(p2 - p0)) > 12.0:\n\t\t\tdraw_colored_polygon(PoolVector2Array([p0, p1, p2]), col)\n\t\ti += 3\n"
        scr_m.reload()
        var dessin_m := Control.new()
        dessin_m.set_script(scr_m)
        dessin_m.s = cur_m_s
        carte_panel.add_child(dessin_m)
    ajouter_ville("📍 Îles Bélep", Vector2(75, 42)); ajouter_ville("📍 Koumac", Vector2(145, 88)); ajouter_ville("📍 [F2] Koné / Pouembout", Vector2(210, 160)); ajouter_ville("📍 Poindimié", Vector2(315, 155)); ajouter_ville("📍 [F3] Bourail", Vector2(295, 238)); ajouter_ville("📍 La Foa", Vector2(382, 272)); ajouter_ville("📍 Dumbéa / Païta", Vector2(432, 302)); ajouter_ville("📍 [F1] Nouméa (QG)", Vector2(455, 336)); ajouter_ville("📍 [F4] Île des Pins", Vector2(525, 396)); ajouter_ville("📍 Ouvéa", Vector2(448, 112)); ajouter_ville("📍 [F6] Lifou (Loyauté)", Vector2(505, 160)); ajouter_ville("📍 Maré", Vector2(582, 222))
    add_child(carte_panel)

func maj_texte(pv : float, en : float, ess : float, est_nuit : bool, vague : int, bois : int, metal : int, bidons : int, vivres : int, arme_nom : String, ch : int, res : int, nb_al : int, veh_nom : String):
    barre_pv.rect_size.x = 190.0 * clamp(pv / 100.0, 0.0, 1.0)
    barre_energie.rect_size.x = 190.0 * clamp(en / 100.0, 0.0, 1.0)
    barre_essence.rect_size.x = 190.0 * clamp(ess / 100.0, 0.0, 1.0)
    var moment = "🌙 NUIT — VAGUE " + str(vague) if est_nuit else "☀️ JOUR — VAGUE " + str(vague)
    var auto_txt = "🚙 " + veh_nom + " (" + str(int(ess)) + "%)" if veh_nom != "" else "🏃 À pied ([F] Véhicule)"
    hud_label.text = "❤️ PV: " + str(int(pv)) + " | ⚡ Énergie: " + str(int(en)) + " | ⛽ Essence: " + str(int(ess)) + "% | " + moment + "\n🔫 " + arme_nom + " (" + str(ch) + " | Rés: " + str(res) + ") [Tab/R/B] | 🤝 Escouade: " + str(nb_al) + " | " + auto_txt + "\n🪵 Bois: " + str(bois) + " | 🔩 Métal: " + str(metal) + " | 🛢️ Bidons: " + str(bidons) + " | 🥫 Vivres: " + str(vivres) + " | [L] Échelle [V] Bâtiment [E] Fouiller"
