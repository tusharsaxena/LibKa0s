-- tests/fixture_diagnostics.lua — a throwaway host for the kit's shared diagnostics contract
-- (testkit/test_diagnostics_contract.lua), and the `Kit.diagnostics` facts it is run with.
--
-- This repo vendors its own kit, so the kit's contract case arrives here as it arrives in every
-- addon, and the suite inventory asks for it to be wired. A library has no slash command of its
-- own, so this is the smallest host that has one: a DebugLog console, a Slash dispatcher that is
-- gated on an enabled flag, a `debug` verb that routes through `DebugVerb` and falls back to the
-- window toggle, and a `diagnostics` verb. Running the contract against it proves the two majors
-- compose into what the rule asks of an addon: the report is live while disabled through Slash's
-- LIVE_VERBS alone, with no host-side live list.

return function(T)
  local state = { debug = false, disabled = false, chat = {} }
  local brand = "Ka0s Diag Host"
  local D, Sl

  local function reset()
    D = T.debuglog:New({
      name        = "DiagHost",
      title       = "Diag Host",
      brandName   = brand,
      font        = "Interface\\Fonts\\FRIZQT__.TTF",
      isEnabled   = function() return state.debug end,
      setEnabled  = function(on) state.debug = on end,
      print       = function(line) state.chat[#state.chat + 1] = line end,
      diagnostics = function()
        return { { "state", function(out) out:add("State", "disabled=%s", state.disabled) end } }
      end,
    })
    local commands = {
      { "help", "List available commands", function() Sl:PrintHelp() end },
      { "debug", "Debug console: on, off, diagnostics", function(rest)
        if not D:DebugVerb(rest) then D:Toggle() end
      end },
      { "diagnostics", "Write a diagnostics report to the debug console", function()
        D:RunDiagnostics()
      end },
    }
    Sl = T.slash:New({
      slash     = "/dh",
      commands  = commands,
      brandName = brand,
      isEnabled = function() return not state.disabled end,
      print     = function(line) state.chat[#state.chat + 1] = line end,
    })
  end
  reset()

  return {
    brand       = brand,
    dispatch    = function(line) Sl:OnSlash(line) end,
    console     = function() return D end,
    setDebug    = function(on) state.debug = on and true or false end,
    setDisabled = function(off) state.disabled = off and true or false end,
    reset       = reset,
  }
end
