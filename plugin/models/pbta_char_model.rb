module AresMUSH
  class Character
    attribute :pbta_role
    attribute :pbta_gimmick
    attribute :pbta_stats,  :type => DataType::Hash,    :default => {}
    attribute :pbta_moves,  :type => DataType::Array,   :default => []
    attribute :pbta_xp,                  :type => DataType::Integer, :default => 0
    attribute :pbta_xp_remainder,        :type => DataType::Float,   :default => 0.0
    attribute :pbta_stress,              :type => DataType::Integer, :default => 0
    attribute :pbta_last_stress_tick     # date string "YYYY-MM-DD", nil = never ticked
    attribute :pbta_stress_frozen_until  # date string "YYYY-MM-DD", nil = not frozen
    attribute :pbta_heal_cooldown        # datetime string, nil = not on cooldown
    attribute :pbta_xp_rate_window_start # date string "YYYY-MM-DD", start of current rate window
    attribute :pbta_xp_rate_earned,      :type => DataType::Integer, :default => 0

  end
end
