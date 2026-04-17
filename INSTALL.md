# Heroes Guild Plugin — Install Guide

## Prerequisites

- AresMUSH server (tested against current stable release)
- Admin access to the server file system and in-game admin account
- The Jobs plugin enabled (core plugin — enabled by default)
- The Scenes plugin enabled (core plugin — enabled by default)

---

## Step 1 — Copy Plugin Files

```
plugin/  →  aresmush/plugins/heroesguild/
```

Copy the entire `plugin/` directory to `aresmush/plugins/heroesguild/`. The result should be:

```
aresmush/plugins/heroesguild/
  heroesguild.rb
  engine.rb
  helpers.rb
  commands/
  models/
  web/
  help/
  locale/
```

---

## Step 2 — Copy Config Files

```
game/config/heroesguild.yml       →  aresmush/game/config/heroesguild.yml
game/config/heroesguild_chargen.yml  (do NOT copy — see Step 4)
```

---

## Step 3 — Register the Plugin

Add `heroesguild` to the enabled list in `aresmush/game/config/plugins.yml`:

```yaml
plugins:
  - # ... existing plugins ...
  - heroesguild
```

---

## Step 4 — Add the Chargen Stage

`heroesguild_chargen.yml` cannot be installed as a standalone file. Open `aresmush/game/config/chargen.yml` and add the `hg-gimmick` stage at the appropriate position in the chargen flow (after the Groups stage, before app review):

```yaml
stages:
  # ... existing stages (groups, background, etc.) ...
  hg-gimmick:
    help: heroesguild-gimmick
  # ... remaining stages ...
```

---

## Step 5 — Add the Playbook Group

Open `aresmush/game/config/groups.yml` and add a `Playbook` group with the role names as values. These must match the role keys in `heroesguild.yml` exactly (case-sensitive):

```yaml
groups:
  # ... existing groups ...
  Playbook:
    default: ''
    values:
      - Meatshield
      - Shadowfoot
      - Arcanist
      - Heartspeaker
      - Wildcardigan
```

---

## Step 6 — Install Custom Files

Each file in `custom_files/` merges into an existing AresMUSH plugin file. For each:

| Source | Destination |
|---|---|
| `custom_files/custom_char_fields.rb` | `aresmush/plugins/profile/custom_char_fields.rb` |
| `custom_files/custom_app_review.rb` | `aresmush/plugins/chargen/custom_app_review.rb` |
| `custom_files/custom_scene_data.rb` | `aresmush/plugins/scenes/custom_scene_data.rb` |
| `custom_files/profile-custom-tabs.hbs` | `aresmush/webportal/app/templates/components/profile-custom-tabs.hbs` |
| `custom_files/profile-custom.hbs` | `aresmush/webportal/app/templates/components/profile-custom.hbs` |
| `custom_files/profile-custom.js` | `aresmush/webportal/app/components/profile-custom.js` |
| `custom_files/chargen-custom-tabs.hbs` | `aresmush/webportal/app/templates/components/chargen-custom-tabs.hbs` |
| `custom_files/chargen-custom.hbs` | `aresmush/webportal/app/templates/components/chargen-custom.hbs` |
| `custom_files/chargen-custom.js` | `aresmush/webportal/app/components/chargen-custom.js` |
| `custom_files/live-scene-custom-play.hbs` | `aresmush/webportal/app/templates/components/live-scene-custom-play.hbs` |
| `custom_files/live-scene-custom-play.js` | `aresmush/webportal/app/components/live-scene-custom-play.js` |
| `custom_files/custom-routes.js` | `aresmush/webportal/app/custom-routes.js` |
| `custom_files/custom.scss` | `aresmush/webportal/app/styles/custom.scss` |

**If any of these files already have content,** merge the Heroes Guild additions in rather than overwriting. In particular:

