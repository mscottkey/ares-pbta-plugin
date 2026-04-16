module AresMUSH
  module HeroesGuild
    class InitStatsRequestHandler
      include WebRequestHandler
      def handle(request)
        char = get_character(request)
        return error_response("Not found") unless char
        
        role_name = Groups.group_value(char, "Playbook")
        return error_response("You must select a Playbook group first on the Groups tab.") if role_name.nil? || role_name.empty?

        roles = Global.read_config("heroesguild", "roles")
        return error_response("Invalid playbook in group settings.") unless roles[role_name]
        
        stats = roles[role_name]["stats"].stringify_keys
        char.update(pbta_stats: stats)
        { success: true }
      end
    end

    class SetGimmickRequestHandler
      include WebRequestHandler
      def handle(request)
        char = get_character(request)
        return error_response("Not found") unless char
        gimmick_name = request.args[:gimmick]
        gimmicks = Global.read_config("heroesguild", "gimmicks")
        return error_response("Invalid gimmick") unless gimmicks[gimmick_name]
        char.update(pbta_gimmick: gimmick_name)
        { success: true }
      end
    end

    class ChargenDataRequestHandler
      include WebRequestHandler
      def handle(request)
        roles = Global.read_config("heroesguild", "roles").map do |name, cfg|
          { name: name, desc: cfg["desc"], stats: cfg["stats"] }
        end
        gimmicks = Global.read_config("heroesguild", "gimmicks").map do |name, cfg|
          { name: name, desc: cfg["desc"] }
        end
        { roles: roles, gimmicks: gimmicks }
      end
    end
  end
end
