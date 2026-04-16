module AresMUSH
  module HeroesGuild
    module TavernHelpers
      FALLOUT_OUTCOMES = {
        "lost_gear"    => "%{name} wakes up to find something valuable... gone.",
        "new_rival"    => "Someone at this tavern now has strong feelings about %{name}. The negative kind.",
        "woke_in_debt" => "%{name} apparently made some promises last night. The kind with interest."
      }.freeze

      def tavern_fallout(char)
        msg = FALLOUT_OUTCOMES.values.sample % { name: char.name }
        enactor.room.emit "%xr[TAVERN FALLOUT] #{msg}%xn"
      end
    end

    class CarouseCmd
      include CommandHandler
      include TavernHelpers

      def handle
        room_name = enactor.room ? enactor.room.name : ""
        stat_val = HeroesGuild.stat_value(enactor, "heart",
                                          move_name: "Carouse",
                                          room_name: room_name)
        result = Engine.roll(stat_val)
        enactor.room.emit Engine.format_roll(enactor.name, "Carouse", "heart", result)

        case result[:tier]
        when :strong
          new_stress = [enactor.pbta_stress.to_i - 2, 0].max
          new_vibe = enactor.pbta_vibe.to_i + 2
          enactor.update(pbta_stress: new_stress, pbta_vibe: new_vibe)
          enactor.room.emit t('heroesguild.carouse_success',
                               name: enactor.name, stress: 2, vibe: 2)
        when :weak
          new_stress = [enactor.pbta_stress.to_i - 1, 0].max
          new_vibe = enactor.pbta_vibe.to_i + 1
          enactor.update(pbta_stress: new_stress, pbta_vibe: new_vibe)
          enactor.room.emit t('heroesguild.carouse_partial',
                               name: enactor.name, stress: 1)
        when :miss
          enactor.room.emit t('heroesguild.carouse_miss', name: enactor.name)
          tavern_fallout(enactor)
        end
      end
    end

    class ImbibeCmd
      include CommandHandler
      include TavernHelpers

      def handle
        brawn = (enactor.pbta_stats["brawn"] || 0).to_i
        limit = 5 + brawn
        new_ineb = enactor.pbta_inebriation.to_i + 1
        new_vibe = enactor.pbta_vibe.to_i + 1
        enactor.update(pbta_inebriation: new_ineb, pbta_vibe: new_vibe)

        if new_ineb >= limit
          enactor.room.emit t('heroesguild.inebriation_limit', name: enactor.name)
          enactor.update(pbta_inebriation: 0)
          tavern_fallout(enactor)
        else
          bar = ("#" * new_ineb).ljust(limit, "-")
          enactor.room.emit "%xc#{enactor.name}%xn drinks. [#{bar}] #{new_ineb}/#{limit}  Vibe: #{new_vibe}"
        end
      end
    end

    class SoberCmd
      include CommandHandler

      def handle
        brawn = (enactor.pbta_stats["brawn"] || 0).to_i
        limit = 5 + brawn
        new_ineb = [enactor.pbta_inebriation.to_i - 2, 0].max
        enactor.update(pbta_inebriation: new_ineb)
        bar = ("#" * new_ineb).ljust(limit, "-")
        client.emit "#{enactor.name} sobers up a bit. [#{bar}] #{new_ineb}/#{limit}"
      end
    end
  end
end
