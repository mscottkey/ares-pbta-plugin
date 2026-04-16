module AresMUSH
  class TavernNight < Ohm::Model
    include ObjectModel

    attribute :status,     :default => "active"   # active, closed
    attribute :vibe_pool,  :type => DataType::Integer, :default => 0
    attribute :opened_at
    attribute :closed_at

    reference :room,       "AresMUSH::Room"
    reference :scene,      "AresMUSH::Scene"
    reference :opened_by,  "AresMUSH::Character"

    collection :participants, "AresMUSH::TavernParticipant"

    index :status
    index :room_id
  end
end
