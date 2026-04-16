module AresMUSH
  class PbtaLead < Ohm::Model
    include ObjectModel

    attribute :title
    attribute :description
    attribute :status, default: "open"
    attribute :clues_needed, Typecast::Integer, default: 3
    attribute :clues_gathered, Typecast::Integer, default: 0

    reference :character, "AresMUSH::Character"

    index :status
  end
end
