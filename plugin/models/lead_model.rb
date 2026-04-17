module AresMUSH
  class PbtaLead < Ohm::Model
    include ObjectModel

    attribute :title
    attribute :description
    attribute :status,         :default => "open"
    attribute :clues_needed,   :type => DataType::Integer, :default => 3
    attribute :clues_gathered, :type => DataType::Integer, :default => 0
    attribute :job_id

    reference :character, "AresMUSH::Character"

    index :status
    index :character_id
  end
end
