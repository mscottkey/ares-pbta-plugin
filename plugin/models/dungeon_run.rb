module AresMUSH
  class DungeonRun < Ohm::Model
    include ObjectModel

    attribute :status, :default => "pending"
    # pending  = started but no contract selected yet
    # active   = contract selected, crawl in progress
    # complete = successfully cleared
    # failed   = abandoned or TPK
    attribute :doom_level,     :type => DataType::Integer, :default => 0
    attribute :progress_boxes, :type => DataType::Integer, :default => 0
    attribute :progress_max,   :type => DataType::Integer, :default => 2
    attribute :started_at
    attribute :ended_at

    reference :room,       "AresMUSH::Room"
    reference :scene,      "AresMUSH::Scene"
    reference :started_by, "AresMUSH::Character"
    reference :contract,   "AresMUSH::DungeonContract"

    collection :participants, "AresMUSH::RunParticipant"

    index :status
    index :room_id
  end
end
