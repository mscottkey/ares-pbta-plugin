module AresMUSH
  module PbtA
    class SheetCmd
      include CommandHandler

      attr_accessor :target_name

      def parse_args
        self.target_name = cmd.args ? cmd.args.strip : nil
      end

      def handle
        target = target_name ?
          Character.find_one_by_name(target_name) : enactor

        unless target
          client.emit_failure "Character '#{target_name}' not found."
          return
        end

        stats = target.pbta_stats || {}
        role = target.pbta_role || "Unset"
        gimmick = target.pbta_gimmick || "None"
        xp = target.pbta_xp.to_i
        stress = target.pbta_stress.to_i
        stress_max = Global.read_config("pbta", "stress_max").to_i
        moves = target.pbta_moves || []

        role_moves = []
        if target.pbta_role
          role_config = Global.read_config("pbta", "roles")[target.pbta_role]
          role_moves = role_config ? (role_config["core_moves"] || []) : []
        end
        all_moves = (role_moves + moves).uniq

        stat_line = %w[brawn cunning flow heart luck].map do |s|
          val = stats[s].to_i
          sign = val >= 0 ? "+" : ""
          "%xh#{s.upcase[0..2]}%xn #{sign}#{val}"
        end.join("  ")

        stress_bar = ("#" * stress).ljust(stress_max, "-")

        output = []
        output << "%xh%xb--- PbtA SHEET: #{target.name.upcase} ---%xn"
        output << "Role: %xc#{role}%xn   Gimmick: %xy#{gimmick}%xn"
        output << "Stats: #{stat_line}"
        output << "Stress: [#{stress_bar}] #{stress}/#{stress_max}   " \
                  "XP: #{xp}/#{Global.read_config('pbta', 'xp_to_advance')}"
        output << "%xhMoves:%xn #{all_moves.empty? ? 'None' : all_moves.join(', ')}"
        output << "%xb#{'-'*50}%xn"

        client.emit output.join("\n")
      end
    end
  end
end
