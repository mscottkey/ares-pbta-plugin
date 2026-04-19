module AresMUSH
  module PbtA
    class CharProfileWeb
      def self.get_fields(char, viewer)
        role = char.pbta_role
        return {} if role.nil? || role.empty?

        raw_stats = char.pbta_stats || {}
        stress = char.pbta_stress.to_i
        xp = char.pbta_xp.to_i
        stress_max = Global.read_config("pbta", "stress_max").to_i
        xp_max = Global.read_config("pbta", "xp_to_advance").to_i

        stats = PbtA.stat_names.map do |key|
          val = (raw_stats[key] || 0).to_i
          {
            key: key,
            name: key.capitalize,
            value: val,
            display: val >= 0 ? "+#{val}" : val.to_s,
            positive: val > 0,
            negative: val < 0
          }
        end

        role_config = Global.read_config("pbta", "roles")[role] || {}
        role_moves = role_config["core_moves"] || []
        learned_moves = char.pbta_moves || []
        all_move_names = (role_moves + learned_moves).uniq

        moves_config = Global.read_config("pbta", "moves") || {}
        universal = moves_config["universal"] || {}
        role_specific = moves_config["role_specific"] || {}

        all_moves = all_move_names.map do |name|
          move_def = universal[name] || role_specific[name] || {}
          { name: name, stat: move_def["stat"] || "", desc: move_def["desc"] || "" }
        end

        stress_pips = (1..stress_max).map { |i| { filled: i <= stress } }
        xp_pips     = (1..xp_max).map    { |i| { filled: i <= xp } }

        {
          role: role,
          gimmick: char.pbta_gimmick,
          stats: stats,
          stress: stress,
          stress_max: stress_max,
          xp: xp,
          xp_max: xp_max,
          stress_pips: stress_pips,
          xp_pips: xp_pips,
          all_moves: all_moves
        }
      end
    end
  end
end
