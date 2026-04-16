module AresMUSH
  module HeroesGuild
    class JobBoardRequestHandler
      include WebRequestHandler

      def handle(request)
        contracts = DungeonContract.find(status: "posted").map do |c|
          {
            id: c.id,
            title: c.title,
            description: c.description,
            modifier: c.modifier,
            status: c.status
          }
        end
        { contracts: contracts }
      end
    end
  end
end
