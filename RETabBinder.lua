local addonName = ...
local _G = _G
local print, pairs = print, pairs
local string = string
local InCombatLockdown = InCombatLockdown
local IsInInstance = IsInInstance
local GetCurrentBindingSet = GetCurrentBindingSet
local GetZonePVPInfo = GetZonePVPInfo
local GetBindingKey = GetBindingKey
local GetBindingAction = GetBindingAction
local SetBinding = SetBinding
local SaveBindings = SaveBindings
local UnitName = UnitName

local RETabBinderFrame = CreateFrame("Frame", nil, UIParent)

local DBdefaults = {
	factionrealm = {
		[UnitName("player")] = {
			DefaultKey = false,
			OpenWorld = false,
			SilentMode = false,
		}
	}
}

local Fail = false

local function eventHandler(self, event, ...)
	if event == "ADDON_LOADED" and ... == addonName then
		RETabBinderFrame.db = RETabBinderFrame.db or LibStub("AceDB-3.0"):New("RETabBinderDB", DBdefaults, nil)
		self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
		self:RegisterEvent("PLAYER_REGEN_ENABLED")
		self:RegisterEvent("DUEL_REQUESTED")
		self:RegisterEvent("DUEL_FINISHED")
		self:RegisterEvent("CHAT_MSG_SYSTEM")
		self:RegisterEvent("PLAYER_ENTERING_WORLD")
	elseif event == "ZONE_CHANGED_NEW_AREA" or (event == "PLAYER_REGEN_ENABLED" and Fail == true) or event == "DUEL_REQUESTED" or event == "DUEL_FINISHED" or event == "CHAT_MSG_SYSTEM" then

		local settings = RETabBinderFrame.db.factionrealm[UnitName("player")]

		if event == "CHAT_MSG_SYSTEM" then
			local msg = ...
			if msg == _G.ERR_DUEL_REQUESTED then
				event = "DUEL_REQUESTED"
			else
				return
			end
		end

		if InCombatLockdown() then
			Fail = true
			return
		end

		local BindSet = GetCurrentBindingSet()

		local TargetKey = GetBindingKey("TARGETNEARESTENEMYPLAYER")
		if TargetKey == nil then
			TargetKey = GetBindingKey("TARGETNEARESTENEMY")
		end
		if TargetKey == nil and settings.DefaultKey == true then
			TargetKey = "TAB"
		end

		local LastTargetKey = GetBindingKey("TARGETPREVIOUSENEMYPLAYER")
		if LastTargetKey == nil then
			LastTargetKey = GetBindingKey("TARGETPREVIOUSENEMY")
		end
		if LastTargetKey == nil and settings.DefaultKey == true then
			LastTargetKey = "SHIFT-TAB"
		end

		local CurrentBind
		if TargetKey then
			CurrentBind = GetBindingAction(TargetKey)
		end

		local PVPType, isFFa = GetZonePVPInfo()
		local _, ZoneType = IsInInstance()

		if ZoneType == "arena" or ZoneType == "pvp" or settings.OpenWorld == true or PVPType == "combat" or isFFa or event == "DUEL_REQUESTED" then
			if CurrentBind ~= "TARGETNEARESTENEMYPLAYER" then
				local Success
				if GetBindingKey("TARGETNEARESTENEMY") == TargetKey then
					SetBinding(TargetKey, "TARGETNEARESTENEMYPLAYER")
					SetBinding(LastTargetKey, "TARGETPREVIOUSENEMYPLAYER")
					Success = true
				end
				if Success == true then
					SaveBindings(BindSet)
					Fail = false
					if settings.SilentMode == false then
						print("\124cFF74D06C[RETabBinder]\124r PVP Mode enabled")
					end
				else
					Fail = true
				end
			elseif CurrentBind == "TARGETNEARESTENEMYPLAYER" then
				Fail = false
				if settings.SilentMode == false then
					print("\124cFF74D06C[RETabBinder]\124r PVP Mode enabled")
				end
			end
		else
			if CurrentBind ~= "TARGETNEARESTENEMY" then
				local Success
				if GetBindingKey("TARGETNEARESTENEMYPLAYER") == TargetKey then
					SetBinding(TargetKey, "TARGETNEARESTENEMY")
					SetBinding(LastTargetKey, "TARGETPREVIOUSENEMY")
					Success = true
				end
				if Success == true then
					SaveBindings(BindSet)
					Fail = false
					if settings.SilentMode == false then
						print("\124cFF74D06C[RETabBinder]\124r PVE Mode enabled")
					end
				else
					Fail = true
				end
			elseif CurrentBind == "TARGETNEARESTENEMY" then
				Fail = false
				if settings.SilentMode == false then
					print("\124cFF74D06C[RETabBinder]\124r PVE Mode enabled")
				end
			end
		end
	end
end

RETabBinderFrame:RegisterEvent("ADDON_LOADED")
RETabBinderFrame:SetScript("OnEvent", eventHandler)
RETabBinderFrame:Hide()

local function RETabBinderSlashCMD(msg)
	local _, _, cmd, args = string.find(msg, "%s?(%w+)%s?(.*)")
	local settings = RETabBinderFrame.db.factionrealm[UnitName("player")]
	local colorRed = _G.RED_FONT_COLOR_CODE
	local colorGreen = _G.GREEN_FONT_COLOR_CODE
	local colorEnd = _G.FONT_COLOR_CODE_CLOSE
	if cmd == "toggle" and args == "defaultKey" then
		settings.DefaultKey = not settings.DefaultKey
		print(colorRed.."Default Key"..colorEnd.." mode is now"..colorGreen,settings.DefaultKey,colorEnd)
	elseif cmd == "toggle" and args == "openWorld" then
		settings.OpenWorld = not settings.OpenWorld
		print(colorRed.."Open World"..colorEnd.." mode is now"..colorGreen,settings.OpenWorld,colorEnd)
	elseif cmd == "toggle" and args == "silentMode" then
		settings.SilentMode = not settings.SilentMode
		print(colorRed.."Silent Mode"..colorEnd.." is now"..colorGreen,settings.SilentMode,colorEnd)
	elseif cmd == "help" and args == "" then
		for setting, value in pairs(settings) do 
			print(colorRed,setting,colorEnd,"is",colorGreen,value,colorEnd) 
		end
		print(colorRed.."Syntax:"..colorEnd.."\n/rtb toggle "..colorRed.."defaultKey"..colorEnd.."\nToggles Default Key mode"..colorGreen.." - Set to "..colorEnd..colorRed.."true"..colorEnd..colorGreen.." if you are using the default action for the TAB button else leave at "..colorEnd..colorRed.."false"..colorEnd..".\n/rtb toggle "..colorRed.."openWorld"..colorEnd.."\nToggles Open World mode"..colorGreen.." - Set to "..colorEnd..colorRed.."true"..colorEnd..colorGreen.." if you want to leave PVP mode on while in the open world"..colorEnd.."\n/rtb toggle "..colorRed.."silentMode"..colorEnd.."\nToggle Silent Mode"..colorGreen.." - Dont print PVP/PVE mode status"..colorEnd)
	else 
		print("Type '/rtb "..colorGreen.."help"..colorEnd.."' for a list of commands")
	end
end

SLASH_RETABBINDER1 = "/retabbinder"
SLASH_RETABBINDER2 = "/rtb"
SlashCmdList["RETABBINDER"] = RETabBinderSlashCMD
