module AresMUSH
  module Scenes
    def self.custom_scene_data(viewer)
      stats = viewer.pbta_stats || {}
      stat_list = PbtA.stat_names.map do |s|
        val = (stats[s] || 0).to_i
        { key: s, name: s.capitalize,
          display: val >= 0 ? "+#{val}" : val.to_s }
      end

      {
        pbta: {
          stats: stat_list,
          all_moves: PbtA.char_moves_for_web(viewer)
        }
      }
    end
  end
end
