# Lab 4: Walking Sim

## Overview

Explore a mysterious subway station and experience an unsettling narrative through environmental storytelling. When drowsiness overcomes you in the metro carriage, sit on the platform bench to rest and progress the story. The project demonstrates immersive 3D atmosphere, spatial audio, and environmental narrative systems.

## Controls

**Movement:** W/A/S/D  
**Look:** Mouse movement  
**Interact:** E (when prompt appears)

**Goal:** Enter metro carriage → Feel sleepy → Sit on bench → Experience the story unfold

### Environmental Storytelling System
- No text or dialogue - narrative told purely through environment
- Spatial audio cues and lighting changes convey the story
- Emotional progression from normal to unsettling atmosphere

### Interactive Elements
- **Metro Carriage:** Triggers drowsiness state when entered
- **Bench:** Progresses story when interacted with while drowsy
- **Dynamic Lighting:** Flickering lights and emergency lighting shifts mood

### Player Systems
- First-person movement with head bobbing and footstep sounds
- Automatic collision generation for all environment meshes
- Smooth camera controls with mouse look

### Audio Atmosphere
- **SFX:** Footsteps, breathing, environmental sounds, horror cues
- **Spatial Audio:** 3D positioned sounds enhance immersion
- **Audio Transitions:** Seamless shifts between normal and horror sequences

### Visual Feedback
- Blinking effects when tired
- Smooth fade transitions between scenes
- Dynamic lighting that responds to narrative progression

## Code/Scene Organization

**player.gd** – First-person movement, camera control, footstep sounds  
**gamemanager.gd** – Story progression, audio management, scene transitions  
**flickeringlight.gd** – Dynamic lighting effects and emergency lighting  
**autocollisiongenerator.gd** – Automatic mesh collision generation  

**Scene Structure:**
- Subway station environment with metro carriage and platform
- Carefully composed spaces guiding player naturally
- Trigger zones for story progression

## Technical Implementation

- **Collision Layers:** Automated system prevents walk-through walls
- **Performance:** Optimized 3D environment with proper scene organization
- **Audio Routing:** Separate buses for environmental sounds and horror effects

## Assets & Credits

**3D Models & Environment:** https://elbolilloduro.itch.io/metro
https://elbolilloduro.itch.io/6twelve
**Audio:** https://nox-sound-design.itch.io/essentials-series-sfx-nox-sound
https://taira-komori.net/freesoundcn.html
