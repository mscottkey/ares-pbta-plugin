module AresMUSH
  module PbtA
    module Engine
      # Core PbtA roll: 2d6 + stat + modifier
      # Returns: { roll:, stat_val:, modifier:, total:, tier: :strong/:weak/:miss, dice: [d1,d2] }
      def self.roll(stat_value, modifier = 0)
        die1 = rand(1..6)
        die2 = rand(1..6)
        total = die1 + die2 + stat_value + modifier
        tier = case total
               when 10..Float::INFINITY then :strong
               when 7..9 then :weak
               else :miss
               end
        { roll: die1 + die2, stat_val: stat_value, modifier: modifier,
          total: total, tier: tier, dice: [die1, die2] }
      end

      # Apply post-roll consequences to the character (XP on miss, stress on doom>=4 non-strong).
      # Returns a data hash - the caller (CommandHandler) is responsible for t() translations.
      # Keys: :xp_bump, :xp_accumulating, :xp_remainder, :xp_rate_limited, :new_xp,
      #       :advance_ready, :stress_bump, :new_stress, :stress_max
      def self.consequence_data(char, result, doom_level = 0)
        stress_max = Global.read_config("pbta", "stress_max").to_i
        xp_to_advance = Global.read_config("pbta", "xp_to_advance").to_i
        xp_per_miss = (Global.read_config("pbta", "xp_per_miss") || 1).to_f

        data = {
          xp_bump: false,
          xp_accumulating: false,
          xp_remainder: 0.0,
          xp_rate_limited: false,
          new_xp: char.pbta_xp.to_i,
          advance_ready: false,
          stress_bump: false,
          new_stress: char.pbta_stress.to_i,
          stress_max: stress_max
        }

        if result[:tier] == :miss
          xp_require_container = Global.read_config("pbta", "xp_require_container")
          in_container = false

          if xp_require_container
            if defined?(AresMUSH::HeroesGuild)
              room = char.room
              if room
                in_container = HeroesGuild.active_dungeon_run(room) ||
                               HeroesGuild.active_tavern_night(room)
              end
            end
          end

          if !xp_require_container || in_container
            # Check rate limit — refresh window if it has expired
            rate_limit = (Global.read_config("pbta", "xp_rate_limit") || 0).to_i
            rate_days  = (Global.read_config("pbta", "xp_rate_days")  || 1).to_i
            rate_limited = false

            if rate_limit > 0
              today = Date.today
              window_start = char.pbta_xp_rate_window_start ?
                (Date.parse(char.pbta_xp_rate_window_start) rescue nil) : nil

              if window_start.nil? || (today - window_start).to_i >= rate_days
                # Window expired or never set — reset counter
                char.update(pbta_xp_rate_window_start: today.to_s, pbta_xp_rate_earned: 0)
                window_earned = 0
              else
                window_earned = char.pbta_xp_rate_earned.to_i
              end

              rate_limited = window_earned >= rate_limit
            end

            if rate_limited
              data[:xp_rate_limited] = true
            else
              remainder = (char.pbta_xp_remainder || 0.0).to_f + xp_per_miss
              whole_xp = remainder.floor
              new_remainder = remainder - whole_xp

              if whole_xp > 0
                # Cap whole_xp at how much room is left in the window
                if rate_limit > 0
                  headroom = rate_limit - char.pbta_xp_rate_earned.to_i
                  whole_xp = [whole_xp, headroom].min
                  new_remainder = (remainder - whole_xp)
                end

                new_xp = char.pbta_xp.to_i + whole_xp
                updates = { pbta_xp: new_xp, pbta_xp_remainder: new_remainder }
                updates[:pbta_xp_rate_earned] = char.pbta_xp_rate_earned.to_i + whole_xp if rate_limit > 0
                char.update(updates)
                data[:xp_bump] = true
                data[:new_xp] = new_xp
                data[:advance_ready] = new_xp >= xp_to_advance
              else
                char.update(pbta_xp_remainder: new_remainder)
                data[:xp_accumulating] = true
                data[:xp_remainder] = new_remainder
              end
            end
          end
        end

        if doom_level >= 4 && result[:tier] != :strong
          new_stress = [char.pbta_stress.to_i + 1, stress_max].min
          if new_stress > char.pbta_stress.to_i
            char.update(pbta_stress: new_stress)
            data[:stress_bump] = true
            data[:new_stress] = new_stress
          end
        end

        data
      end

      # Increment doom on a contract. Returns data hash - caller handles t() translations.
      # Keys: :new_doom, :threshold (:alert/:hostile/:lethal/nil)
      def self.advance_doom(contract)
        new_doom = contract.doom_level.to_i + 1
        contract.update(doom_level: new_doom)
        threshold = case new_doom
                    when 4  then :alert
                    when 7  then :hostile
                    when 10 then :lethal
                    end
        { new_doom: new_doom, threshold: threshold }
      end

      # Format the dice roll output string for emit (uses Ares ANSI color codes).
      def self.format_roll(char_name, move_name, stat_name, result)
        dice_str = "[#{result[:dice][0]}+#{result[:dice][1]}]"
        mod_str = ""
        if result[:modifier] != 0
          mod_str = " #{result[:modifier] >= 0 ? '+' : ''}#{result[:modifier]}"
        end
        tier_label = { strong: "%xg10+%xn", weak: "%xy7-9%xn", miss: "%xr6-%xn" }[result[:tier]]
        "%xh#{char_name}%xn rolls %xc#{move_name}%xn (+#{stat_name}): " \
        "#{dice_str} + #{result[:stat_val]}#{mod_str} = %xh#{result[:total]}%xn #{tier_label}"
      end
    end
  end
end
