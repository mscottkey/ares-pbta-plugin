module AresMUSH
  module Heroesguild
    class Dungeon
      include Mongoid::Document
      include Mongoid::Timestamps

      field :name, type: String
      field :doom_track, type: Integer, default: 0
      field :threat_level, type: Integer, default: 1
      field :status, type: String, default: "active" # active, completed, failed
    end
  end
end
