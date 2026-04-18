module AresMUSH
  module Scenes
    class CustomSceneData
      def self.custom_scene_data(scene, enactor)
        room = scene.room
        run   = room ? HeroesGuild.active_dungeon_run(room)  : nil
        night = room ? HeroesGuild.active_tavern_night(room) : nil

        stats = enactor.pbta_stats || {}
        stat_list = %w[brawn cunning flow heart luck].map do |s|
          val = (stats[s] || 0).to_i
          { key: s, name: s.capitalize,
            display: val >= 0 ? "+#{val}" : val.to_s }
        end

        moves = PbtA.char_moves_for_web(enactor)

        {
          heroesguild: {
            dungeon_run_id:  run   ? run.id   : nil,
            tavern_night_id: night ? night.id : nil
          },
          pbta: {
            stats: stat_list,
            all_moves: moves
          }
        }
      end
    end
  end
end
