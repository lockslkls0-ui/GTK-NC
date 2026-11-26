# 🎮 RAPPORT COMPLET & ARCHITECTURE : CAILLOU SURVIVAL (V0.1)
**Auteur & Créateur :** lockslkls | **Moteur :** Godot Engine 3.5 (OpenGL 3.3 / GLES2)
**Plateforme Cible :** Linux (Optimisé Intel Core i3-2350M / Intel HD 3000 / 8 Go RAM)

---

## 1. VISION & CONCEPT DU JEU
**Caillou Survival** est un jeu de **survie urbaine, d'exploration, de stratégie et de barricades** se déroulant sur la **vraie carte géographique de la Nouvelle-Calédonie** (Nouméa, Anse Vata, Brousse, lagon).

### Mécaniques Principales (Boucle Jour / Nuit)
* **Le Jour (Exploration & Collecte) :**
  * Le joueur explore les vraies rues et les vrais bâtiments de Nouméa importés depuis OpenStreetMap (`carte_noumea.json`).
  * Fouille des bâtiments (supermarchés, stations-service, ateliers) pour récolter : **Bois/Palettes**, **Tôle ondulée**, **Carburant**, **Vivres/Eau** et **Composants électriques**.
* **La Stratégie & Construction (Barricades & Énergie) :**
  * Pose libre de barricades modulaires dans les rues pour bloquer les accès et créer des goulots d'étranglement.
  * Gestion d'un **groupe électrogène** (alimentation des projecteurs halogènes et pièges électriques la nuit).
* **La Nuit (Défense & Survie) :**
  * Obscurité dynamique (seules les lampes torches, feux de camp et projecteurs éclairent la zone).
  * Vagues d'assaillants fictifs (drones de sécurité détraqués / créatures de quarantaine nocturne) qui testent la solidité des barricades jusqu'au lever du soleil.

---

## 2. ARCHITECTURE TECHNIQUE & OPTIMISATION MATÉRIELLE
Calibré pour tourner à **60 FPS constants** sans surchauffe CPU sur PC portable modeste :
* **Moteur Godot 3.5 (Rendu GLES2 / Compatibility)** : Zéro dépendance Vulkan lourde, démarrage en 1 seconde.
* **Pipeline Cartographique Réel (Python + OpenStreetMap)** :
  * Extraction des polygones réels des bâtiments (`way["building"]`) et des tracés routiers (`way["highway"]`).
  * Projection GPS (Latitude/Longitude) vers coordonnées locales en mètres `(X, Y)` centrées sur le quartier choisi.
* **Rendu 2.5D / Top-Down Stylisé** :
  * Routes asphaltées, trottoirs, bâtiments avec ombres portées et toitures colorées, eau animée du lagon.

---

## 3. FEUILLE DE ROUTE DE DÉVELOPPEMENT (5 PHASES)
* **Phase 1 — Moteur Cartographique Réel (En cours) :** Importation de `carte_noumea.json` dans Godot, rendu des vraies routes et bâtiments d'Anse Vata, et déplacement fluide du survivant avec collisions.
* **Phase 2 — Système de Barricades & Construction :** Inventaire rapide (1 à 5), prévisualisation fantôme au curseur, pose et amélioration des barricades (Bois -> Tôle -> Barbelés/Électrique).
* **Phase 3 — Cycle Jour/Nuit & Lumières Dynamiques :** Horloge 24h accélérée, assombrissement progressif, lampe torche directionnelle et projecteurs sur groupe électrogène.
* **Phase 4 — IA des Vagues Nocturnes & Pathfinding :** Navigation intelligente des ennemis autour des bâtiments réels, attaque des barricades et système de réparation.
* **Phase 5 — Multi-Quartiers NC & Export Standalone :** Sélecteur de quartier (Anse Vata, Centre-Ville, Dumbéa, Koné/Pouembout), sauvegarde de partie et export exécutable Linux/Windows.

---

## 4. EXTENSION DU CAHIER DES CHARGES (V0.6 — MÉCANIQUES AVANCÉES)
* **Territoire Intégral & Chunks Dynamiques (`nc_territoire.json` + `ChunksNC.gd`) :**
  * Rendu de toute la Grande Terre (Bélep -> Île des Pins) + Îles Loyauté (Ouvéa, Lifou, Maré) et génération infinie de routes, villages de brousse, stations et arbres lors des déplacements.
* **Verticalité & Intérieurs Réels (`Batiments.gd`) :**
  * Escalade réelle sur les toits (`[L]`) avec avantage hauteur pour le Sniper (`[B]` lunette optique + décalage caméra) et entrée dans les intérieurs meublés (`[V]`).
* **Économie, QG Fortifié & Explosifs (`EconomieQG.gd`) :**
  * Monnaie locale (Francs CFP), Boutique de survie (`[P]`), QG aménageable avec coffre de stockage (`[K]`/`[O]`) et explosifs artisanaux (`[X]`).
* **Missions Géolocalisées & Dialogues PNJ (`MondeVivant.gd` + `PNJDialogues.gd`) :**
  * Générateur de 1000+ missions (Sauvetage de civils, Défense chronométrée 25s, Convoi, Station) sur les vrais quartiers de Nouméa avec boussole et dialogues (`[Y]`).
* **Combat Réel, Balistique & Escouade :**
  * 5 armes (Pistolet, Pompe, Assaut, Machette, Sniper), tirs ennemis qui blessent le joueur et endommagent les véhicules, et recrutement d'escouade illimité (`[G]`).