- `custom_char_fields.rb` — add the `fields[:heroesguild] = ...` line inside the existing `get_fields` method.
- `custom_app_review.rb` — add the Heroes Guild errors to the existing `app_review` method's errors array.
- `custom_scene_data.rb` — merge the `:heroesguild` key into the existing returned hash.
- `custom-routes.js` — add the four routes to the existing exported array.
- `custom.scss` — append the Heroes Guild style blocks to the bottom of the file.
- `profile-custom-tabs.hbs` / `chargen-custom-tabs.hbs` — add the new `<li>` alongside existing tabs.
- `profile-custom.hbs` / `chargen-custom.hbs` — wrap new content in its own `{{#if}}` block.
- `profile-custom.js` / `chargen-custom.js` — merge actions into the existing component's `actions` hash.
- `live-scene-custom-play.hbs` — add new `<li>` items inside the existing play menu list.
- `live-scene-custom-play.js` — merge actions into the existing component.

---

## Step 7 — Jobs Integration (no action required)

Leads automatically open a Jobs ticket when created via `+investigate`. No configuration is needed — the plugin uses the existing Jobs system's default category (`Jobs.request_category`). Each lead's ticket receives IC comments as clues are added and when the lead is closed or converted.

---

## Step 8 — Install Web Portal Files

```
webportal/routes/    →  aresmush/webportal/app/routes/
webportal/templates/ →  aresmush/webportal/app/templates/
webportal/components/ →  aresmush/webportal/app/components/
```

Copy all four route files, all templates (Guild Board, Dungeon HUD, Tavern HUD, Job Board), and all four component JS files.

---

## Step 9 — Add the Navigation Link

Open `aresmush/game/config/website.yml` and add the Guild Board link under `top_navbar`:

```yaml
top_navbar:
  - title: Guild
    menu:
      - title: Guild Board
        route: heroesguild-board
```

---

## Step 10 — Reload the Server

From in-game as an admin:

```
load heroesguild
```

Or do a full server restart if this is a first install.

---

## Step 11 — Verify Installation

Run these checks in-game and in the web portal:

```
+sheet                  → should show empty HG sheet for your character
help roll               → should show roll help file
help heroesguild-gimmick → should show chargen help
```

Web portal checks:
- Navigate to `/heroesguild/board` — should show the Guild Board (empty is fine)
- Navigate to `/heroesguild/jobs` — should still work (backward compat)
- Go through chargen — the Playbook Setup stage should appear after Groups
- View a character profile — a "Playbook" tab should appear if the character has a Playbook set

---

## Playbook Setup (After Install)

Once installed, players must complete chargen in this order:

1. **Groups stage** — select a Playbook value (Meatshield, Shadowfoot, etc.)
2. **Playbook Setup stage (hg-gimmick)** — click "Auto-Populate Playbook Stats", then select a Gimmick
3. App review checks both steps

Characters who already exist before installing need to have their stats initialized manually. An admin can use `+admin/char <name>=heroesguild` or set stats directly via the web portal chargen route once it's installed.

---

## Running a Dungeon

1. Start a scene in a room.
2. From the scene play menu → **Start Dungeon Run** (opens Dungeon HUD in a new tab).
3. In the HUD: select a contract from the board to activate the run.
4. Players roll moves in-game (`+move <name>`) or via the HUD move roller.
5. Doom advances automatically on misses. GM controls in the HUD advance doom, trigger threats, and mark progress manually.
6. Mark progress until complete, or end the run to abandon it.

## Running a Tavern Night

1. Start a scene in a tavern room.
2. From the scene play menu → **Open Tavern Night** (opens Tavern HUD in a new tab).
3. Players use `+carouse`, `+imbibe`, `+sober`, `+investigate` in-game, or the action buttons in the HUD.
4. Inebriation and Vibe are tracked per-session in the HUD; Stress is on the character.
5. Leads generated by Investigate accumulate clues. When enough clues are marked, the lead auto-converts to a posted contract.
6. Close the night from the HUD or with `+admin`.

---

## Uninstall

1. Remove `heroesguild` from `plugins.yml`.
2. Remove `aresmush/plugins/heroesguild/`.
3. Remove `heroesguild.yml` from `game/config/`.
4. Remove the `hg-gimmick` stage from `chargen.yml`.
5. Remove the `Playbook` group from `groups.yml`.
6. Revert the custom files (remove Heroes Guild additions or restore backups).
7. Remove the web portal files added in Step 7.
8. Redis data (Character attributes, DungeonRun, TavernNight records) will persist but are inert with the plugin removed.
