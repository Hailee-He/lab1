Time Runner

Time Runner is a small 2D action-maze game made in Godot 4.5 for an Advanced Game Design systems-thinking assignment. A full run takes about 3–10 minutes.

Goal

You are trapped in a pixel world with only 60 seconds of frozen time left.

Collect 5 Time Shards to unlock the EXIT door.

Reach the exit before the timer hits 0 or your HP and hearts run out.

Core Systems

HP & Hearts

HP is 0–100%.

You have 3 hearts = 6 half-lives.

At 0 HP, if you still have halves, you revive with full HP and a short invincibility window, respawning near where you were about 2 seconds ago.

Time

Starts at 60s, continuously counts down.

Killing enemies gives a small time bonus.

Reaching 0s is an automatic loss.

Enemies

Chaser (ghost slime): moves through walls, low damage.

Shooter (armored): blocked by walls, higher damage.

Both increase score and time when killed, and are tracked in HUD counters.

Traps & Items

Spike floors: slowly drain HP while you stand on them.

Time Shards: 5 total; light up icons in the HUD and open the door when all are collected.

Medkit + Rock Block: Medkit heals to 100% HP, but drops a rock that blocks the bottom path.

Portal Window: teleports you past the rock if the path is blocked.

HUD & Feedback

Top HUD shows:

Hearts (revives)

HP% bar (color changes with health)

Remaining time (seconds)

Shards collected

Chaser / Shooter kill counts

Almost every system has sound + visual feedback so the game tries to teach itself without external instructions.

Controls

Move: Arrow Keys or WASD

Shoot: SPACE or Left Mouse Button

Menu flow:

Title → 2. Story → 3. Controls & Hints → Game

All transitions use ENTER or SPACE.

Asset Credits

Player character art
From Gun Bonbin by Seryhugo Studios
(seryhugostudios.itch.io/gun-bonbin)

Music
From the shared BGM pack
(Google Drive folder: drive.google.com/drive/folders/1ce8LP87A2Yc1xRLvaCpZr13KI5S-f_Aw)

Other assets
The remaining sprites and sounds come from resources used in my previous course assignments.
