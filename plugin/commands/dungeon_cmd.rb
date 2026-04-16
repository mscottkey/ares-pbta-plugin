module AresMUSH
  module HeroesGuild
    class DungeonCmd
      include CommandHandler

      def handle
        case cmd.switch
        when "start"    then do_start
        when "doom"     then do_doom
        when "threat"   then do_threat
        when "progress" then do_progress
        when "end"      then do_end
        else
          client.emit_failure "Use +dungeon/start <id>, +dungeon/doom, +dungeon/threat, " \
                              "+dungeon/progress <boxes>, or +dungeon/end"
        end
      end

      private

      def do_start
        id = cmd.args ? cmd.args.strip : nil
        run = AresMUSH::DungeonRun[id]
        unless run && run.status == "pending"
          client.emit_failure "No pending dungeon run found with that id."
          return
        end

        run.update(status: "active")
        enactor.room.emit "%xcThe dungeon run begins. Doom: #{run.doom_level}%xn"
      end

      def do_doom
        run = HeroesGuild.active_dungeon_run(enactor.room)
        unless run && run.status == "active"
          client.emit_failure "No active dungeon run in this room."
          return
        end

        doom_data = Engine.advance_doom(run)
        room_name = enactor.room.name
        enactor.room.emit "%xr#{t('heroesguild.doom_increased', level: doom_data[:new_doom])}%xn"
        case doom_data[:threshold]
        when :alert   then enactor.room.emit "%xr#{t('heroesguild.doom_alert',   room: room_name)}%xn"
        when :hostile then enactor.room.emit "%xr#{t('heroesguild.doom_hostile', room: room_name)}%xn"
        when :lethal  then enactor.room.emit "%xr#{t('heroesguild.doom_lethal',  room: room_name)}%xn"
        end
      end

      def do_threat
        threats = [
          "A section of floor gives way.",
          "The torches go out.",
          "Something starts growling nearby.",
          "A tripwire — discovered too late.",
          "The corridor behind you shifts.",
          "Water starts pouring in from the walls.",
          "An alarm — magical, shrill, definitely heard.",
          "The smell of smoke."
        ]
        enactor.room.emit "%xr[ENVIRONMENTAL THREAT] #{threats.sample}%xn"
      end

      def do_progress
        run = HeroesGuild.active_dungeon_run(enactor.room)
        unless run && run.status == "active"
          client.emit_failure "No active dungeon run in this room."
          return
        end

        boxes = cmd.args ? cmd.args.strip.to_i : 0
        new_prog = run.progress_boxes.to_i + boxes
        run.update(progress_boxes: new_prog)

        if new_prog >= run.progress_max.to_i
          run.update(status: "complete")
          enactor.room.emit "%xg[DUNGEON CLEARED] You survived. The run is complete!%xn"
        else
          enactor.room.emit "%xy[PROGRESS] Marked #{boxes} boxes. Total: #{new_prog}/#{run.progress_max}%xn"
        end
      end

      def do_end
        run = HeroesGuild.active_dungeon_run(enactor.room)
        unless run
          client.emit_failure "No active dungeon run in this room."
          return
        end

        if run.status != "complete"
          run.update(status: "failed", ended_at: Time.now.to_s)
          enactor.room.emit "%xr[DUNGEON ABANDONED] The party retreated. Run failed.%xn"
          run.contract.update(status: "posted") if run.contract
        end

        enactor.room.emit "%xhDungeon Summary:%xn Doom reached #{run.doom_level}. " \
                          "Progress: #{run.progress_boxes}/#{run.progress_max}."
      end
    end
  end
end
