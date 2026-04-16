module AresMUSH
  module HeroesGuild
    module Engine
      # Core PbtA roll: 2d6 + stat + modifier
      # Returns a hash: { roll: int, stat_val: int, modifier: int, 
      #                   total: int, tier: :strong/:weak/:miss, dice: [int,int] }
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

      # Apply post-roll consequences: XP on miss, stress on weak+alert doom
      # Returns array of result message strings for emit
      def self.apply_consequences(char, result, doom_level = 0)
        messages = []
        if result[:tier] == :miss
          new_xp = char.pbta_xp.to_i + 1
          char.update(pbta_xp: new_xp)
          xp_msg = t('heroesguild.xp_gained', total: new_xp)
          messages << t('heroesguild.miss', xp_msg: xp_msg)
          if new_xp >= Global.read_config("heroesguild", "xp_to_advance").to_i
            messages << t('heroesguild.advance_ready', name: char.name)
          end
        elsif result[:tier] == :weak && doom_level >= 4
          new_stress = char.pbta_stress.to_i + 1
          char.update(pbta_stress: new_stress)
          max_stress = Global.read_config("heroesguild", "stress_max").to_i
          messages << t('heroesguild.stress_taken', name: char.name, 
                         amount: 1, total: new_stress, max: max_stress)
        end
        messages
      end

      # Increment doom on a room/dungeon object, check thresholds
      # char is the roller; room_name for messaging
      # Returns array of threshold alert strings (may be empty)
      def self.advance_doom(contract, room_name)
        messages = []
        new_doom = contract.doom_level.to_i + 1
        contract.update(doom_level: new_doom)
        messages << t('heroesguild.doom_increased', level: new_doom)
        thresholds = Global.read_config("heroesguild", "doom_thresholds")
        if thresholds[new_doom.to_s]
          case new_doom
          when 4 then messages << t('heroesguild.doom_alert', room: room_name)
          when 7 then messages << t('heroesguild.doom_hostile', room: room_name)
          when 10 then messages << t('heroesguild.doom_lethal', room: room_name)
          end
        end
        messages
      end

      # Format the dice roll output string for emit
      def self.format_roll(char_name, move_name, stat_name, result)
        dice_str = "[#{result[:dice][0]}+#{result[:dice][1]}]"
        mod_str = result[:modifier] != 0 ? " #{result[:modifier] >= 0 ? '+' : ''}#{result[:modifier]}" : ""
        tier_label = { strong: "%xg10+%xn", weak: "%xy7-9%xn", miss: "%xr6-%xn" }[result[:tier]]
        "%xh#{char_name}%xn rolls %xc#{move_name}%xn (+#{stat_name}): " \
        "#{dice_str} + #{result[:stat_val]}#{mod_str} = %xh#{result[:total]}%xn #{tier_label}"
      end
    end
  end
end
