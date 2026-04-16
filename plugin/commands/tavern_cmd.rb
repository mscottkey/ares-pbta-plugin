module AresMUSH
  module HeroesGuild
    module TavernHelpers
      FALLOUT_OUTCOMES = {
        "lost_gear"    => "%{name} wakes up to find something valuable... gone.",
        "new_rival"    => "Someone at this tavern now has strong feelings about %{name}. The negative kind.",
        "woke_in_debt" => "%{name} apparently made some promises last night. The kind with interest."
      }.freeze

      def tavern_fallout(char, room = enactor.room)
        msg = FALLOUT_OUTCOMES.values.sample % { name: char.name }
        room.emit "%xr[TAVERN FALLOUT] #{msg}%xn"
      end
    end

    class CarouseCmd
      include CommandHandler
      include TavernHelpers

      def handle
        night = HeroesGuild.active_tavern_night(enactor.room)
        unless night
          client.emit_failure "No tavern night is active here. Someone needs to open one first."
          return
        end
        participant = HeroesGuild.find_or_create_tavern_participant(night, enactor)

        room_name = enactor.room ? enactor.room.name : ""
        stat_val = HeroesGuild.stat_value(enactor, "heart",
                                          move_name: "Carouse",
                                          room_name: room_name)
        result = Engine.roll(stat_val)
        enactor.room.emit Engine.format_roll(enactor.name, "Carouse", "heart", result)

        case result[:tier]
        when :strong
          participant.update(vibe: participant.vibe.to_i + 2)
          new_stress = [enactor.pbta_stress.to_i - 2, 0].max
          enactor.update(pbta_stress: new_stress)
          enactor.room.emit t('heroesguild.carouse_success',
                               name: enactor.name, stress: 2, vibe: 2)
        when :weak
          participant.update(vibe: participant.vibe.to_i + 1)
          new_stress = [enactor.pbta_stress.to_i - 1, 0].max
          enactor.update(pbta_stress: new_stress)
          enactor.room.emit t('heroesguild.carouse_partial',
                               name: enactor.name, stress: 1)
        when :miss
          enactor.room.emit t('heroesguild.carouse_miss', name: enactor.name)
          tavern_fallout(enactor)
          run = HeroesGuild.active_dungeon_run(enactor.room)
          doom_level = run ? run.doom_level.to_i : 0
          data = Engine.consequence_data(enactor, result, doom_level)
          if data[:xp_bump]
            xp_msg = t('heroesguild.xp_gained', total: data[:new_xp])
            enactor.room.emit t('heroesguild.miss', xp_msg: xp_msg)
          end
        end
      end
    end

    class ImbibeCmd
      include CommandHandler
      include TavernHelpers

      def handle
        night = HeroesGuild.active_tavern_night(enactor.room)
        unless night
          client.emit_failure "No tavern night is active here. Someone needs to open one first."
          return
        end
        participant = HeroesGuild.find_or_create_tavern_participant(night, enactor)

        limit = HeroesGuild.ineb_limit(enactor)
        new_ineb = participant.inebriation.to_i + 1
        new_vibe = participant.vibe.to_i + 1
        participant.update(inebriation: new_ineb, vibe: new_vibe)

        if new_ineb >= limit
          enactor.room.emit t('heroesguild.inebriation_limit', name: enactor.name)
          participant.update(inebriation: 0)
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
        night = HeroesGuild.active_tavern_night(enactor.room)
        unless night
          client.emit_failure "No tavern night is active here."
          return
        end
        participant = HeroesGuild.find_or_create_tavern_participant(night, enactor)

        limit = HeroesGuild.ineb_limit(enactor)
        new_ineb = [participant.inebriation.to_i - 2, 0].max
        participant.update(inebriation: new_ineb)
        bar = ("#" * new_ineb).ljust(limit, "-")
        client.emit "#{enactor.name} sobers up a bit. [#{bar}] #{new_ineb}/#{limit}"
      end
    end
  end
end
