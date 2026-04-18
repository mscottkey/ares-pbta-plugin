module AresMUSH
  module PbtA
    class RollStatFromSceneRequestHandler
      def handle(request)
        return { error: t('webportal.not_logged_in') } unless request.enactor

        char = request.enactor
        stat = request.args[:stat] || request.args["stat"]
        scene = AresMUSH::Scene[request.args[:scene_id] || request.args["scene_id"]]

        valid_stats = %w[brawn cunning flow heart luck]
        return { error: "Invalid stat." } unless valid_stats.include?(stat)
        return { error: "Scene not found." } unless scene

        stat_val = PbtA.stat_value(char, stat, room_name: scene.room&.name || "")
        result = Engine.roll(stat_val)
        output = Engine.format_roll(char.name, stat.capitalize, stat, result)

        scene.room.emit(output) if scene.room
        Scenes.add_to_scene(scene, output, char, false, false)

        {}
      end
    end

    class RollMoveFromSceneRequestHandler
      def handle(request)
        return { error: t('webportal.not_logged_in') } unless request.enactor

        char = request.enactor
        move_name = request.args[:move] || request.args["move"]
        scene = AresMUSH::Scene[request.args[:scene_id] || request.args["scene_id"]]

        move_config = PbtA.find_move(move_name)
        return { error: "Move not found." } unless move_config
        return { error: "You don't have that move." } unless PbtA.char_has_move?(char, move_name)
        return { error: "Scene not found." } unless scene

        stat_name = move_config["stat"]
        stat_val = PbtA.stat_value(char, stat_name,
                                   move_name: move_name,
                                   room_name: scene.room&.name || "")

        result = Engine.roll(stat_val)
        output = Engine.format_roll(char.name, move_name, stat_name, result)
        move_output = "%xc#{move_config['desc']}%xn"

        scene.room.emit(output) if scene.room
        scene.room.emit(move_output) if scene.room
        Scenes.add_to_scene(scene, "#{output}\n#{move_output}", char, false, false)

        doom_level = 0
        data = Engine.consequence_data(char, result, doom_level)
        if data[:xp_bump]
          xp_msg = "XP: #{data[:new_xp]}/#{Global.read_config('pbta', 'xp_to_advance')}"
          scene.room.emit("Miss! Mark XP. #{xp_msg}") if scene.room
        end

        {}
      end
    end
  end
end
