module AresMUSH
  module HeroesGuild
    class MoveCmd
      include CommandHandler

      attr_accessor :move_name

      def parse_args
        self.move_name = cmd.args ? cmd.args.strip.titlecase : nil
      end

      def required_args
        [move_name]
      end

      def handle
        move_config = HeroesGuild.find_move(move_name)
        unless move_config
          client.emit_failure t('heroesguild.no_such_move', name: move_name)
          return
        end

        unless HeroesGuild.char_has_move?(enactor, move_name)
          client.emit_failure t('heroesguild.not_your_move', move: move_name)
          return
        end

        stat_name = move_config["stat"]
        room_name = enactor.room ? enactor.room.name : ""
        stat_val = HeroesGuild.stat_value(enactor, stat_name, 
                                           move_name: move_name, 
                                           room_name: room_name)

        result = Engine.roll(stat_val)
        output = Engine.format_roll(enactor.name, move_name, stat_name, result)
        enactor.room.emit output
        enactor.room.emit "%xc#{move_config['desc']}%xn"

        contract = DungeonContract.find(status: "active").first
        doom_level = contract ? contract.doom_level.to_i : 0
        consequences = Engine.apply_consequences(enactor, result, doom_level)
        consequences.each { |msg| enactor.room.emit msg }

        if result[:tier] == :miss && contract
          doom_msgs = Engine.advance_doom(contract, enactor.room.name)
          doom_msgs.each { |msg| enactor.room.emit "%xr#{msg}%xn" }
        end
      end
    end
  end
end
