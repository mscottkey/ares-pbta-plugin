> **+dungeon** — Manage an active Dungeon Run

**Usage**
```
+dungeon/start <run id>
+dungeon/doom
+dungeon/threat
+dungeon/progress <boxes>
+dungeon/end
```

Most dungeon management happens through the Dungeon HUD (opened from the scene play menu). These game commands are available as fallbacks.

**Switches**
- `/start <id>` — Activate a pending Dungeon Run (must be in status "pending").
- `/doom` — Manually advance the Doom clock by 1. Active run only.
- `/threat` — Emit a random environmental threat.
- `/progress <boxes>` — Mark progress boxes on the current run. Completes the run if the max is reached.
- `/end` — End the current run. If not already complete, marks it failed and returns the contract to the board.

**Doom thresholds**
- **4 — Alert:** 7-9 results also deal 1 Stress.
- **7 — Hostile:** GM introduces environmental threats.
- **10 — Lethal:** All characters must Defy Danger just to remain in the room.

**See also:** +contract, +roll, +move
