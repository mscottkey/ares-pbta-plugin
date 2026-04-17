module AresMUSH
  module PbtA

    # - Stat & Move Helpers -------------------------

    # Returns the character's effective stat value, applying Gimmick bonuses.
    def self.stat_value(char, stat_name, move_name: nil, room_name: nil)
      base = (char.pbta_stats[stat_name] || 0).to_i
      gimmick = char.pbta_gimmick
      return base unless gimmick

      gimmick_config = Global.read_config("pbta", "gimmicks")[gimmick]
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
      moves = Global.read_config("pbta", "moves")
      moves["universal"][move_name] ||
        moves["role_specific"][move_name]
    end

    # Returns true if the character has access to a given move.
    def self.char_has_move?(char, move_name)
      return true if char.pbta_moves.include?(move_name)
      role = char.pbta_role
      return false unless role
      role_config = Global.read_config("pbta", "roles")[role]
      return false unless role_config
      role_config["core_moves"].include?(move_name)
    end

    # Returns the role's base stat hash for a given role name.
    def self.role_stats(role_name)
      role_config = Global.read_config("pbta", "roles")[role_name]
      role_config ? role_config["stats"] : {}
    end

    # - Chargen Actions ---------------------------

    # Sets the character's playbook and initializes stats from the role config.
    # Called by both client commands and web handlers.
    # Returns { success: true } or { error: "message" }
    def self.set_playbook(char, role_name)
      return { error: "No role specified." } if role_name.nil? || role_name.empty?
      roles = Global.read_config("pbta", "roles")
      return { error: "Config error: pbta.yml missing or has no 'roles' key. Check game/config/pbta.yml is deployed." } if roles.nil?
      return { error: "Invalid playbook '#{role_name}'." } unless roles[role_name]
      stats = roles[role_name]["stats"].stringify_keys
      char.update(pbta_role: role_name, pbta_stats: stats)
      { success: true }
    end

    # Sets the character's gimmick.
    # Returns { success: true } or { error: "message" }
    def self.set_gimmick(char, gimmick_name)
      return { error: "No gimmick specified." } if gimmick_name.nil? || gimmick_name.empty?
      gimmicks = Global.read_config("pbta", "gimmicks")
      return { error: "Invalid gimmick '#{gimmick_name}'." } unless gimmicks[gimmick_name]
      char.update(pbta_gimmick: gimmick_name)
      { success: true }
    end

    # Lists all available playbooks for display.
    def self.playbook_list
      (Global.read_config("pbta", "roles") || {}).map do |name, cfg|
        stats = (cfg["stats"] || {}).map { |s, v| "#{s}: #{v.to_i >= 0 ? '+' : ''}#{v}" }.join(", ")
        { name: name, desc: cfg["desc"], stats: stats,
          core_moves: cfg["core_moves"] || [] }
      end
    end

    # Lists all available gimmicks for display.
    def self.gimmick_list
      (Global.read_config("pbta", "gimmicks") || {}).map do |name, cfg|
        { name: name, desc: cfg["desc"] }
      end
    end

    # Returns the character's moves as an array of hashes for web display.
    def self.char_moves_for_web(char)
      role_moves = []
      if char.pbta_role
        role_config = Global.read_config("pbta", "roles")[char.pbta_role]
        role_moves = role_config ? (role_config["core_moves"] || []) : []
      end
      all_move_names = (role_moves + (char.pbta_moves || [])).uniq

      moves_config = Global.read_config("pbta", "moves")
      all_move_names.map do |name|
        move_def = moves_config["universal"][name] ||
                   moves_config["role_specific"][name] || {}
        { name: name, stat: move_def["stat"] || "", desc: move_def["desc"] || "" }
      end
    end

  end
end
