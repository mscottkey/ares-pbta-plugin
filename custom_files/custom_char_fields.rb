module AresMUSH
  module Profile
    class CustomCharFields
      def self.get_fields(char, viewer)
        fields = {}
        # Add inside the get_fields method:
        fields[:heroesguild] = HeroesGuild::CharProfileWeb.get_fields(char, viewer)
        
        fields
      end
    end
  end
end
