module AresMUSH
  module HeroesGuild
    class LeadsCmd
      include CommandHandler

      attr_accessor :days

      def parse_args
        self.days = cmd.args ? cmd.args.strip.to_i : nil
      end

      def handle
        case cmd.switch
        when "flush" then do_flush
        when "list"  then do_list_all
        else
          client.emit_failure "Use +leads/flush <days> or +leads/list"
        end
      end

      private

      def do_flush
        unless enactor.is_admin?
          client.emit_failure "Only staff can flush leads."
          return
        end

        unless days && days > 0
          client.emit_failure "Usage: +leads/flush <days> — e.g. +leads/flush 14"
          return
        end

        client.emit t('heroesguild.leads_flush_header', days: days)

        open_leads = AresMUSH::PbtaLead.find(status: "open").to_a
        flushed = 0
        output  = []

        open_leads.each do |lead|
          inactive = HeroesGuild.lead_inactive_days(lead)
          next unless inactive && inactive >= days

          result = HeroesGuild.close_lead(lead, enactor, reason: :idle)

          case result[:outcome]
          when :converted
            output << t('heroesguild.leads_flush_converted',
                        title: lead.title,
                        clues: lead.clues_gathered,
                        needed: lead.clues_needed)
          when :archived
            output << t('heroesguild.leads_flush_archived',
                        title: lead.title,
                        clues: lead.clues_gathered,
                        needed: lead.clues_needed)
          when :removed
            output << t('heroesguild.leads_flush_removed',
                        title: lead.title,
                        needed: lead.clues_needed)
          end

          flushed += 1
        end

        if flushed == 0
          client.emit t('heroesguild.leads_flush_none', days: days)
          return
        end

        output.each { |line| client.emit line }

        global_cap   = Global.read_config("heroesguild", "lead_global_cap").to_i
        active_count = AresMUSH::PbtaLead.find(status: "open").count
        client.emit t('heroesguild.leads_flush_summary',
                      count: flushed,
                      active: active_count,
                      cap: global_cap)
      end

      def do_list_all
        unless enactor.is_admin?
          client.emit_failure "Only staff can view all leads."
          return
        end

        open_leads = AresMUSH::PbtaLead.find(status: "open").to_a
        global_cap = Global.read_config("heroesguild", "lead_global_cap").to_i

        if open_leads.empty?
          client.emit "No open leads on the board."
          return
        end

        output = []
        output << "%xh%xbActive Leads (#{open_leads.count}/#{global_cap}):%xn"
        output << "%xb#{"─" * 60}%xn"

        open_leads.each do |lead|
          char     = lead.character
          inactive = HeroesGuild.lead_inactive_days(lead)
          inactive_str = inactive ? "#{inactive}d idle" : "no job"
          output << "[#{lead.id}] #{lead.title}"
          output << "      By: #{char ? char.name : 'Unknown'} | " \
                    "Clues: #{lead.clues_gathered}/#{lead.clues_needed} | " \
                    "#{inactive_str}"
        end

        output << "%xb#{"─" * 60}%xn"
        client.emit output.join("\n")
      end
    end
  end
end
