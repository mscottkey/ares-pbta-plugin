module AresMUSH
  class DungeonContract < Ohm::Model
    include ObjectModel

    attribute :title
    attribute :description
    attribute :modifier
    attribute :status,         :default => "posted"
    # valid statuses: posted, taken, complete, failed
    attribute :doom_level,     :type => DataType::Integer, :default => 0
    attribute :progress_boxes, :type => DataType::Integer, :default => 0
    attribute :progress_max,   :type => DataType::Integer, :default => 2
    attribute :job_id,         :type => DataType::Integer

    reference :character, "AresMUSH::Character"

    index :status
  end
end
