require_relative 'helpers'
require_relative 'models/pbta_char_model'
require_relative 'engine'
require_relative 'commands/roll_cmd'
require_relative 'commands/move_cmd'
require_relative 'commands/sheet_cmd'
require_relative 'commands/advance_cmd'
require_relative 'commands/chargen_cmd'
require_relative 'web/char_profile_web'
require_relative 'web/chargen_web'

module AresMUSH
  module PbtA
    def self.plugin_dir
      File.dirname(__FILE__)
    end

    def self.shortcuts
      Global.read_config("pbta_misc", "shortcuts")
    end

    def self.get_cmd_handler(client, cmd, enactor)
      case cmd.root
      when "roll"    then return RollCmd
      when "move"    then return MoveCmd
      when "sheet"   then return SheetCmd
      when "advance"  then return AdvanceCmd
      when "playbook" then return PlaybookCmd
      when "gimmick"  then return GimmickCmd
      end
      nil
    end

    def self.get_web_request_handler(request)
      case request.cmd
      when "initHeroesGuildStats"   then return InitStatsRequestHandler
      when "setHeroesGuildRole"     then return SetRoleRequestHandler
      when "setHeroesGuildGimmick"  then return SetGimmickRequestHandler
      when "heroesguildChargenData" then return ChargenDataRequestHandler
      end
      nil
    end
  end
end
