module AresMUSH
  class TavernParticipant < Ohm::Model
    include ObjectModel

    attribute :inebriation, :type => DataType::Integer, :default => 0
    attribute :vibe,        :type => DataType::Integer, :default => 0

    reference :tavern_night, "AresMUSH::TavernNight"
    reference :character,    "AresMUSH::Character"

    index :tavern_night_id
    index :character_id
  end
end
