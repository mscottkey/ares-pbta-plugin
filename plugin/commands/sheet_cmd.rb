module AresMUSH
  module PbtA
    class SheetCmd
      include CommandHandler

      attr_accessor :target_name

      def parse_args
        self.target_name = cmd.args ? titlecase_arg(cmd.args) : enactor_name
      end

      def handle
        ClassTargetFinder.with_a_character(target_name, client, enactor) do |target|
          template = SheetTemplate.new(target, client)
          client.emit template.render
        end
      end
    end
  end
end
