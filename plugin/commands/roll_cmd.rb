module AresMUSH
  module PbtA
    class RollCmd
      include CommandHandler

      attr_accessor :stat_name, :modifier

      def parse_args
        args = cmd.args ? cmd.args.strip : ""
        if args =~ /^(\w+)\s*([+-]\d+)?$/
          self.stat_name = $1.downcase
          self.modifier = ($2 ? $2.to_i : 0)
        end
      end

      def required_args
        [stat_name]
      end

      def handle
        valid_stats = %w[brawn cunning flow heart luck]
        unless valid_stats.include?(stat_name)
          client.emit_failure "Unknown stat '#{stat_name}'. Valid stats: #{valid_stats.join(', ')}"
          return
        end

        stat_val = PbtA.stat_value(enactor, stat_name)
        result = Engine.roll(stat_val, modifier)

        enactor.room.emit Engine.format_roll(enactor.name, stat_name.capitalize,
                                              stat_name, result)

        run = defined?(HeroesGuild) && HeroesGuild.respond_to?(:active_dungeon_run) ?
              HeroesGuild.active_dungeon_run(enactor.room) : nil
        doom_level = run ? run.doom_level.to_i : 0

        emit_consequences(Engine.consequence_data(enactor, result, doom_level))

        if result[:tier] == :miss && run && run.status == "active"
          emit_doom(Engine.advance_doom(run), enactor.room.name)
        end
      end

      private

      def emit_consequences(data)
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
      end

      def emit_doom(doom_data, room_name)
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
