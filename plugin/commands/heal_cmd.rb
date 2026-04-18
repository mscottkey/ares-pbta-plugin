module AresMUSH
  module PbtA
    class HealCmd
      include CommandHandler

      attr_accessor :target_name

      def parse_args
        self.target_name = cmd.args ? cmd.args.strip : nil
      end

      def required_args
        [target_name]
      end

      def handle
        heal_moves = Global.read_config("pbta", "heal_moves") || []
        if heal_moves.empty?
          client.emit_failure "No heal moves are configured."
          return
        end

        heal_move_name = heal_moves.find { |m| PbtA.char_has_move?(enactor, m) }
        unless heal_move_name
          client.emit_failure "You don't have a healing move. " \
                              "(Requires: #{heal_moves.join(', ')})"
          return
        end

        target = Character.find_one_by_name(target_name)
        unless target
          client.emit_failure "Character '#{target_name}' not found."
          return
        end

        if target == enactor
          client.emit_failure "You cannot heal yourself."
          return
        end

        unless target.room == enactor.room
          client.emit_failure "#{target.name} is not here."
          return
        end

        if target.pbta_heal_cooldown
          cooldown_hours = Global.read_config("pbta", "heal_cooldown_hours").to_i
          cooldown_until = begin
            Time.parse(target.pbta_heal_cooldown) + (cooldown_hours * 3600)
          rescue
            nil
          end
          if cooldown_until && Time.now < cooldown_until
            hours_left = ((cooldown_until - Time.now) / 3600).ceil
            client.emit_failure "#{target.name} cannot be healed again for " \
                                "#{hours_left} hour(s)."
            return
          end
        end

        if target.pbta_stress.to_i == 0
          client.emit_failure "#{target.name} has no Stress to clear."
          return
        end

        move_config = PbtA.find_move(heal_move_name)
        unless move_config
          client.emit_failure "Heal move '#{heal_move_name}' not found in config."
          return
        end

        stat_name = move_config["stat"]
        room_name = enactor.room ? enactor.room.name : ""
        stat_val = PbtA.stat_value(enactor, stat_name,
                                   move_name: heal_move_name,
                                   room_name: room_name)

        result = Engine.roll(stat_val)
        enactor.room.emit Engine.format_roll(enactor.name, heal_move_name, stat_name, result)

        stress_max = Global.read_config("pbta", "stress_max").to_i

        case result[:tier]
        when :strong
          new_stress = [target.pbta_stress.to_i - 2, 0].max
          target.update(pbta_stress: new_stress,
                        pbta_last_stress_tick: Date.today.to_s,
                        pbta_heal_cooldown: Time.now.to_s)
          enactor.room.emit "%xg#{enactor.name} tends to #{target.name}. " \
                            "Clear 2 Stress. " \
                            "(#{target.name} Stress: #{new_stress}/#{stress_max})%xn"

        when :weak
          new_target_stress = [target.pbta_stress.to_i - 1, 0].max
          new_enactor_stress = [enactor.pbta_stress.to_i + 1, stress_max].min
          target.update(pbta_stress: new_target_stress,
                        pbta_heal_cooldown: Time.now.to_s)
          enactor.update(pbta_stress: new_enactor_stress)
          enactor.room.emit "%xy#{enactor.name} tends to #{target.name} " \
                            "at cost to themselves. " \
                            "#{target.name} clears 1 Stress " \
                            "(#{new_target_stress}/#{stress_max}). " \
                            "#{enactor.name} takes 1 Stress " \
                            "(#{new_enactor_stress}/#{stress_max}).%xn"

        when :miss
          new_enactor_stress = [enactor.pbta_stress.to_i + 1, stress_max].min
          enactor.update(pbta_stress: new_enactor_stress)
          data = Engine.consequence_data(enactor, result, 0)
          enactor.room.emit "%xr#{enactor.name} tries to help but makes things worse. " \
                            "#{target.name}'s Stress is unchanged. " \
                            "#{enactor.name} takes 1 Stress " \
                            "(#{new_enactor_stress}/#{stress_max}).%xn"
          if data[:xp_bump]
            enactor.room.emit "#{enactor.name} tried their best. " \
                              "Mark XP. (#{data[:new_xp]}/" \
                              "#{Global.read_config('pbta', 'xp_to_advance')})"
          end
        end
      end
    end

    # Staff command: +stress/set <char>=<amount>, +stress/freeze <char>=<days>,
    # +stress/unfreeze <char>
    class StressCmd
      include CommandHandler

      attr_accessor :target_name, :amount

      def parse_args
        if cmd.args && cmd.args.include?("=")
          parts = cmd.args.split("=", 2)
          self.target_name = parts[0].strip
          self.amount = parts[1].strip
        else
          self.target_name = cmd.args ? cmd.args.strip : nil
        end
      end

      def handle
        case cmd.switch
        when "set"      then do_set
        when "freeze"   then do_freeze
        when "unfreeze" then do_unfreeze
        else
          client.emit_failure "Use +stress/set <char>=<amount>, " \
                              "+stress/freeze <char>=<days>, " \
                              "or +stress/unfreeze <char>"
        end
      end

      private

      def do_set
        unless enactor.is_admin?
          client.emit_failure "Only staff can set stress directly."
          return
        end
        target = Character.find_one_by_name(target_name)
        unless target
          client.emit_failure "Character '#{target_name}' not found."
          return
        end
        stress_max = Global.read_config("pbta", "stress_max").to_i
        new_stress = [[amount.to_i, 0].max, stress_max].min
        target.update(pbta_stress: new_stress)
        client.emit_success "#{target.name} Stress set to #{new_stress}/#{stress_max}."
      end

      def do_freeze
        unless enactor.is_admin?
          client.emit_failure "Only staff can freeze stress recovery."
          return
        end
        target = Character.find_one_by_name(target_name)
        unless target
          client.emit_failure "Character '#{target_name}' not found."
          return
        end
        days = amount.to_i
        if days <= 0
          client.emit_failure "Days must be a positive number."
          return
        end
        frozen_until = (Date.today + days).to_s
        target.update(pbta_stress_frozen_until: frozen_until)
        client.emit_success "#{target.name} stress recovery frozen until #{frozen_until}."
        Login.notify(target, :jobs,
                     "Your stress recovery has been paused by staff until #{frozen_until}.",
                     target.id)
      end

      def do_unfreeze
        unless enactor.is_admin?
          client.emit_failure "Only staff can unfreeze stress recovery."
          return
        end
        target = Character.find_one_by_name(target_name)
        unless target
          client.emit_failure "Character '#{target_name}' not found."
          return
        end
        target.update(pbta_stress_frozen_until: nil)
        client.emit_success "#{target.name} stress recovery resumed."
        Login.notify(target, :jobs,
                     "Your stress recovery has been resumed by staff.",
                     target.id)
      end
    end
  end
end
