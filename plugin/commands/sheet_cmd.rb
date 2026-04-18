module AresMUSH
  module PbtA
    class SheetCmd
      include CommandHandler

      attr_accessor :target_name

      def parse_args
        self.target_name = cmd.args ? titlecase_arg(cmd.args) : enactor_name
      end

      def handle
        ClassTargetFinder.with_a_character(target_name, client, enactor) do |target|
          roles_config = Global.read_config("pbta", "roles") || {}
          role = target.pbta_role
          role_config = role ? (roles_config[role] || {}) : {}
          role_moves = role_config["core_moves"] || []
          all_moves = (role_moves + (target.pbta_moves || [])).uniq

          stats = target.pbta_stats || {}
          stress = target.pbta_stress.to_i
          xp = target.pbta_xp.to_i
          stress_max = Global.read_config("pbta", "stress_max").to_i
          xp_max = Global.read_config("pbta", "xp_to_advance").to_i

          stat_line = %w[brawn cunning flow heart luck].map do |s|
            val = stats[s].to_i
            sign = val >= 0 ? "+" : ""
            "%xh#{s.upcase[0..2]}%xn #{sign}#{val}"
          end.join("  ")

          stress_bar = ("#" * stress).ljust(stress_max, "-")

          output = []
          output << "%xh%xb--- PbtA SHEET: #{target.name.upcase} ---%xn"
          output << "Role: %xc#{role || 'Unset'}%xn   Gimmick: %xy#{target.pbta_gimmick || 'None'}%xn"
          output << "Stats: #{stat_line}"
          output << "Stress: [#{stress_bar}] #{stress}/#{stress_max}   XP: #{xp}/#{xp_max}"
          output << "%xhMoves:%xn #{all_moves.empty? ? 'None' : all_moves.join(', ')}"
          output << "%xb#{'-' * 50}%xn"

          client.emit output.join("\n")
        end
      end
    end
  end
end
