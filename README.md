# ares-pbta-plugin

A generic [Powered by the Apocalypse](https://en.wikipedia.org/wiki/Powered_by_the_Apocalypse) engine for [AresMUSH](https://www.aresmush.com/).

This plugin provides the core PbtA loop — stats, rolls, moves, XP, stress, advancement, chargen, and a character sheet — as a reusable base layer. Game-specific content (dungeon runs, tavern sessions, investigation leads) lives in a separate overlay plugin that calls into this one.

---

## What's Included

**Engine**
- `+roll <stat> [+/-N]` — 2d6 + stat + modifier, emits result with tier (10+/7-9/6-)
- `+move <name>` — named move roll; validates access, looks up stat and description
- `+sheet [name]` — character sheet with stats, stress/XP tracks, and move list
- `+advance/stat <stat>` or `+advance/move <name>` — spends 10 XP to raise a stat (+1, max +3) or learn a move

**Character Model** (extensions to the Ares `Character` class)
- `pbta_role` — Playbook name (set during chargen)
- `pbta_stats` — hash of five stats (brawn, cunning, flow, heart, luck)
- `pbta_gimmick` — selected Gimmick name
- `pbta_moves` — moves learned via advancement
- `pbta_xp`, `pbta_stress` — Integer trackers

**Web Portal**
- Playbook tab on the character profile (stats, stress/XP pip tracks, moves)
- Chargen stage (`hg-gimmick`) for Playbook stat init and Gimmick selection
- Web API handlers: `initHeroesGuildStats`, `setHeroesGuildRole`, `setHeroesGuildGimmick`, `heroesguildChargenData`

**Configuration** — `game/config/pbta.yml`
- Roles (stats, core moves, description)
- Gimmicks (stat bonuses, location gates, move bonuses)
- Universal and role-specific move tables
- Doom threshold definitions
- `stress_max`, `xp_to_advance`

---

## PbtA Mechanics

| Roll | Result |
|---|---|
| 10+ | Strong hit |
| 7–9 | Weak hit |
| 6– | Miss — gain 1 XP; doom advances if in an active run |

**Doom** escalates at thresholds 4 (Alert), 7 (Hostile), and 10 (Lethal). At Alert and above, weak hits also deal 1 Stress.

**Advancement** requires 10 XP. Use `+advance/stat` or `+advance/move`. Stats cap at +3. XP resets to 0 on advance.

**Gimmicks** grant passive bonuses — to a specific stat, to a specific move, or only when in a particular location (by room name substring).

---

## Installation

### 1. Copy plugin files

```
plugin/  →  aresmush/plugins/pbta/
```

The directory should contain:

```
aresmush/plugins/pbta/
  pbta.rb
  engine.rb
  helpers.rb
  commands/
  models/
  web/
  help/
  locale/
```

### 2. Copy config files

```
game/config/pbta.yml         →  aresmush/game/config/pbta.yml
```

`pbta_chargen.yml` is not a standalone config — see step 4.

### 3. Register the plugin

Add `pbta` to `aresmush/game/config/plugins.yml`:

```yaml
plugins:
  - pbta
```

### 4. Add the chargen stage

Open `aresmush/game/config/chargen.yml` and add the `hg-gimmick` stage after the Groups stage:

```yaml
stages:
  # ... existing stages ...
  hg-gimmick:
    help: heroesguild-gimmick
  # ... remaining stages ...
```

### 5. Add the Playbook group

Open `aresmush/game/config/groups.yml` and add a `Playbook` group whose values match the role keys in `pbta.yml` exactly (case-sensitive):

```yaml
groups:
  Playbook:
    default: ''
    values:
      - Meatshield
      - Shadowfoot
      - Arcanist
      - Heartspeaker
      - Wildcardigan
```

Replace these values with your own role names if you've customized `pbta.yml`.

### 6. Install custom files

Each file in `custom_files/` drops into an existing AresMUSH file. If those files already have content, merge rather than overwrite.

| Source | Destination |
|---|---|
| `custom_files/custom_char_fields.rb` | `aresmush/plugins/profile/custom_char_fields.rb` |
| `custom_files/custom_app_review.rb` | `aresmush/plugins/chargen/custom_app_review.rb` |
| `custom_files/custom-routes.js` | `aresmush/webportal/app/custom-routes.js` |
| `custom_files/custom.scss` | `aresmush/webportal/app/styles/custom.scss` |
| `custom_files/profile-custom-tabs.hbs` | `aresmush/webportal/app/templates/components/profile-custom-tabs.hbs` |
| `custom_files/profile-custom.hbs` | `aresmush/webportal/app/templates/components/profile-custom.hbs` |
| `custom_files/profile-custom.js` | `aresmush/webportal/app/components/profile-custom.js` |
| `custom_files/chargen-custom-tabs.hbs` | `aresmush/webportal/app/templates/components/chargen-custom-tabs.hbs` |
| `custom_files/chargen-custom.hbs` | `aresmush/webportal/app/templates/components/chargen-custom.hbs` |
| `custom_files/chargen-custom.js` | `aresmush/webportal/app/components/chargen-custom.js` |

Merge notes:
- `custom_char_fields.rb` — add the `fields[:heroesguild] = PbtA::CharProfileWeb.get_fields(...)` line inside `get_fields`
- `custom_app_review.rb` — add the PbtA errors into the existing `errors` array
- `custom-routes.js` — this plugin adds no routes; leave your existing array unchanged
- `custom.scss` — append PbtA style blocks to the bottom

### 7. Reload

From in-game as an admin:

```
load pbta
```

Or do a full restart on first install.

### 8. Verify

```
+sheet             → empty PbtA sheet for your character
help roll          → roll help file
help move          → move help file
```

Web portal: go through chargen — the Playbook Setup stage should appear after Groups, allow stat initialization, and offer a Gimmick picker.

---

## Configuration Reference (`pbta.yml`)

### Roles

```yaml
roles:
  RoleName:
    desc: "One-line flavor text."
    stats: { brawn: 2, heart: 1, flow: 0, cunning: -1, luck: 0 }
    core_moves: ["Move One", "Move Two", "Defy Danger"]
```

Stat values at chargen typically sum to 2. Core moves are available to all characters of that role without spending XP.

### Gimmicks

```yaml
gimmicks:
  Gimmick Name:
    desc: "Player-visible description."
    bonus_stat: luck         # Which stat gets the bonus
    bonus_value: 1           # How much (omit if location_required is set — bonus is always 1)
    location_required: Tavern  # Room name must include this string (optional)
    move_bonus: "Move Name"    # Bonus applies when rolling this specific move (optional)
```

### Moves

```yaml
moves:
  universal:       # Available to all roles
    Move Name:
      stat: flow
      desc: "Trigger condition and outcome text."
  role_specific:   # Available only to roles that list it in core_moves, or via advancement
    Other Move:
      stat: brawn
      desc: "..."
```

### Doom thresholds

```yaml
doom_thresholds:
  4:
    label: Alert
    effect: "Weak hits also deal 1 Stress."
  7:
    label: Hostile
    effect: "GM introduces an environmental threat."
  10:
    label: Lethal
    effect: "All characters must Defy Danger just to remain."
```

### Other settings

```yaml
stress_max: 5       # Max stress a character can hold
xp_to_advance: 10   # XP required to trigger an advancement
```

---

## Building an Overlay Plugin

This plugin exposes its API under the `AresMUSH::PbtA` namespace.

### Engine (`PbtA::Engine`)

```ruby
# Core dice roll. Returns { total:, tier: :strong/:weak/:miss, dice: [d1,d2], stat_val:, modifier: }
PbtA::Engine.roll(stat_value, modifier = 0)

# Apply post-roll consequences to a character (XP on miss, stress on weak if doom >= 4).
# Returns { xp_bump:, new_xp:, advance_ready:, stress_bump:, new_stress:, stress_max: }
# Caller is responsible for all t() translations.
PbtA::Engine.consequence_data(char, result, doom_level = 0)

# Increment doom on any model that has a doom_level attribute.
# Returns { new_doom:, threshold: :alert/:hostile/:lethal/nil }
PbtA::Engine.advance_doom(container)

# Returns the formatted ANSI roll output string.
PbtA::Engine.format_roll(char_name, move_name, stat_name, result)
```

### Helpers (`PbtA`)

```ruby
# Effective stat value, including any active Gimmick bonus.
PbtA.stat_value(char, stat_name, move_name: nil, room_name: nil)

# Move config hash (universal or role-specific), or nil.
PbtA.find_move(move_name)

# True if the character has the move (core or learned).
PbtA.char_has_move?(char, move_name)

# Base stat hash for a role name.
PbtA.role_stats(role_name)

# Move list as an array of { name:, stat:, desc: } hashes for web display.
PbtA.char_moves_for_web(char)
```

### Doom advancement in overlay commands

`roll_cmd.rb` and `move_cmd.rb` check for a `HeroesGuild.active_dungeon_run` method at runtime and skip doom advancement if the overlay plugin isn't loaded. To wire up doom in your own overlay, define:

```ruby
module AresMUSH
  module YourPlugin
    def self.active_dungeon_run(room)
      # Return whatever model tracks your active session, or nil.
    end
  end
end
```

Then alias or patch the `defined?(HeroesGuild)` guard in the roll/move commands to reference your module instead.

### Character model extension

`pbta_char_model.rb` defines the core PbtA attributes on `Character`. If your overlay plugin has models that reference `Character` (e.g., session participants, leads), add their `collection` declarations in your own model extension file rather than modifying this plugin:

```ruby
# yourplugin/plugin/models/char_extensions.rb
module AresMUSH
  class Character
    collection :your_records, "AresMUSH::YourModel"
  end
end
```

---

## Uninstall

1. Remove `pbta` from `plugins.yml`.
2. Remove `aresmush/plugins/pbta/`.
3. Remove `pbta.yml` from `game/config/`.
4. Remove the `hg-gimmick` stage from `chargen.yml`.
5. Remove the `Playbook` group from `groups.yml`.
6. Revert or clean up the merged custom files.
7. Redis data (`pbta_*` attributes on Character) persists but is inert.
