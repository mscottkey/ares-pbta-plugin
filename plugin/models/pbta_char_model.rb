module AresMUSH
  class Character < Ohm::Model
    attribute :pbta_gimmick
    attribute :pbta_stats, HashSerializer, default: {}
    attribute :pbta_moves, ArraySerializer, default: []
    attribute :pbta_xp, Typecast::Integer, default: 0
    attribute :pbta_stress, Typecast::Integer, default: 0
    attribute :pbta_vibe, Typecast::Integer, default: 0
    attribute :pbta_inebriation, Typecast::Integer, default: 0

    collection :pbta_leads, "AresMUSH::PbtaLead"
    collection :dungeon_contracts, "AresMUSH::DungeonContract"
  end
end
