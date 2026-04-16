module AresMUSH
  module HeroesGuild

    # POST: Start a TavernNight in the scene's room.
    class StartTavernNightRequestHandler
      def handle(request)
        error = WebHelpers.check_login(request)
        return error if error

        char  = request.enactor
        scene = AresMUSH::Scene[request.args[:scene_id]]
        return { error: "Scene not found." } unless scene

        room = scene.room
        return { error: "No room associated with this scene." } unless room

        return { error: "A tavern night is already active here." } if HeroesGuild.active_tavern_night(room)

        night = AresMUSH::TavernNight.create(
          status: "active", room: room, scene: scene,
          opened_by: char, opened_at: Time.now.to_s
        )
        room.emit "%xc[TAVERN NIGHT] #{char.name} opens the night. " \
                  "Use the Tavern HUD to carouse, imbibe, and investigate.%xn"
        { night_id: night.id }
      end
    end

    # POST: Close an active TavernNight.
    class CloseTavernNightRequestHandler
      def handle(request)
        error = WebHelpers.check_login(request)
        return error if error

        char  = request.enactor
        night = AresMUSH::TavernNight[request.args[:night_id]]
        return { error: "Tavern night not found." }  unless night
        return { error: "Already closed." }          if night.status == "closed"

        night.update(status: "closed", closed_at: Time.now.to_s)
        night.room.emit "%xc[TAVERN NIGHT] #{char.name} calls last round. The night is over.%xn" if night.room
        { success: true }
      end
    end

    # GET: Full TavernNight data for the HUD page.
    class TavernNightRequestHandler
      def handle(request)
        error = WebHelpers.check_login(request)
        return error if error

        night = AresMUSH::TavernNight[request.args[:id]]
        return { error: "Tavern night not found." } unless night

        HeroesGuild.tavern_night_web_data(night, request.enactor)
      end
    end

    # POST: Tavern actions from the HUD — carouse, imbibe, sober, investigate.
    class TavernActionRequestHandler
      def handle(request)
        error = WebHelpers.check_login(request)
        return error if error

        char  = request.enactor
        night = AresMUSH::TavernNight[request.args[:night_id]]
        return { error: "Tavern night not found." } unless night
        return { error: "Tavern night is closed." } unless night.status == "active"

        participant = HeroesGuild.find_or_create_tavern_participant(night, char)
        room        = night.room

        case request.args[:action]

        when "carouse"
          room_name = room ? room.name : ""
          stat_val  = HeroesGuild.stat_value(char, "heart",
                                             move_name: "Carouse", room_name: room_name)
          result = Engine.roll(stat_val)
          room.emit Engine.format_roll(char.name, "Carouse", "heart", result) if room

          case result[:tier]
          when :strong
            participant.update(vibe: participant.vibe.to_i + 2)
            char.update(pbta_stress: [char.pbta_stress.to_i - 2, 0].max)
            room.emit "#{char.name} has a great night. Clear 2 Stress and gain 2 Vibe." if room
          when :weak
            participant.update(vibe: participant.vibe.to_i + 1)
            char.update(pbta_stress: [char.pbta_stress.to_i - 1, 0].max)
            room.emit "#{char.name} has a decent night. Clear 1 Stress, but make a choice." if room
          when :miss
            room.emit "#{char.name} had TOO good a night. Tavern Fallout incoming." if room
            fallout_msg = [
              "#{char.name} wakes up to find something valuable... gone.",
              "Someone now has strong feelings about #{char.name}. The negative kind.",
              "#{char.name} apparently made some promises last night. The kind with interest."
            ].sample
            room.emit "%xr[TAVERN FALLOUT] #{fallout_msg}%xn" if room
            data = Engine.consequence_data(char, result, 0)
            if data[:xp_bump]
              room.emit "You tried your best. Mark XP. (#{data[:new_xp]} total)" if room
            end
          end

        when "imbibe"
          limit     = HeroesGuild.ineb_limit(char)
          new_ineb  = participant.inebriation.to_i + 1
          new_vibe  = participant.vibe.to_i + 1
          participant.update(inebriation: new_ineb, vibe: new_vibe)

          if new_ineb >= limit
            room.emit "#{char.name} has hit their limit. The night ends badly." if room
            participant.update(inebriation: 0)
            fallout_msg = [
              "#{char.name} wakes up to find something valuable... gone.",
              "Someone now has strong feelings about #{char.name}. The negative kind.",
              "#{char.name} apparently made some promises last night. The kind with interest."
            ].sample
            room.emit "%xr[TAVERN FALLOUT] #{fallout_msg}%xn" if room
          else
            bar = ("#" * new_ineb).ljust(limit, "-")
            room.emit "#{char.name} drinks. [#{bar}] #{new_ineb}/#{limit}  Vibe: #{new_vibe}" if room
          end

        when "sober"
          new_ineb = [participant.inebriation.to_i - 2, 0].max
          participant.update(inebriation: new_ineb)
          limit = HeroesGuild.ineb_limit(char)
          bar   = ("#" * new_ineb).ljust(limit, "-")
          room.emit "#{char.name} sobers up. [#{bar}] #{new_ineb}/#{limit}" if room

        when "investigate"
          room_name = room ? room.name : ""
          stat_val  = HeroesGuild.stat_value(char, "cunning",
                                             move_name: "Investigate", room_name: room_name)
          result = Engine.roll(stat_val)
          room.emit Engine.format_roll(char.name, "Investigate", "cunning", result) if room

          if result[:tier] == :miss
            data = Engine.consequence_data(char, result, 0)
            room.emit "You tried your best. Mark XP. (#{data[:new_xp]} total)" if room && data[:xp_bump]
          else
            seeds = [
              ["Rumors of a sealed vault east of the Ashwood", "Someone paid a lot to keep this quiet."],
              ["A merchant paid triple for an escort that never arrived", "Three guards. No bodies found."],
              ["Old guild records mention a dungeon with no exit", "...and one survivor who won't talk about it."],
              ["A map fragment found in a dead man's boot", "The symbols don't match any known dungeon."],
              ["The night watch has been avoiding the old mill", "Won't say why. Eyes say plenty."]
            ]
            seed  = seeds.sample
            clues = result[:tier] == :strong ? 2 : 4
            lead  = AresMUSH::PbtaLead.create(title: seed[0], description: seed[1],
                                               status: "open", clues_needed: clues, character: char)
            room.emit "#{char.name} picks up a lead: #{lead.title}" if room
            room.emit "%xy(Lead requires #{clues} clue(s))%xn" if room
            room.emit "%xr[COMPLICATION] You drew unwanted attention.%xn" if room && result[:tier] == :weak
          end
        end

        HeroesGuild.tavern_night_web_data(night, char)
      end
    end

    # POST: Add a clue to a lead; auto-converts when threshold reached.
    class AddClueRequestHandler
      def handle(request)
        error = WebHelpers.check_login(request)
        return error if error

        char = request.enactor
        lead = AresMUSH::PbtaLead[request.args[:lead_id]]
        return { error: "Lead not found." }    unless lead
        return { error: "Not your lead." }     unless lead.character_id == char.id
        return { error: "Lead already converted." } unless lead.status == "open"

        lead.update(clues_gathered: lead.clues_gathered.to_i + 1)
        converted = false

        if lead.clues_gathered.to_i >= lead.clues_needed.to_i
          lead.update(status: "converted")
          modifiers = ["Cursed Gold", "Anti-Magic Field", "Haunted",
                       "Flooded Lower Levels", "Boss Guarded", "Trapped Entrance"]
          AresMUSH::DungeonContract.create(
            title: lead.title, description: lead.description,
            modifier: modifiers.sample, character: char, status: "posted"
          )
          converted = true
        end

        night = char.tavern_participants.map(&:tavern_night).compact
                    .find { |n| n.status == "active" }

        if night
          data = HeroesGuild.tavern_night_web_data(night, char)
          data[:converted] = converted
          data
        else
          { success: true, converted: converted }
        end
      end
    end

    # POST: Start a DungeonRun in the scene's room (status: pending).
    class StartDungeonRunRequestHandler
      def handle(request)
        error = WebHelpers.check_login(request)
        return error if error

        char  = request.enactor
        scene = AresMUSH::Scene[request.args[:scene_id]]
        return { error: "Scene not found." } unless scene

        room = scene.room
        return { error: "No room associated with this scene." } unless room

        return { error: "A dungeon run is already active here." } if HeroesGuild.active_dungeon_run(room)

        run = AresMUSH::DungeonRun.create(
          status: "pending", room: room, scene: scene,
          started_by: char, started_at: Time.now.to_s
        )
        room.emit "%xr[DUNGEON RUN] #{char.name} opens a dungeon run. " \
                  "Select a contract in the Dungeon HUD to begin.%xn"
        { run_id: run.id }
      end
    end

    # GET: Full DungeonRun data for the HUD page.
    class DungeonRunRequestHandler
      def handle(request)
        error = WebHelpers.check_login(request)
        return error if error

        run = AresMUSH::DungeonRun[request.args[:id]]
        return { error: "Dungeon run not found." } unless run

        HeroesGuild.dungeon_run_web_data(run, request.enactor)
      end
    end

    # POST: Select a contract for a pending DungeonRun; activates the run.
    class SelectContractRequestHandler
      def handle(request)
        error = WebHelpers.check_login(request)
        return error if error

        run = AresMUSH::DungeonRun[request.args[:run_id]]
        return { error: "Dungeon run not found." }   unless run
        return { error: "Run is not pending." }       unless run.status == "pending"

        contract = AresMUSH::DungeonContract[request.args[:contract_id]]
        return { error: "Contract not found." }       unless contract
        return { error: "Contract is not available." } unless contract.status == "posted"

        contract.update(status: "taken")
        run.update(contract: contract, status: "active",
                   progress_max: contract.progress_max || 2)

        run.room.emit "%xr[DUNGEON RUN] Contract accepted: #{contract.title}. " \
                      "Modifier: #{contract.modifier}. The dungeon is waiting.%xn" if run.room

        HeroesGuild.dungeon_run_web_data(run, request.enactor)
      end
    end

    # POST: End a DungeonRun (any non-admin player can end).
    class EndDungeonRunRequestHandler
      def handle(request)
        error = WebHelpers.check_login(request)
        return error if error

        char = request.enactor
        run  = AresMUSH::DungeonRun[request.args[:run_id]]
        return { error: "Dungeon run not found." } unless run

        final_status = run.status == "complete" ? "complete" : "failed"
        run.update(status: final_status, ended_at: Time.now.to_s)
        if run.contract
          new_contract_status = final_status == "complete" ? "complete" : "posted"
          run.contract.update(status: new_contract_status)
        end

        run.room.emit "%xr[DUNGEON RUN] #{char.name} ends the run. " \
                      "Status: #{final_status.upcase}. " \
                      "Doom reached: #{run.doom_level}/10.%xn" if run.room

        { success: true, status: final_status }
      end
    end

    # POST: GM actions on a DungeonRun — doom, threat, progress. Requires admin.
    class DungeonGmActionRequestHandler
      def handle(request)
        error = WebHelpers.check_login(request)
        return error if error

        return { error: "GM controls require admin access." } unless request.enactor.is_admin?

        run = AresMUSH::DungeonRun[request.args[:run_id]]
        return { error: "Dungeon run not found." } unless run

        room = run.room

        case request.args[:action]

        when "doom"
          doom_data = Engine.advance_doom(run)
          if room
            room.emit "%xrThe dungeon noticed. Doom advances to #{doom_data[:new_doom]}.%xn"
            case doom_data[:threshold]
            when :alert   then room.emit "%xr#{room.name} goes on ALERT. 7-9 results now deal Stress.%xn"
            when :hostile then room.emit "%xr#{room.name} turns HOSTILE. Environmental threats incoming.%xn"
            when :lethal  then room.emit "%xr#{room.name} is LETHAL. Just being here requires a roll.%xn"
            end
          end

        when "threat"
          threats = [
            "A section of floor gives way.", "The torches go out.",
            "Something starts growling nearby.", "A tripwire — discovered too late.",
            "The corridor behind you shifts.", "Water starts pouring in from the walls.",
            "An alarm — magical, shrill, definitely heard.", "The smell of smoke."
          ]
          room.emit "%xr[ENVIRONMENTAL THREAT] #{threats.sample}%xn" if room

        when "progress"
          boxes    = (request.args[:boxes] || 1).to_i
          new_prog = run.progress_boxes.to_i + boxes
          run.update(progress_boxes: new_prog)
          if new_prog >= run.progress_max.to_i
            run.update(status: "complete")
            room.emit "%xg[DUNGEON CLEARED] The contract is complete!%xn" if room
          else
            room.emit "%xy[PROGRESS] #{boxes} box(es) marked. Total: #{new_prog}/#{run.progress_max}%xn" if room
          end
        end

        HeroesGuild.dungeon_run_web_data(run, request.enactor)
      end
    end

    # POST: Roll a named move from the Dungeon HUD.
    class HudRollMoveRequestHandler
      def handle(request)
        error = WebHelpers.check_login(request)
        return error if error

        char      = request.enactor
        run       = AresMUSH::DungeonRun[request.args[:run_id]]
        return { error: "Dungeon run not found." } unless run

        move_name   = request.args[:move_name]
        move_config = HeroesGuild.find_move(move_name)
        return { error: "No move called '#{move_name}'." }                       unless move_config
        return { error: "'#{move_name}' isn't in your playbook." }               unless HeroesGuild.char_has_move?(char, move_name)

        stat_name = move_config["stat"]
        room      = run.room
        room_name = room ? room.name : ""
        stat_val  = HeroesGuild.stat_value(char, stat_name,
                                           move_name: move_name, room_name: room_name)

        result = Engine.roll(stat_val)
        room.emit Engine.format_roll(char.name, move_name, stat_name, result) if room
        room.emit "%xc#{move_config['desc']}%xn" if room

        doom_level = run.doom_level.to_i
        data = Engine.consequence_data(char, result, doom_level)

        if data[:xp_bump]
          room.emit "You tried your best. Mark XP. (#{data[:new_xp]} total)" if room
        end
        if data[:stress_bump]
          room.emit "#{char.name} takes 1 Stress. (#{data[:new_stress]}/#{data[:stress_max]})" if room
        end

        if result[:tier] == :miss && run.status == "active"
          doom_data = Engine.advance_doom(run)
          if room
            room.emit "%xrThe dungeon noticed. Doom advances to #{doom_data[:new_doom]}.%xn"
            case doom_data[:threshold]
            when :alert   then room.emit "%xr#{room_name} goes on ALERT. 7-9 results now deal Stress.%xn"
            when :hostile then room.emit "%xr#{room_name} turns HOSTILE. Environmental threats incoming.%xn"
            when :lethal  then room.emit "%xr#{room_name} is LETHAL. Just being here requires a roll.%xn"
            end
          end
        end

        HeroesGuild.dungeon_run_web_data(run, char)
      end
    end

  end
end
