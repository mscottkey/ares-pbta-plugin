require_relative 'helpers'
require_relative 'templates/sheet_template'
require_relative 'models/pbta_char_model'
require_relative 'engine'
require_relative 'commands/roll_cmd'
require_relative 'commands/move_cmd'
require_relative 'commands/sheet_cmd'
require_relative 'commands/advance_cmd'
require_relative 'commands/chargen_cmd'
require_relative 'commands/heal_cmd'
require_relative 'events/stress_recovery_event'
require_relative 'web/char_profile_web'
require_relative 'web/chargen_web'
require_relative 'web/pbta_roll_web'

module AresMUSH
  module PbtA
    def self.plugin_dir
      File.dirname(__FILE__)
    end

    def self.shortcuts
      Global.read_config("pbta", "shortcuts")
    end

    def self.get_cmd_handler(client, cmd, enactor)
      case cmd.root
      when "roll"    then return RollCmd
      when "move"    then return MoveCmd
      when "sheet"   then return SheetCmd
      when "advance"  then return AdvanceCmd
      when "playbook" then return PlaybookCmd
      when "gimmick"  then return GimmickCmd
      when "heal"    then return HealCmd
      when "stress"  then return StressCmd
      end
      nil
    end

    def self.install_setup
      Character.all.each do |c|
        c.update(pbta_stats: {})          if c.pbta_stats.nil?
        c.update(pbta_moves: [])          if c.pbta_moves.nil?
        c.update(pbta_xp: 0)             if c.pbta_xp.nil?
        c.update(pbta_xp_remainder: 0.0)   if c.pbta_xp_remainder.nil?
        c.update(pbta_xp_rate_earned: 0)   if c.pbta_xp_rate_earned.nil?
        c.update(pbta_stress: 0)           if c.pbta_stress.nil?
        # pbta_last_stress_tick, pbta_stress_frozen_until, pbta_heal_cooldown,
        # pbta_xp_rate_window_start left nil intentionally — set on first use
      end
      Global.logger.info "PbtA install_setup complete."
    end

    def self.get_event_handler(event_name)
      case event_name
      when "CronEvent"
        return StressRecoveryEventHandler
      end
      nil
    end

    def self.get_web_request_handler(request)
      case request.cmd
      when "initHeroesGuildStats"   then return InitStatsRequestHandler
      when "setHeroesGuildRole"     then return SetRoleRequestHandler
      when "setHeroesGuildGimmick"  then return SetGimmickRequestHandler
      when "heroesguildChargenData" then return ChargenDataRequestHandler
      when "pbtaRollStat"           then return RollStatFromSceneRequestHandler
      when "pbtaRollMove"           then return RollMoveFromSceneRequestHandler
      end
      nil
    end
  end
end
