module AresMUSH
  class DungeonContract < Ohm::Model
    include ObjectModel

    attribute :title
    attribute :description
    attribute :modifier
    attribute :status, default: "posted"
    attribute :doom_level, Typecast::Integer, default: 0
    attribute :progress_boxes, Typecast::Integer, default: 0
    attribute :progress_max, Typecast::Integer, default: 2
    attribute :job_id, Typecast::Integer

    reference :character, "AresMUSH::Character"

    index :status
  end
end
