module AresMUSH
  module HeroesGuild

    # ── Stat & Move Helpers ──────────────────────────────────────────────────

    # Returns the character's effective stat value, applying Gimmick bonuses.
    def self.stat_value(char, stat_name, move_name: nil, room_name: nil)
      base = (char.pbta_stats[stat_name] || 0).to_i
      gimmick = char.pbta_gimmick
      return base unless gimmick

      gimmick_config = Global.read_config("heroesguild", "gimmicks")[gimmick]
      return base unless gimmick_config

      bonus = 0
      if gimmick_config["bonus_stat"] == stat_name
        if gimmick_config["location_required"]
          bonus = 1 if room_name&.include?(gimmick_config["location_required"])
        else
          bonus = gimmick_config["bonus_value"].to_i
        end
      end
      bonus = 1 if move_name && gimmick_config["move_bonus"] == move_name
      base + bonus
    end

    # Returns the move config hash for a named move, or nil.
    def self.find_move(move_name)
      moves = Global.read_config("heroesguild", "moves")
      moves["universal"][move_name] ||
        moves["role_specific"][move_name]
    end

    # Returns true if the character has access to a given move.
    def self.char_has_move?(char, move_name)
      return true if char.pbta_moves.include?(move_name)
      role = char.pbta_role
      return false unless role
      role_config = Global.read_config("heroesguild", "roles")[role]
      return false unless role_config
      role_config["core_moves"].include?(move_name)
    end

    # Returns the role's base stat hash for a given role name.
    def self.role_stats(role_name)
      role_config = Global.read_config("heroesguild", "roles")[role_name]
      role_config ? role_config["stats"] : {}
    end

    # ── Container Lookups ────────────────────────────────────────────────────

    # Returns the active TavernNight for a given room, or nil.
    def self.active_tavern_night(room)
      return nil unless room
      AresMUSH::TavernNight.find(room_id: room.id, status: "active").first
    end

    # Returns the active DungeonRun (pending OR active) for a given room, or nil.
    def self.active_dungeon_run(room)
      return nil unless room
      pending = AresMUSH::DungeonRun.find(room_id: room.id, status: "pending").first
      return pending if pending
      AresMUSH::DungeonRun.find(room_id: room.id, status: "active").first
    end

    # Returns or creates a TavernParticipant for a character in a night.
    def self.find_or_create_tavern_participant(night, char)
      existing = AresMUSH::TavernParticipant.find(
        tavern_night_id: night.id, character_id: char.id).first
      return existing if existing
      AresMUSH::TavernParticipant.create(tavern_night: night, character: char)
    end

    # Returns or creates a RunParticipant for a character in a run.
    def self.find_or_create_run_participant(run, char)
      existing = AresMUSH::RunParticipant.find(
        dungeon_run_id: run.id, character_id: char.id).first
      return existing if existing
      AresMUSH::RunParticipant.create(dungeon_run: run, character: char)
    end

    # ── Utility ──────────────────────────────────────────────────────────────

    # Returns a human-readable label for a doom level.
    def self.doom_label(doom_level)
      case doom_level
      when 10..Float::INFINITY then "Lethal"
      when 7..9                then "Hostile"
      when 4..6                then "Alert"
      else                          "Safe"
      end
    end

    # Returns the inebriation limit for a character (5 + Brawn).
    def self.ineb_limit(char)
      brawn = (char.pbta_stats["brawn"] || 0).to_i
      5 + brawn
    end

    # Returns the character's moves as an array of hashes for web display.
    def self.char_moves_for_web(char)
      role_moves = []
      if char.pbta_role
        role_config = Global.read_config("heroesguild", "roles")[char.pbta_role]
        role_moves = role_config ? (role_config["core_moves"] || []) : []
      end
      all_move_names = (role_moves + (char.pbta_moves || [])).uniq

      moves_config = Global.read_config("heroesguild", "moves")
      all_move_names.map do |name|
        move_def = moves_config["universal"][name] ||
                   moves_config["role_specific"][name] || {}
        { name: name, stat: move_def["stat"] || "", desc: move_def["desc"] || "" }
      end
    end

    # ── Web Data Builders ────────────────────────────────────────────────────

    # Full state hash for a DungeonRun — used by the Dungeon HUD web handler.
    def self.dungeon_run_web_data(run, viewer)
      contract    = run.contract
      stress_max  = Global.read_config("heroesguild", "stress_max").to_i

      participants = run.participants.map do |p|
        char = p.character
        stress_pips = (1..stress_max).map { |i| { filled: i <= char.pbta_stress.to_i } }
        {
          name: char.name,
          role: char.pbta_role || "Unknown",
          stress: char.pbta_stress.to_i,
          stress_max: stress_max,
          stress_pips: stress_pips
        }
      end

      posted_contracts = AresMUSH::DungeonContract.find(status: "posted").map do |c|
        { id: c.id, title: c.title, description: c.description, modifier: c.modifier }
      end

      doom_pips = (1..10).map do |i|
        label = case i
                when 4  then "A"
                when 7  then "H"
                when 10 then "L"
                else i.to_s
                end
        threshold = case i
                    when 4  then "alert"
                    when 7  then "hostile"
                    when 10 then "lethal"
                    end
        { filled: i <= run.doom_level.to_i, label: label, threshold: threshold }
      end

      progress_pips = (1..run.progress_max.to_i).map do |i|
        { filled: i <= run.progress_boxes.to_i }
      end

      {
        id: run.id,
        status: run.status,
        doom_level: run.doom_level.to_i,
        doom_label: HeroesGuild.doom_label(run.doom_level.to_i),
        doom_pips: doom_pips,
        progress: run.progress_boxes.to_i,
        progress_max: run.progress_max.to_i,
        progress_pips: progress_pips,
        contract: contract ? {
          id: contract.id,
          title: contract.title,
          description: contract.description,
          modifier: contract.modifier
        } : nil,
        participants: participants,
        posted_contracts: posted_contracts,
        is_admin: viewer.is_admin?,
        viewer_moves: HeroesGuild.char_moves_for_web(viewer)
      }
    end

    # Full state hash for a TavernNight — used by the Tavern HUD web handler.
    def self.tavern_night_web_data(night, viewer)
      stress_max  = Global.read_config("heroesguild", "stress_max").to_i
      participant = AresMUSH::TavernParticipant.find(
        tavern_night_id: night.id, character_id: viewer.id).first

      participants = night.participants.map do |p|
        char = p.character
        {
          name: char.name,
          inebriation: p.inebriation.to_i,
          ineb_limit: HeroesGuild.ineb_limit(char),
          vibe: p.vibe.to_i,
          stress: char.pbta_stress.to_i
        }
      end

      viewer_leads = AresMUSH::PbtaLead.find(
        character_id: viewer.id, status: "open").map do |l|
        { id: l.id, title: l.title,
          clues_gathered: l.clues_gathered.to_i, clues_needed: l.clues_needed.to_i }
      end

      viewer_ineb   = participant ? participant.inebriation.to_i : 0
      ineb_limit    = HeroesGuild.ineb_limit(viewer)

      stress_pips = (1..stress_max).map { |i| { filled: i <= viewer.pbta_stress.to_i } }
      ineb_pips   = (1..ineb_limit).map { |i| { filled: i <= viewer_ineb } }

      {
        id: night.id,
        status: night.status,
        vibe_pool: night.vibe_pool.to_i,
        participants: participants,
        viewer_inebriation: viewer_ineb,
        viewer_vibe: participant ? participant.vibe.to_i : 0,
        viewer_ineb_limit: ineb_limit,
        viewer_stress: viewer.pbta_stress.to_i,
        stress_max: stress_max,
        stress_pips: stress_pips,
        ineb_pips: ineb_pips,
        viewer_leads: viewer_leads,
        is_admin: viewer.is_admin?
      }
    end

  end
end
