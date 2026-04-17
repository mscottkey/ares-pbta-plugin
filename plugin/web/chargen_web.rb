module AresMUSH
  module PbtA
    # Initializes pbta_stats and pbta_role from the character's Groups Playbook setting.
    class InitStatsRequestHandler
      def handle(request)
        error = WebHelpers.check_login(request)
        return error if error

        char = request.enactor
        role_name = Groups.group_value(char, "Playbook")
        return { error: "You must select a Playbook group first on the Groups tab." } if role_name.nil? || role_name.empty?

        roles = Global.read_config("pbta", "roles")
        return { error: "Invalid playbook in group settings." } unless roles[role_name]

        stats = roles[role_name]["stats"].stringify_keys
        char.update(pbta_stats: stats, pbta_role: role_name)
        { success: true }
      end
    end

    # Sets pbta_role directly (web chargen role picker, if used instead of Groups).
    class SetRoleRequestHandler
      def handle(request)
        error = WebHelpers.check_login(request)
        return error if error

        char = request.enactor
        role_name = request.args[:role]
        roles = Global.read_config("pbta", "roles")
        return { error: "Invalid role." } unless roles[role_name]

        stats = roles[role_name]["stats"].stringify_keys
        char.update(pbta_role: role_name, pbta_stats: stats)
        { success: true }
      end
    end

    class SetGimmickRequestHandler
      def handle(request)
        error = WebHelpers.check_login(request)
        return error if error

        char = request.enactor
        gimmick_name = request.args[:gimmick]
        gimmicks = Global.read_config("pbta", "gimmicks")
        return { error: "Invalid gimmick." } unless gimmicks[gimmick_name]

        char.update(pbta_gimmick: gimmick_name)
        { success: true }
      end
    end

    # Returns roles and gimmicks list for the chargen UI (no login required — read-only).
    class ChargenDataRequestHandler
      def handle(request)
        roles = Global.read_config("pbta", "roles").map do |name, cfg|
          { name: name, desc: cfg["desc"], stats: cfg["stats"] }
        end
        gimmicks = Global.read_config("pbta", "gimmicks").map do |name, cfg|
          { name: name, desc: cfg["desc"] }
        end
        { roles: roles, gimmicks: gimmicks }
      end
    end
  end
end
