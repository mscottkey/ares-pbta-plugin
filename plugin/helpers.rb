module AresMUSH
  module HeroesGuild
    # Returns the character's effective stat value for a given stat name.
    # Applies Gimmick bonuses when applicable.
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
      if move_name && gimmick_config["move_bonus"] == move_name
        bonus = 1
      end
      base + bonus
    end

    # Returns the move config hash for a named move, or nil if not found.
    def self.find_move(move_name)
      moves = Global.read_config("heroesguild", "moves")
      moves["universal"][move_name] || 
        moves["role_specific"][move_name]
    end

    # Returns true if the character has access to a given move.
    def self.char_has_move?(char, move_name)
      return true if char.pbta_moves.include?(move_name)
      role = Groups.group_value(char, "Playbook")
      return false if role.nil? || role.empty?
      role_config = Global.read_config("heroesguild", "roles")[role]
      return false unless role_config
      role_config["core_moves"].include?(move_name)
    end

    # Returns the role's base stat hash for a given role name.
    def self.role_stats(role_name)
      role_config = Global.read_config("heroesguild", "roles")[role_name]
      role_config ? role_config["stats"] : {}
    end
  end
end
