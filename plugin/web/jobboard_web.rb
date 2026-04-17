module AresMUSH
  module HeroesGuild

    class GuildBoardRequestHandler
      def handle(request)
        # ── Active Leads ─────────────────────────────────────────────
        leads = AresMUSH::PbtaLead.find(status: "open").map do |lead|
          char        = lead.character
          reply_count = 0
          job_url     = nil

          if lead.job_id
            job = AresMUSH::Job[lead.job_id]
            if job
              reply_count = job.replies.count
              job_url     = "/jobs/#{job.id}"
            end
          end

          inactive = HeroesGuild.lead_inactive_days(lead)

          {
            id:             lead.id,
            title:          lead.title,
            description:    lead.description,
            investigator:   char ? char.name : "Unknown",
            clues_gathered: lead.clues_gathered.to_i,
            clues_needed:   lead.clues_needed.to_i,
            reply_count:    reply_count,
            job_url:        job_url,
            inactive_days:  inactive,
            idle:           inactive && inactive >= 7,
            can_clue:       request.enactor && lead.character_id == request.enactor.id
          }
        end

        # ── Posted Contracts ─────────────────────────────────────────
        contracts = AresMUSH::DungeonContract.find(status: "posted").map do |c|
          {
            id:          c.id,
            title:       c.title,
            description: c.description,
            modifier:    c.modifier
          }
        end

        # ── Active & Pending Runs ─────────────────────────────────────
        active_runs = []

        AresMUSH::DungeonRun.find(status: "active").each do |run|
          party = run.participants.map { |p| p.character&.name }.compact
          active_runs << {
            id:             run.id,
            contract_title: run.contract ? run.contract.title : "Unnamed Run",
            modifier:       run.contract ? run.contract.modifier : nil,
            doom_level:     run.doom_level.to_i,
            doom_label:     HeroesGuild.doom_label(run.doom_level.to_i),
            progress:       run.progress_boxes.to_i,
            progress_max:   run.progress_max.to_i,
            party:          party
          }
        end

        AresMUSH::DungeonRun.find(status: "pending").each do |run|
          active_runs << {
            id:             run.id,
            contract_title: "Pending — selecting contract",
            modifier:       nil,
            doom_level:     0,
            doom_label:     "Safe",
            progress:       0,
            progress_max:   0,
            party:          run.participants.map { |p| p.character&.name }.compact
          }
        end

        # ── Recent History ────────────────────────────────────────────
        recent = []
        ["complete", "failed"].each do |status|
          AresMUSH::DungeonRun.find(status: status).to_a
            .sort_by { |r| r.ended_at || "" }
            .last(10)
            .reverse
            .each do |run|
            recent << {
              status:         run.status,
              contract_title: run.contract ? run.contract.title : "Unknown",
              doom_level:     run.doom_level.to_i,
              ended_at:       run.ended_at
            }
          end
        end

        global_cap   = Global.read_config("heroesguild", "lead_global_cap").to_i
        active_count = AresMUSH::PbtaLead.find(status: "open").count

        {
          leads:       leads,
          contracts:   contracts,
          active_runs: active_runs,
          recent:      recent,
          lead_cap:    global_cap,
          lead_count:  active_count,
          board_full:  active_count >= global_cap
        }
      end
    end

    # Backward-compat alias — existing calls to heroesguildJobBoard still work.
    JobBoardRequestHandler = GuildBoardRequestHandler

  end
end
