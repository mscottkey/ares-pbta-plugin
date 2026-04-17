module AresMUSH
  module Profile
    class CustomCharFields
      def self.get_fields_for_viewing(char, viewer)
        fields = {}
        fields[:pbta] = PbtA::CharProfileWeb.get_fields(char, viewer)
        fields
      end
    end
  end
end
