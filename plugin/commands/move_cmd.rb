module AresMUSH
  module PbtA
    class MoveCmd
      include CommandHandler

      attr_accessor :move_name

      def parse_args
        self.move_name = cmd.args ? cmd.args.strip.split.map(&:capitalize).join(' ') : nil
      end

      def required_args
        [move_name]
      end

      def handle
        move_config = PbtA.find_move(move_name)
        unless move_config
          client.emit_failure t('pbta.no_such_move', name: move_name)
          return
        end

        unless PbtA.char_has_move?(enactor, move_name)
          client.emit_failure t('pbta.not_your_move', move: move_name)
          return
        end

        stat_name = move_config["stat"]
        room_name = enactor.room ? enactor.room.name : ""
        stat_val = PbtA.stat_value(enactor, stat_name,
                                   move_name: move_name,
                                   room_name: room_name)

        result = Engine.roll(stat_val)
        enactor.room.emit Engine.format_roll(enactor.name, move_name, stat_name, result)
        enactor.room.emit "%xc#{move_config['desc']}%xn"

        run = defined?(HeroesGuild) && HeroesGuild.respond_to?(:active_dungeon_run) ?
              HeroesGuild.active_dungeon_run(enactor.room) : nil
        doom_level = run ? run.doom_level.to_i : 0
        data = Engine.consequence_data(enactor, result, doom_level)

        if data[:xp_bump]
          xp_msg = t('pbta.xp_gained', total: data[:new_xp])
          enactor.room.emit t('pbta.miss', xp_msg: xp_msg)
          client.emit t('pbta.advance_ready', name: enactor.name) if data[:advance_ready]
        elsif data[:xp_accumulating]
          xp_msg = t('pbta.xp_accumulating', remainder: data[:xp_remainder].round(2))
          enactor.room.emit t('pbta.miss', xp_msg: xp_msg)
        elsif data[:xp_rate_limited]
          enactor.room.emit t('pbta.miss', xp_msg: t('pbta.xp_rate_limited'))
        end
        if data[:stress_bump]
          enactor.room.emit t('pbta.stress_taken',
                               name: enactor.name, amount: 1,
                               total: data[:new_stress], max: data[:stress_max])
        end

        if result[:tier] == :miss && run && run.status == "active"
          doom_data = Engine.advance_doom(run)
          enactor.room.emit "%xr#{t('pbta.doom_increased', level: doom_data[:new_doom])}%xn"
          case doom_data[:threshold]
          when :alert   then enactor.room.emit "%xr#{t('pbta.doom_alert',   room: room_name)}%xn"
          when :hostile then enactor.room.emit "%xr#{t('pbta.doom_hostile', room: room_name)}%xn"
          when :lethal  then enactor.room.emit "%xr#{t('pbta.doom_lethal',  room: room_name)}%xn"
          end
        end
      end
    end
  end
end
