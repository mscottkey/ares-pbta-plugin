module AresMUSH
  module PbtA
    class PlaybookCmd
      include CommandHandler

      attr_accessor :role_name

      def parse_args
        self.role_name = cmd.args ? cmd.args.strip : nil
      end

      def handle
        if role_name.nil?
          output = ["%xhAvailable Playbooks:%xn"]
          PbtA.playbook_list.each do |p|
            output << "%xh#{p[:name]}%xn — #{p[:desc]}"
            output << "  Stats: #{p[:stats]}"
            output << "  Core Moves: #{p[:core_moves].join(', ')}"
          end
          client.emit output.join("\n")
        else
          result = PbtA.set_playbook(enactor, role_name)
          if result[:error]
            client.emit_failure result[:error]
          else
            client.emit_success "Playbook set to #{role_name}. Stats initialized."
          end
        end
      end
    end

    class GimmickCmd
      include CommandHandler

      attr_accessor :gimmick_name

      def parse_args
        self.gimmick_name = cmd.args ? cmd.args.strip : nil
      end

      def handle
        if gimmick_name.nil?
          output = ["%xhAvailable Gimmicks:%xn"]
          PbtA.gimmick_list.each do |g|
            output << "%xh#{g[:name]}%xn — #{g[:desc]}"
          end
          client.emit output.join("\n")
        else
          result = PbtA.set_gimmick(enactor, gimmick_name)
          if result[:error]
            client.emit_failure result[:error]
          else
            client.emit_success "Gimmick set to #{gimmick_name}."
          end
        end
      end
    end
  end
end
