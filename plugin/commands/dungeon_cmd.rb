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
        contract = AresMUSH::DungeonContract[id]
        unless contract && contract.status == "posted"
          client.emit_failure "Contract not found or not available to start."
          return
        end

        contract.update(status: "active")
        enactor.room.emit "%xcThe dungeon yawns open. What happens next is not going to be clean.%xn"
        enactor.room.emit "Current Doom level is: #{contract.doom_level}"
      end

      def do_doom
        contract = AresMUSH::DungeonContract.find(status: "active").first
        unless contract
          client.emit_failure "No active dungeon contract found."
          return
        end

        doom_data = Engine.advance_doom(contract)
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
        contract = AresMUSH::DungeonContract.find(status: "active").first
        unless contract
          client.emit_failure "No active dungeon contract found."
          return
        end

        boxes = cmd.args ? cmd.args.strip.to_i : 0
        new_prog = contract.progress_boxes.to_i + boxes
        contract.update(progress_boxes: new_prog)

        if new_prog >= contract.progress_max.to_i
          contract.update(status: "complete")
          enactor.room.emit "%xg[DUNGEON CLEARED] You survived. The contract is complete!%xn"
          if contract.job_id
            job = Job[contract.job_id]
            Jobs.add_comment(job, enactor, "Dungeon cleared successfully! Doom Reached: #{contract.doom_level}", true) if job
          end
        else
          enactor.room.emit "%xy[PROGRESS] Marked #{boxes} boxes. Total: #{new_prog}/#{contract.progress_max}%xn"
        end
      end

      def do_end
        contract = AresMUSH::DungeonContract.find(status: "active").first
        unless contract
          client.emit_failure "No active dungeon contract found."
          return
        end

        if contract.status != "complete"
          contract.update(status: "failed")
          enactor.room.emit "%xr[DUNGEON ABANDONED] The party retreated. Contract failed.%xn"
          if contract.job_id
            job = Job[contract.job_id]
            Jobs.add_comment(job, enactor, "Dungeon abandoned / failed. Doom Reached: #{contract.doom_level}", true) if job
          end
        end

        enactor.room.emit "%xhDungeon Summary:%xn Doom reached #{contract.doom_level}. " \
                          "Progress: #{contract.progress_boxes}/#{contract.progress_max}."
      end
    end
  end
end
