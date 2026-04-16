module AresMUSH
  module HeroesGuild
    class ContractCmd
      include CommandHandler

      MODIFIERS = ["Cursed Gold", "Anti-Magic Field", "Haunted",
                   "Flooded Lower Levels", "Boss Guarded", "Trapped Entrance"].freeze

      def handle
        case cmd.switch
        when "list" then do_list
        when "take" then do_take
        when "post" then do_post
        else
          client.emit_failure "Use +contract/list, +contract/take <id>, or +contract/post <title>=<desc>"
        end
      end

      private

      def do_list
        contracts = AresMUSH::DungeonContract.find(status: "posted")
        if contracts.empty?
          client.emit "No contracts posted on the board."
          return
        end

        output = ["%xhJob Board:%xn"]
        contracts.each do |c|
          output << "[#{c.id}] #{c.title} (Modifier: #{c.modifier || 'None'})"
        end
        client.emit output.join("\n")
      end

      def do_take
        id = cmd.args ? cmd.args.strip : nil
        contract = AresMUSH::DungeonContract[id]
        unless contract && contract.status == "posted"
          client.emit_failure "Contract not found or unavailable."
          return
        end

        message = "#{enactor.name} has accepted the contract.\n\nDescription: #{contract.description}\nModifier: #{contract.modifier}"
        result = Jobs.create_job("HeroesGuild Contracts", "Contract: #{contract.title}", message, enactor)
        job = result[:job]

        contract.update(status: "active", character: enactor, job_id: job ? job.id.to_i : nil)
        enactor.room.emit "%xgContract accepted. The dungeon is waiting. " \
                          "(Ticket opened: #{job ? job.id : 'N/A'})%xn"
      end

      def do_post
        unless enactor.is_admin?
          client.emit_failure "Only staff can manually post contracts."
          return
        end

        unless cmd.args && cmd.args.include?("=")
          client.emit_failure "Format: +contract/post <title>=<desc>"
          return
        end

        title, desc = cmd.args.split("=", 2).map(&:strip)
        mod = MODIFIERS.sample

        AresMUSH::DungeonContract.create(title: title, description: desc,
                                          modifier: mod, status: "posted")
        enactor.room.emit "Posted new contract: #{title}"
      end
    end
  end
end
