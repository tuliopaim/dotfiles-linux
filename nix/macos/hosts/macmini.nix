{ ... }:
{
  # No kanata here — Mac mini uses its keyboard as-is.

  # Default Pi to Copilot subagent preset for workplace isolation.
  # /subagent-preset still overrides this at the session level.
  home.sessionVariables.PI_SUBAGENT_PRESET = "copilot";
}
