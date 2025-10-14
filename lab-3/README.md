 Lab 3
 

Overview

A tiny 2D platformer. Collect 8 gems and touch the flag to level up. On the way you face slimes, spikes, and falling rocks; a medkit can heal you. The project demonstrates Health, Damage, and Respawn systems with clear feedback.

Controls

Move: A/D or ←/→

Jump: Space (also W / ↑)

Goal: Gems 8/8 → touch flag → Level Up

What’s Implemented (maps to Lab 3)

Health System

Hearts UI (top-left), red screen flash, hit SFX, brief i-frames.

health_changed signal; death anim → died signal.

Hazards

Spikes (Area2D): contact damage + knockback + cooldown.

Slime (patrolling enemy): damages via Hitbox.

Falling Rock (RigidBody2D): drops when triggered; optional delay/one-shot.

Respawn

Checkpoint flag saves position (and health pips).

On death: smooth delay → respawn at checkpoint; GameOver SFX/BGM resume.

Feedback & Audio

HUD shows hearts and Gems: X / 8.

SFX: hit, jump, success, game over, level up; looping BGM.

Audio routed to Music and SFX buses.

Code/Scene Organization

player.gd – movement, hearts, damage, signals.

hud.gd – hearts & gem counter + hit flash.

main.gd – gem count, checkpoint/respawn, audio helpers.

checkpoint.gd – activate + notify level (plays level-up if 8/8).

gem.gd, spike.gd, slime.gd, rock.gd – pickups & hazards.

Collision layers (summary):
1 Player, 2 World, 3 Enemy, 4 Hazard/Hitbox, 5 PlayerHurtbox.
Player collides with World only; hazards use Area2D to avoid sticking.

