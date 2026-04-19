module AresMUSH
  module PbtA
    class SheetTemplate < ErbTemplateRenderer

      attr_accessor :char, :client

      def initialize(char, client)
        @char = char
        @client = client
        super File.dirname(__FILE__) + "/sheet.erb"
      end

      def role
        char.pbta_role || "Unset"
      end

      def gimmick
        char.pbta_gimmick || "None"
      end

      def stat_line
        stats = char.pbta_stats || {}
        PbtA.stat_names.map do |s|
          val = stats[s].to_i
          sign = val >= 0 ? "+" : ""
          "%xh#{s.upcase}%xn #{sign}#{val}"
        end.join("  ")
      end

      def stress
        char.pbta_stress.to_i
      end

      def stress_max
        Global.read_config("pbta", "stress_max").to_i
      end

      def stress_bar
        ("#" * stress).ljust(stress_max, "-")
      end

      def xp
        char.pbta_xp.to_i
      end

      def xp_max
        Global.read_config("pbta", "xp_to_advance").to_i
      end

      def moves
        roles_config = Global.read_config("pbta", "roles") || {}
        role_config = char.pbta_role ? (roles_config[char.pbta_role] || {}) : {}
        role_moves = role_config["core_moves"] || []
        all_moves = (role_moves + (char.pbta_moves || [])).uniq
        all_moves.empty? ? ["None"] : all_moves
      end

      def section_line(title)
        @client.screen_reader ? title : line_with_text(title)
      end

    end
  end
end
