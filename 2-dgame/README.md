# Time Runner

_Time Runner_ is a small 2D action–maze game made in Godot 4.5 for an **Advanced Game Design – Systems Thinking** assignment.  
A full run usually takes about **3–10 minutes**.

---

## Goal

You are trapped in a pixel world with only **60 seconds** of frozen time left.

- Collect **5 Time Shards** to unlock the **EXIT** door.  
- Reach the exit **before the timer hits 0** or your **HP and hearts** run out.

---

## Core Systems

### HP & Hearts

- HP is tracked as **0–100%**.  
- You start with **3 hearts = 6 half-lives**.  
- When HP reaches 0:
  - If you still have any half-hearts, you **revive with full HP**.
  - You get a short **invincibility window**.
  - You respawn near where you were **about 2 seconds ago**, based on a position trail.

### Time

- Starts at **60s** and continuously counts down.  
- **Killing enemies** gives a small **time bonus**.  
- If time reaches 0, you **instantly lose**, no matter how much HP you have.

### Enemies

- **Chaser (ghost slime)**  
  - Can move **through walls**.  
  - Deals **low damage**, but is hard to escape in tight spaces.

- **Shooter (armored enemy)**  
  - **Cannot pass walls**, but deals **higher damage**.  
  - More threatening in open areas and corridors.

Killing either enemy:

- Adds to your **score** and **remaining time**.  
- Updates **separate kill counters** in the HUD (Chaser / Shooter).

### Traps & Items

- **Spike floors**  
  - Slowly **drain HP** while you stand on them.  
  - Encourage careful path planning vs. taking risky shortcuts.

- **Time Shards**  
  - There are **5 total**.  
  - Each shard lights up an icon in the HUD.  
  - When all 5 are collected, they **signal the door to open**.

- **Medkit + Rock Block combo**  
  - The Medkit heals you to **100% HP**.  
  - But taking it causes a **Rock Block** to fall and **seal the lower path**, creating a trade-off:
    - Heal now vs. making navigation harder later.

- **Portal Window**  
  - A one-way **teleport** that lets you **escape past the Rock Block** if the corridor is blocked.

---

## HUD & Feedback

The **top HUD** shows:

- **Hearts** – remaining half-revives (3 hearts = 6 halves).  
- **HP% bar** – color changes from green → yellow → red as health gets low.  
- **Timer** – remaining time in seconds.  
- **Shard icons** – light up as you collect Time Shards.  
- **Kill counters** – number of Chasers and Shooters defeated.

Almost every system has **both sound and visual feedback** (animations, color changes, SFX), so the game **tries to teach itself through play** without needing an external manual.

---

## Controls

- **Move**: Arrow Keys or **WASD**  
- **Shoot**: **SPACE** or **Left Mouse Button**

### Menu Flow

1. **Title** – game name.  
2. **Story** – short narrative + main goal.  
3. **Controls & Hints** – controls, enemy types, traps, and HUD explanation.  
4. **Game** – the actual run.

All transitions use **ENTER** or **SPACE**.

---

## Systems Thinking Notes

This project focuses on **interconnected systems and meaningful trade-offs**:

- **Time ↔ Enemies**  
  - Killing enemies is risky but gives **extra time**, encouraging aggressive play for skilled players.

- **HP / Hearts ↔ Hazards & Revives**  
  - Spike floors, enemies, and Medkits all interact with HP and the revive system, creating tension between safety and speed.

- **Progression ↔ Level Geometry**  
  - Time Shards, the EXIT door, Rock Block, and Portal Window form a small **puzzle system**:
    - Healing with the Medkit makes survival easier,
    - but also changes the **level topology** and forces players to adapt their route.

---

## Asset Credits

- **Player character art**  
  From _Gun Bonbin_ by Seryhugo Studios  
  <https://seryhugostudios.itch.io/gun-bonbin>

- **Music**  
  From the shared BGM pack  
  <https://drive.google.com/drive/folders/1ce8LP87A2Yc1xRLvaCpZr13KI5S-f_Aw>

- **Other assets**  
  Remaining sprites and sound effects come from resources used in my previous course assignments 
