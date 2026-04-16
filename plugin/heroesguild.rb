require_relative 'helpers'
require_relative 'models/pbta_char_model'
require_relative 'models/lead_model'
require_relative 'models/dungeon_contract'
require_relative 'models/tavern_night'
require_relative 'models/tavern_participant'
require_relative 'models/dungeon_run'
require_relative 'models/run_participant'
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
require_relative 'web/container_web'

module AresMUSH
  module HeroesGuild
    def self.plugin_dir
      File.dirname(__FILE__)
    end

    def self.shortcuts
      Global.read_config("heroesguild", "shortcuts")
    end

    # Returns the handler CLASS for a given command root. Ares instantiates it.
    def self.get_cmd_handler(client, cmd, enactor)
      case cmd.root
      when "roll"       then return RollCmd
      when "move"       then return MoveCmd
      when "sheet"      then return SheetCmd
      when "advance"    then return AdvanceCmd
      when "carouse"    then return CarouseCmd
      when "imbibe"     then return ImbibeCmd
      when "sober"      then return SoberCmd
      when "dungeon"    then return DungeonCmd
      when "investigate", "lead" then return LeadCmd
      when "contract"   then return ContractCmd
      end
      nil
    end

    def self.get_web_request_handler(request)
      case request.cmd
      when "heroesguildJobBoard"     then return JobBoardRequestHandler
      when "initHeroesGuildStats"    then return InitStatsRequestHandler
      when "setHeroesGuildRole"      then return SetRoleRequestHandler
      when "setHeroesGuildGimmick"   then return SetGimmickRequestHandler
      when "heroesguildChargenData"  then return ChargenDataRequestHandler
      when "hgStartTavernNight"      then return StartTavernNightRequestHandler
      when "hgCloseTavernNight"      then return CloseTavernNightRequestHandler
      when "hgTavernNight"           then return TavernNightRequestHandler
      when "hgTavernAction"          then return TavernActionRequestHandler
      when "hgAddClue"               then return AddClueRequestHandler
      when "hgStartDungeonRun"       then return StartDungeonRunRequestHandler
      when "hgDungeonRun"            then return DungeonRunRequestHandler
      when "hgSelectContract"        then return SelectContractRequestHandler
      when "hgEndDungeonRun"         then return EndDungeonRunRequestHandler
      when "hgDungeonGmAction"       then return DungeonGmActionRequestHandler
      when "hgHudRollMove"           then return HudRollMoveRequestHandler
      end
      nil
    end
  end
end
