

//
// Console commands for TargetCache (in its own file to avoid duplicate registrations
//
function OnCommandTcOn(client)

    if client == nil or Shared.GetCheatsEnabled() or Shared.GetDevMode() then
        GetGamerules():GetTargetCache().enabled = true
        Shared.Message("target cache enabled")
    end
    
end

function OnCommandTcOff(client)

    if client == nil or Shared.GetCheatsEnabled() or Shared.GetDevMode() then
        GetGamerules():GetTargetCache().enabled = false
        // also mark the cache as invalid so we don't work on keeping it uptodate.
        GetGamerules():GetTargetCache().tlcSalVersion = -1
        Shared.Message("target cache disabled")
    end
    
end

function OnCommandTcLog(client, logs)

    if client == nil or Shared.GetCheatsEnabled() or Shared.GetDevMode() then
        if logs == nil then
            logs = ""
        end
        if logs == "all" then
            logs = TargetCache.kAllLogs
        end
        GetGamerules():GetTargetCache().logs = logs
        Shared.Message("target cache logging set to " .. logs)
    end
    
end

// just call it. With logging on, it should say if it needed to update any version
// this should not be necessary, all objects of interest should be announced via OnEntityChange()
function OnCommandTcCheck(client, logs)

    if client == nil or Shared.GetCheatsEnabled() or Shared.GetDevMode() then
        local tc = GetGamerules():GetTargetCache()
        local savedlogs = tc.logs
        tc.logs = TargetCache.kAllLogs
        Shared.Message("Checking target cache integrity")
        tc:_UpdateTargetListCaches()
    end
    
end


Event.Hook("Console_tcon",                  OnCommandTcOn)
Event.Hook("Console_tcoff",                 OnCommandTcOff)
Event.Hook("Console_tclog",                 OnCommandTcLog)
Event.Hook("Console_tccheck",               OnCommandTcCheck)

