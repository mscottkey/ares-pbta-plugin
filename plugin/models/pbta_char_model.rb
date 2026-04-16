module AresMUSH
  class Character
    attribute :pbta_role
    attribute :pbta_gimmick
    attribute :pbta_stats,        :type => DataType::Hash,    :default => {}
    attribute :pbta_moves,        :type => DataType::Array,   :default => []
    attribute :pbta_xp,           :type => DataType::Integer, :default => 0
    attribute :pbta_stress,       :type => DataType::Integer, :default => 0
    attribute :pbta_vibe,         :type => DataType::Integer, :default => 0
    attribute :pbta_inebriation,  :type => DataType::Integer, :default => 0

    collection :pbta_leads,        "AresMUSH::PbtaLead"
    collection :dungeon_contracts, "AresMUSH::DungeonContract"
  end
end
