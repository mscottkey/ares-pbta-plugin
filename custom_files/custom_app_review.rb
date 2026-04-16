module AresMUSH
  module Chargen
    module CustomAppReview
      def self.app_review(char)
        errors = []
        if !char.pbta_stats || char.pbta_stats.empty?
          errors << "You must click 'Auto-Populate Playbook Stats' in the Playbook Setup stage."
        end
        if !char.pbta_gimmick
          errors << "You must select a Gimmick in the Playbook chargen stage."
        end
        errors
      end
    end
  end
end
