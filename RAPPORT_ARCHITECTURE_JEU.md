# 🌴 CAHIER DES CHARGES & SUIVI INTÉGRAL DE A À Z — GTK-NC (CAILLOU SURVIVAL)
**Créateur :** lockslkls | **Moteur :** Godot Engine 3.5 (GLES2) | **Territoire :** Grande Terre, Nouméa, Îles Loyauté, Île des Pins, Bélep

---

## ✅ PARTIE 1 : CE QUI EST DÉJÀ FAIT ET VALIDÉ (PALIERS 1 À 14)
* **Palier 1–4 — Cartographie Réelle Intégrale de la Nouvelle-Calédonie :**
  * Côtes maître complètes (41 557 triangles), Chaîne Centrale & latérite du Sud, plages dorées avec vagues animées.
  * 456 594 segments de routes (RT1, RT2, RT3), pistes minières et sentiers de brousse.
  * 95 550 bâtiments réels en 2.5D avec collisions dynamiques autour du joueur, toits accessibles (`[L]`) et intérieurs (`[V]`).
* **Palier 5–10 — Hydrographie, Forêts & Relief Réels :**
  * 52 417 segments de fleuves/rivières/criques, 3 494 lacs/barrages/marais/piscines au millimètre près.
  * 57 383 triangles de massifs forestiers, 320 122 arbres 2.5D récoltables (`+5 bois` + `12 XP`) et 322 sommets nommés avec altitude.
* **Palier 11–12 — Enseignes Réelles & Symboles Vectoriels :**
  * 863+ lieux réels géolocalisés avec icônes dédiées : 631 magasins/commerces, stations-service, 47 postes de police/gendarmeries et 185 hôpitaux/pharmacies/dispensaires (`[E]` pour interagir).
* **Palier 13–14 — Scénario Tribu Houaïlou, Missions Terrain, XP/Armure/Vie Véhicule & Combat :**
  * Démarrage en tribu à Houaïlou (Tribu de Nédiouen -> Coutumier Téin à Néâria).
  * 8 variantes de missions (entraide tribu, ravitaillement magasin, secours dispensaire, convoyage avec 4x4 éclaireur PNJ vert, gendarmerie, secours en mer îlots/Lifou, défense captage) avec **exécution réelle obligatoire + validation par dialogue PNJ `[Y]`**.
  * Barre d'XP & Niveaux (missions, actions & exploration tous les 500 m), Armure selon équipement (`Tenue Tribu` -> `Gilet Tactique 100%`), Vie des véhicules (`pv_veh`), lampe torche plein jour (`[U]`), briquet feu de camp (`[B]`), balles traçantes lumineuses (`[Clic Gauche]`), bombes avec onde de choc et cratère noir au sol (`[X]`), voyages rapides (`[F1]` à `[F7]`).

---

## 🛠️ PARTIE 2 : CE QUI RESTE À FAIRE (PALIERS 15 À 18)
* **Palier 15 — Trafic & Navigation Vivants (Terre & Mer) :**
  * Remplacer les voitures simples du trafic par les beaux sprites détaillés (4x4, berlines, bateaux avec passagers dans les ports et sur le lagon) réquisitionnables en marche avec `[F]`.
  * Densifier la population civile sur Nouméa/Grand Nouméa tout en gardant la brousse calme et authentique.
* **Palier 16 — Téléphone / Radio Interactif du Clan (`[P]`) & Renforts :**
  * Interface visuelle de téléphone/radio permettant de recevoir des appels d'urgence des tribus, choisir une mission à distance ou appeler les cousins/le clan en renfort.
* **Palier 17 — Construction Modulaire de Cabane / Faré & Camp Fortifié :**
  * Aperçu fantôme au curseur avant pose (`[Clic Droit]`), murs fermés avec porte, établi de fabrication avancée et groupe électrogène.
* **Palier 18 — Export Exécutable Standalone (Linux / Windows) :**
  * Empaquetage final `.x86_64` / `.exe` autonome jouable en un double-clic sans ouvrir Godot.
