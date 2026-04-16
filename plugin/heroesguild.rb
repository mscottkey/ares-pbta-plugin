require_relative 'helpers'
require_relative 'models/pbta_char_model'
require_relative 'models/lead_model'
require_relative 'models/dungeon_contract'
require_relative 'engine'
require_relative 'commands/roll_cmd'
require_relative 'commands/move_cmd'  
require_relative 'commands/sheet_cmd'
require_relative 'commands/advance_cmd'
require_relative 'commands/tavern_cmd'
require_relative 'commands/dungeon_cmd'
require_relative 'commands/lead_cmd'
require_relative 'commands/contract_cmd'
require_relative 'web/char_profile_web'
require_relative 'web/jobboard_web'
require_relative 'web/chargen_web'

module AresMUSH
  module HeroesGuild
    def self.plugin_dir
      File.dirname(__FILE__)
    end

    def self.shortcuts
      Global.read_config("heroesguild", "shortcuts")
    end

    def self.dispatch(client, cmd, enactor)
      case cmd.root
      when "roll" then RollCmd.new(client, cmd, enactor).run
      when "move" then MoveCmd.new(client, cmd, enactor).run
      when "sheet" then SheetCmd.new(client, cmd, enactor).run
      when "advance" then AdvanceCmd.new(client, cmd, enactor).run
      when "carouse", "imbibe", "sober" then TavernCmd.new(client, cmd, enactor).run
      when "dungeon" then DungeonCmd.new(client, cmd, enactor).run
      when "investigate", "lead" then LeadCmd.new(client, cmd, enactor).run
      when "contract" then ContractCmd.new(client, cmd, enactor).run
      end
    end

    def self.get_web_request_handler(request)
      case request.cmd
      when "heroesguildJobBoard" then JobBoardRequestHandler.new
      when "initHeroesGuildStats" then InitStatsRequestHandler.new
      when "setHeroesGuildGimmick" then SetGimmickRequestHandler.new
      when "heroesguildChargenData" then ChargenDataRequestHandler.new
      end
    end
  end
end
