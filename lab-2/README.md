# Lab 2

**Theme:** Complex group motion (flocking/swarming) from simple local rules.  


---

## How to Run
1. Open the project in Godot.
2. Controls: WASD / Arrow Keys to move the player.

---

## What to Observe
- **20+ wisps** at start (spawner grows up to ~60).
- Each wisp makes **local decisions only** (no central controller):
  - Separation / Alignment / Cohesion
  - Player avoidance + small random jitter
- When **N wisps** naturally cluster inside **SecretZone**, the **Tombstone** opens and the scene changes → local interaction triggers a global event (emergence).

---

## Tunable Parameters (Inspector)
`separation_weight, alignment_weight, cohesion_weight, avoid_player_weight,`
`separation_distance, player_avoid_distance, perception_radius,`
`max_speed, max_force, random_jitter`

> Small changes produce clearly different group patterns (tight flock, loose swarm, splitting around player, etc.).

---

## Main Files
- `scenes/Environment.tscn` – main scene (spawner, player, secret zone, tombstone)
- `scenes/WillOWisp.tscn` – agent scene (Area2D **Sensor** for neighbor sensing)
- `scripts/WillOWisp.gd` – flocking rules + avoidance + jitter
- `scripts/WispSpawner.gd` – spawns agents only (no behavior control)
- `scripts/Player.gd`, `scripts/SecretZone.gd`, `scripts/Tombstone.gd`, `scripts/EnvironmentSound.gd`

---

## Assets
- **Images:** all from [OpenGameArt.org](https://opengameart.org/)
- **Audio:** all from [Freesound.org](https://freesound.org/)
> Assets follow their respective site licenses (e.g., CC0 / CC-BY). Used here for course/demo only.
