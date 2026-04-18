module AresMUSH
  module PbtA
    # Initializes pbta_stats and pbta_role from the character's Groups Playbook setting.
    class InitStatsRequestHandler
      def handle(request)
        return { error: t('webportal.not_logged_in') } unless request.enactor
        char = request.enactor
        role_name = char.group("Playbook")
        return { error: "Select a Playbook group first." } if role_name.nil? || role_name.empty?
        PbtA.set_playbook(char, role_name)
      end
    end

    # Sets pbta_role directly (web chargen role picker).
    class SetRoleRequestHandler
      def handle(request)
        return { error: t('webportal.not_logged_in') } unless request.enactor
        PbtA.set_playbook(request.enactor, request.args["role"])
      end
    end

    class SetGimmickRequestHandler
      def handle(request)
        return { error: t('webportal.not_logged_in') } unless request.enactor
        PbtA.set_gimmick(request.enactor, request.args["gimmick"])
      end
    end

    # Returns roles and gimmicks list for the chargen UI (no login required - read-only).
    class ChargenDataRequestHandler
      def handle(request)
        char = request.enactor
        result = {
          roles: PbtA.playbook_list,
          gimmicks: PbtA.gimmick_list
        }
        if char
          result[:char_role] = char.pbta_role
          result[:char_gimmick] = char.pbta_gimmick
        end
        result
      end
    end
  end
end
