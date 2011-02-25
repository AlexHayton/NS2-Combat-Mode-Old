// This module used to check the version of Combat Mode vs. NS2.
kCombatModeVersion = 165

function CombatMode_VersionCheck()
	if (Shared.GetBuildNumber() ~= kCombatModeVersion) then
		MainMenu_SetAlertMessage("Wrong version of NS2 for this version of Combat\nThis is build " .. tostring(Shared.GetBuildNumber()) .. ", I was expecting build " .. tostring(kCombatModeVersion) .. "!\nPlease look on the NS2 forums for an updated version of Combat Mode!")
	end
end