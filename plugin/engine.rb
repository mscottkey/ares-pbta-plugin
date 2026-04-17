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

      # Apply post-roll consequences to the character (XP on miss, stress on weak+doom>=4).
      # Returns a data hash - the caller (CommandHandler) is responsible for t() translations.
      # Keys: :xp_bump, :new_xp, :advance_ready, :stress_bump, :new_stress, :stress_max
      def self.consequence_data(char, result, doom_level = 0)
        data = { xp_bump: false, stress_bump: false, advance_ready: false }
        if result[:tier] == :miss
          new_xp = char.pbta_xp.to_i + 1
          char.update(pbta_xp: new_xp)
          data[:xp_bump] = true
          data[:new_xp] = new_xp
          xp_to_advance = Global.read_config("pbta_misc", "xp_to_advance").to_i
          data[:advance_ready] = (new_xp >= xp_to_advance)
        elsif result[:tier] == :weak && doom_level >= 4
          new_stress = char.pbta_stress.to_i + 1
          char.update(pbta_stress: new_stress)
          data[:stress_bump] = true
          data[:new_stress] = new_stress
          data[:stress_max] = Global.read_config("pbta_misc", "stress_max").to_i
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
