module AresMUSH
  module PbtA
    class PbtaRollStatRequestHandler
      def handle(request)
        return { error: t('webportal.not_logged_in') } unless request.enactor

        char = request.enactor
        scene_id = request.args["scene_id"]
        stat_name = request.args["stat"]

        return { error: "No stat specified." } if stat_name.nil? || stat_name.empty?

        valid_stats = %w[brawn cunning flow heart luck]
        return { error: "Invalid stat '#{stat_name}'." } unless valid_stats.include?(stat_name)

        scene = AresMUSH::Scene[scene_id]
        return { error: "Scene not found." } unless scene

        room = scene.room
        stat_val = PbtA.stat_value(char, stat_name, room_name: room&.name)
        result = Engine.roll(stat_val, 0)

        room.emit Engine.format_roll(char.name, stat_name.capitalize, stat_name, result) if room

        run = (defined?(HeroesGuild) && room) ? HeroesGuild.active_dungeon_run(room) : nil
        doom_level = run ? run.doom_level.to_i : 0
        data = Engine.consequence_data(char, result, doom_level)

        if data[:xp_bump]
          room.emit "#{char.name} gains XP on a miss. (#{data[:new_xp]} total)" if room
          room.emit "#{char.name} can now advance!" if data[:advance_ready] && room
        end
        if data[:stress_bump]
          room.emit "#{char.name} takes 1 stress. (#{data[:new_stress]}/#{data[:stress_max]})" if room
        end

        if result[:tier] == :miss && run&.status == "active"
          doom_data = Engine.advance_doom(run)
          room.emit "%xrDoom increases to #{doom_data[:new_doom]}.%xn" if room
        end

        {}
      end
    end

    class PbtaRollMoveRequestHandler
      def handle(request)
        return { error: t('webportal.not_logged_in') } unless request.enactor

        char = request.enactor
        scene_id = request.args["scene_id"]
        move_name = request.args["move"]

        return { error: "No move specified." } if move_name.nil? || move_name.empty?

        move_config = PbtA.find_move(move_name)
        return { error: "Move '#{move_name}' not found." } unless move_config
        return { error: "You don't have that move." } unless PbtA.char_has_move?(char, move_name)

        scene = AresMUSH::Scene[scene_id]
        return { error: "Scene not found." } unless scene

        room = scene.room
        stat_name = move_config["stat"]
        stat_val = PbtA.stat_value(char, stat_name, move_name: move_name, room_name: room&.name)
        result = Engine.roll(stat_val, 0)

        room.emit Engine.format_roll(char.name, move_name, stat_name, result) if room
        room.emit "%xc#{move_config['desc']}%xn" if room

        run = (defined?(HeroesGuild) && room) ? HeroesGuild.active_dungeon_run(room) : nil
        doom_level = run ? run.doom_level.to_i : 0
        data = Engine.consequence_data(char, result, doom_level)

        if data[:xp_bump]
          room.emit "#{char.name} gains XP on a miss. (#{data[:new_xp]} total)" if room
          room.emit "#{char.name} can now advance!" if data[:advance_ready] && room
        end
        if data[:stress_bump]
          room.emit "#{char.name} takes 1 stress. (#{data[:new_stress]}/#{data[:stress_max]})" if room
        end

        if result[:tier] == :miss && run&.status == "active"
          doom_data = Engine.advance_doom(run)
          room.emit "%xrDoom increases to #{doom_data[:new_doom]}.%xn" if room
        end

        {}
      end
    end
  end
end
