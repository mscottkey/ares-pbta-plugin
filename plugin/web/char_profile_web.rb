module AresMUSH
  module PbtA
    class CharProfileWeb
      def self.get_fields(char, viewer)
        role = char.pbta_role
        return {} if role.nil? || role.empty?

        stats = char.pbta_stats || {}
        gimmick = char.pbta_gimmick
        xp = char.pbta_xp.to_i
        stress = char.pbta_stress.to_i
        xp_max = Global.read_config("pbta_misc", "xp_to_advance").to_i
        stress_max = Global.read_config("pbta_misc", "stress_max").to_i

        role_config = Global.read_config("pbta_stats", "roles")[role] || {}
        role_moves = role_config["core_moves"] || []
        learned_moves = char.pbta_moves || []
        all_move_names = (role_moves + learned_moves).uniq

        moves_config = Global.read_config("pbta_stats", "moves")
        all_moves_data = all_move_names.map do |name|
          move_def = moves_config["universal"][name] ||
                     moves_config["role_specific"][name] || {}
          { name: name, desc: move_def["desc"] || "", stat: move_def["stat"] || "" }
        end

        stress_pips = (1..stress_max).map { |i| { filled: i <= stress } }
        xp_pips = (1..xp_max).map { |i| { filled: i <= xp } }

        {
          role: role,
          gimmick: gimmick,
          stats: stats,
          xp: xp,
          stress: stress,
          stress_pips: stress_pips,
          xp_pips: xp_pips,
          all_moves: all_moves_data
        }
      end
    end
  end
end
