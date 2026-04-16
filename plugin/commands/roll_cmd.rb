module AresMUSH
  module HeroesGuild
    class RollCmd
      include CommandHandler

      attr_accessor :stat_name, :modifier

      def parse_args
        # Accept: +roll brawn  OR  +roll flow+1  OR  +roll heart-2
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

        stat_val = HeroesGuild.stat_value(enactor, stat_name)
        result = Engine.roll(stat_val, modifier)

        room = enactor.room
        output = Engine.format_roll(enactor.name, stat_name.capitalize, stat_name, result)
        room.emit output

        # Find active contract for doom tracking
        contract = DungeonContract.find(status: "active").first
        doom_level = contract ? contract.doom_level.to_i : 0

        consequences = Engine.apply_consequences(enactor, result, doom_level)
        consequences.each { |msg| room.emit msg }

        if result[:tier] == :miss && contract
          doom_msgs = Engine.advance_doom(contract, room.name)
          doom_msgs.each { |msg| room.emit "%xr#{msg}%xn" }
        end
      end
    end
  end
end
