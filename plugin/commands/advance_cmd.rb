module AresMUSH
  module HeroesGuild
    class AdvanceCmd
      include CommandHandler

      attr_accessor :advance_type, :advance_target

      def parse_args
        self.advance_type = cmd.switch
        self.advance_target = cmd.args ? cmd.args.strip : nil
      end

      def handle
        xp_needed = Global.read_config("heroesguild", "xp_to_advance").to_i
        if enactor.pbta_xp.to_i < xp_needed
          client.emit_failure "You need #{xp_needed} XP to advance. You have #{enactor.pbta_xp.to_i}."
          return
        end

        case advance_type
        when "stat"
          stat = advance_target&.downcase
          valid_stats = %w[brawn cunning flow heart luck]
          unless valid_stats.include?(stat)
            client.emit_failure "Valid stats: #{valid_stats.join(', ')}"
            return
          end
          stats = enactor.pbta_stats || {}
          current = stats[stat].to_i
          if current >= 3
            client.emit_failure "#{stat.capitalize} is already at the max (+3)."
            return
          end
          stats[stat] = current + 1
          enactor.update(pbta_stats: stats, pbta_xp: 0)
          client.emit "%xg#{enactor.name} advances! #{stat.upcase} is now +#{stats[stat]}.%xn"

        when "move"
          move_name = advance_target&.strip&.titlecase
          unless HeroesGuild.find_move(move_name)
            client.emit_failure t('heroesguild.no_such_move', name: move_name)
            return
          end
          moves = enactor.pbta_moves || []
          if moves.include?(move_name)
            client.emit_failure "You already have the #{move_name} move."
            return
          end
          moves << move_name
          enactor.update(pbta_moves: moves, pbta_xp: 0)
          client.emit "%xg#{enactor.name} learns: #{move_name}!%xn"

        else
          client.emit_failure "Use +advance/stat <stat> or +advance/move <move_name>"
        end
      end
    end
  end
end
