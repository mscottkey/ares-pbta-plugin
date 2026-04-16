module AresMUSH
  class RunParticipant < Ohm::Model
    include ObjectModel

    reference :dungeon_run, "AresMUSH::DungeonRun"
    reference :character,   "AresMUSH::Character"

    index :dungeon_run_id
    index :character_id
  end
end
