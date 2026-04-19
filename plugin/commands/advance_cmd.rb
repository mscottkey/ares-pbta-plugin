module AresMUSH
  module PbtA
    class AdvanceCmd
      include CommandHandler

      attr_accessor :advance_target

      def parse_args
        self.advance_target = cmd.args ? cmd.args.strip : nil
      end

      def handle
        unless ["stat", "move"].include?(cmd.switch)
          client.emit_failure "Use advance/stat <stat> or advance/move <move_name>"
          return
        end

        xp_needed = Global.read_config("pbta", "xp_to_advance").to_i
        if enactor.pbta_xp.to_i < xp_needed
          client.emit_failure "You need #{xp_needed} XP to advance. You have #{enactor.pbta_xp.to_i}."
          return
        end

        case cmd.switch
        when "stat" then handle_stat_advance
        when "move" then handle_move_advance
        end
      end

      private

      def handle_stat_advance
        stat = advance_target&.downcase
        valid_stats = PbtA.stat_names
        unless valid_stats.include?(stat)
          client.emit_failure "Valid stats: #{valid_stats.join(', ')}"
          return
        end
        stats = enactor.pbta_stats || {}
        current = (stats[stat] || 0).to_i
        if current >= 3
          client.emit_failure "#{stat.capitalize} is already at the max (+3)."
          return
        end
        stats[stat] = current + 1
        enactor.update(pbta_stats: stats, pbta_xp: 0)
        client.emit_success "%xg#{enactor.name} advances! #{stat.upcase} is now +#{stats[stat]}.%xn"
      end

      def handle_move_advance
        move_name = advance_target&.strip&.split&.map(&:capitalize)&.join(' ')
        unless PbtA.find_move(move_name)
          client.emit_failure t('pbta.no_such_move', name: move_name)
          return
        end
        moves = enactor.pbta_moves || []
        if moves.include?(move_name)
          client.emit_failure "You already have the #{move_name} move."
          return
        end
        moves << move_name
        enactor.update(pbta_moves: moves, pbta_xp: 0)
        client.emit_success "%xg#{enactor.name} learns: #{move_name}!%xn"
      end
    end
  end
end
