module AresMUSH
  module HeroesGuild
    class JobBoardRequestHandler
      def handle(request)
        contracts = AresMUSH::DungeonContract.find(status: "posted").map do |c|
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
