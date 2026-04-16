module AresMUSH
  module Scenes
    module CustomSceneData
      def self.custom_scene_data(scene, enactor)
        room  = scene.room
        run   = room ? HeroesGuild.active_dungeon_run(room)  : nil
        night = room ? HeroesGuild.active_tavern_night(room) : nil

        {
          heroesguild: {
            dungeon_run_id:  run   ? run.id   : nil,
            tavern_night_id: night ? night.id : nil
          }
        }
      end
    end
  end
end
