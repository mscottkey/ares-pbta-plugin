module AresMUSH
  module HeroesGuild
    class LeadCmd
      include CommandHandler

      def handle
        if cmd.root == "investigate"
          do_investigate
          return
        end

        case cmd.switch
        when "list"    then do_list
        when "clue"    then do_clue
        when "convert" then do_convert
        else
          client.emit_failure "Use +investigate, +lead/list, +lead/clue <id>, or +lead/convert <id>"
        end
      end

      private

      LEAD_SEEDS = [
        ["Rumors of a sealed vault east of the Ashwood", "Someone paid a lot to keep this quiet."],
        ["A merchant paid triple for an escort that never arrived", "Three guards. No bodies found."],
        ["Old guild records mention a dungeon with no exit", "...and one survivor who won't talk about it."],
        ["A map fragment, incomplete, found in a dead man's boot", "The symbols don't match any known dungeon."],
        ["The night watch has been avoiding the old mill", "Won't say why. Eyes say plenty."]
      ].freeze

      MODIFIERS = ["Cursed Gold", "Anti-Magic Field", "Haunted",
                   "Flooded Lower Levels", "Boss Guarded", "Trapped Entrance"].freeze

      def do_investigate
        room_name = enactor.room ? enactor.room.name : ""
        stat_val = HeroesGuild.stat_value(enactor, "cunning",
                                          move_name: "Investigate",
                                          room_name: room_name)
        result = Engine.roll(stat_val)
        enactor.room.emit Engine.format_roll(enactor.name, "Investigate", "cunning", result)

        if result[:tier] == :miss
          run = HeroesGuild.active_dungeon_run(enactor.room)
          doom_level = run ? run.doom_level.to_i : 0
          data = Engine.consequence_data(enactor, result, doom_level)
          if data[:xp_bump]
            xp_msg = t('heroesguild.xp_gained', total: data[:new_xp])
            enactor.room.emit t('heroesguild.miss', xp_msg: xp_msg)
            client.emit t('heroesguild.advance_ready', name: enactor.name) if data[:advance_ready]
          end
          if run && run.status == "active"
            doom_data = Engine.advance_doom(run)
            enactor.room.emit "%xr#{t('heroesguild.doom_increased', level: doom_data[:new_doom])}%xn"
            case doom_data[:threshold]
            when :alert   then enactor.room.emit "%xr#{t('heroesguild.doom_alert',   room: room_name)}%xn"
            when :hostile then enactor.room.emit "%xr#{t('heroesguild.doom_hostile', room: room_name)}%xn"
            when :lethal  then enactor.room.emit "%xr#{t('heroesguild.doom_lethal',  room: room_name)}%xn"
            end
          end
        else
          lead_info = LEAD_SEEDS.sample
          clues = result[:tier] == :strong ? 2 : 4
          lead = AresMUSH::PbtaLead.create(title: lead_info[0], description: lead_info[1],
                                            status: "open", clues_needed: clues,
                                            character: enactor)
          enactor.room.emit t('heroesguild.lead_generated', name: enactor.name, desc: lead.title)
          enactor.room.emit "%xy(Lead requires #{clues} clue(s) to convert)%xn"
          if result[:tier] == :weak
            enactor.room.emit "%xr[COMPLICATION] You also drew unwanted attention while asking around.%xn"
          end
        end
      end

      def do_list
        leads = AresMUSH::PbtaLead.find(character_id: enactor.id, status: "open")
        if leads.empty?
          client.emit "You have no active leads."
          return
        end

        output = ["%xhYour Active Leads:%xn"]
        leads.each do |l|
          output << "[#{l.id}] #{l.title} (Clues: #{l.clues_gathered}/#{l.clues_needed})"
        end
        client.emit output.join("\n")
      end

      def do_clue
        id = cmd.args ? cmd.args.strip : nil
        lead = AresMUSH::PbtaLead[id]
        unless lead && lead.character_id == enactor.id && lead.status == "open"
          client.emit_failure "Lead not found or cannot be modified."
          return
        end

        lead.update(clues_gathered: lead.clues_gathered.to_i + 1)
        client.emit "Marked a clue on lead #{lead.id}. (#{lead.clues_gathered}/#{lead.clues_needed})"
        convert_lead(lead) if lead.clues_gathered.to_i >= lead.clues_needed.to_i
      end

      def do_convert
        id = cmd.args ? cmd.args.strip : nil
        lead = AresMUSH::PbtaLead[id]
        unless lead && lead.status == "open"
          client.emit_failure "Lead not found or already converted."
          return
        end

        unless enactor.is_admin?
          client.emit_failure "Only staff can manually convert a lead without gathering clues."
          return
        end

        convert_lead(lead)
      end

      def convert_lead(lead)
        lead.update(status: "converted")
        mod = MODIFIERS.sample
        contract = AresMUSH::DungeonContract.create(title: lead.title, description: lead.description,
                                                     modifier: mod, character: lead.character,
                                                     status: "posted")
        enactor.room.emit t('heroesguild.lead_converted', title: contract.title)
        enactor.room.emit "%xcThe dungeon has a modifier: #{mod}%xn"
      end
    end
  end
end
