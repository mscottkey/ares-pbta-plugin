module AresMUSH
  module PbtA
    class StressRecoveryEventHandler
      def on_event(event)
        return unless Global.read_config("pbta", "stress_recovery")

        cron_config = Global.read_config("pbta", "stress_recovery_cron")
        return if !Cron.is_cron_match?(cron_config, event.time)

        multiplier = (Global.read_config("pbta", "stress_recovery_multiplier") || 1).to_i
        today = Date.today
        today_str = today.to_s
        stress_max = Global.read_config("pbta", "stress_max").to_i

        Character.all.each do |char|
          next if char.pbta_stress.to_i <= 0
          next unless char.pbta_role  # skip non-PbtA characters

          # Check if recovery is frozen
          if char.pbta_stress_frozen_until
            frozen_until = begin
              Date.parse(char.pbta_stress_frozen_until)
            rescue
              nil
            end
            next if frozen_until && today <= frozen_until
          end

          # Days needed before next tick = current_stress * multiplier
          days_needed = char.pbta_stress.to_i * multiplier
          next if days_needed <= 0

          last_tick = char.pbta_last_stress_tick ?
            (Date.parse(char.pbta_last_stress_tick) rescue nil) : nil

          # If never ticked, record today as start and wait until next check
          unless last_tick
            char.update(pbta_last_stress_tick: today_str)
            next
          end

          days_since_tick = (today - last_tick).to_i
          next if days_since_tick < days_needed

          new_stress = [char.pbta_stress.to_i - 1, 0].max
          char.update(pbta_stress: new_stress,
                      pbta_last_stress_tick: today_str)

          Login.notify(char, :jobs,
                       "Your Stress has recovered. " \
                       "Current Stress: #{new_stress}/#{stress_max}.",
                       char.id)

          Global.logger.info "PbtA stress recovery: #{char.name} " \
                             "#{char.pbta_stress.to_i + 1} -> #{new_stress}"
        end
      end
    end
  end
end
