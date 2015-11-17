_G.BLT_CarryStacker = _G.BLT_CarryStacker or {}
BLT_CarryStacker._path = ModPath
BLT_CarryStacker._data_path = SavePath .. "carrystacker.txt"
BLT_CarryStacker.settings = {}

function BLT_CarryStacker:Load()
	self:ResetWeights()

	local file = io.open(self._data_path, "r")
	if file then

		-- Check for old config data. Going to be removed in R8+
		local foundMP = false
		for k, v in pairs(json.decode(file:read("*all"))) do
			self.settings[k] = v
			if k == "movement_penalties" then foundMP = true end
		end
		file:close()

		if not foundMP then
			os.remove(self._data_path)
			BLT_CarryStacker:ResetWeights()
		end
	end
end

function BLT_CarryStacker:Save()
	local file = io.open(self._data_path, "w+")
	if file then
		file:write(json.encode(self.settings))
		file:close()
	end
end

function BLT_CarryStacker:getMovementPenalties()
	return self.settings.movement_penalties
end

function BLT_CarryStacker:setMovementPenalty(carry_type, penalty)
	if not self.settings.movement_penalties[carry_type] then
		log("There is no \"" .. tostring(carry_type) .. "\" type.")
		return
	end
	self.movement_penalties_server[carry_type] = penalty
end

function BLT_CarryStacker:getCompleteTable()
	local tbl = {}
	for i, v in pairs(BLT_CarryStacker.settings.movement_penalties) do
		tbl[i] = v
	end
	tbl["toggle_host"] = BLT_CarryStacker.settings["toggle_host"]
	return tbl
end

function BLT_CarryStacker:ResetWeights()
	self.settings.movement_penalties = {
		["light"] = 10,
		["coke_light"] = 10,
		["medium"] = 20,
		["heavy"] = 30,
		["very_heavy"] = 40,
		["mega_heavy"] = 50,

		["being"] = 30,
		["slightly_very_heavy"] = 30
	}
	self.settings["toggle_host"] = true
	self.movement_penalties_server = {}
end

function BLT_CarryStacker:getWeightForType(carry_id)
	local carry_type = tweak_data.carry[carry_id].type
	if LuaNetworking:IsMultiplayer() and not LuaNetworking:IsHost() and BLT_CarryStacker:IsRemoteHostSyncEnabled() then
		return self.movement_penalties_server[carry_type] ~= nil and ((100 - self.movement_penalties_server[carry_type]) / 100) or 1
	end
	return self.settings.movement_penalties[carry_type] ~= nil and ((100 - self.settings.movement_penalties[carry_type]) / 100) or 1
end

function BLT_CarryStacker:IsModEnabled()
	if not LuaNetworking:IsMultiplayer() then return true end

	if LuaNetworking:IsHost() then return true end

	return BLT_CarryStacker.enabled
end

function BLT_CarryStacker:EnableMod()
	BLT_CarryStacker.enabled = true
end

function BLT_CarryStacker:DisableMod()
	BLT_CarryStacker.enabled = false
end

function BLT_CarryStacker:IsHostSyncEnabled()
	return BLT_CarryStacker.settings["toggle_host"]
end

function BLT_CarryStacker:SetRemoteHostSyncEnabled(state)
	BLT_CarryStacker.remote_host_sync = state
end

function BLT_CarryStacker:IsRemoteHostSyncEnabled()
	return BLT_CarryStacker.remote_host_sync
end 

function BLT_CarryStacker:SetHostSyncEnabled(state)
	BLT_CarryStacker.settings["toggle_host"] = state
end

Hooks:Add("LocalizationManagerPostInit", "LocalizationManagerPostInit_BLT_CarryStacker", function(loc)
	loc:load_localization_file(BLT_CarryStacker._path .. "loc/english.txt")
end)

function setBagPenalty(this, item)
	local _type = item:name():sub(7)

	BLT_CarryStacker.settings.movement_penalties[_type] = item:value()
	if _type == "light" then
		BLT_CarryStacker.settings.movement_penalties["coke_light"] = item:value()
	elseif _type == "heavy" then
		BLT_CarryStacker.settings.movement_penalties["being"] = item:value()
		BLT_CarryStacker.settings.movement_penalties["slightly_very_heavy"] = item:value()
	end
end

Hooks:Add("MenuManagerInitialize", "MenuManagerInitialize_BLT_CarryStacker", function(menu_manager)
	MenuCallbackHandler.BLT_CarryStacker_setBagPenalty = setBagPenalty	

	MenuCallbackHandler.BLT_CarryStacker_Reset = function(this, item)
		BLT_CarryStacker:ResetWeights()

		MenuHelper:ResetItemsToDefaultValue(item, {["bltcs_light"] = true}, BLT_CarryStacker.settings.movement_penalties["light"])
		MenuHelper:ResetItemsToDefaultValue(item, {["bltcs_medium"] = true}, BLT_CarryStacker.settings.movement_penalties["medium"])
		MenuHelper:ResetItemsToDefaultValue(item, {["bltcs_heavy"] = true}, BLT_CarryStacker.settings.movement_penalties["heavy"])
		MenuHelper:ResetItemsToDefaultValue(item, {["bltcs_very_heavy"] = true}, BLT_CarryStacker.settings.movement_penalties["very_heavy"])
		MenuHelper:ResetItemsToDefaultValue(item, {["bltcs_mega_heavy"] = true}, BLT_CarryStacker.settings.movement_penalties["mega_heavy"])
	end

	MenuCallbackHandler.BLT_CarryStacker_Open_Options = function(this, is_opening)
		if not is_opening then return end

		if LuaNetworking:IsMultiplayer() and not LuaNetworking:IsHost() and BLT_CarryStacker:IsRemoteHostSyncEnabled() then
			local title = "Carry Stacker - Client"
			local message = "You are currently playing as a client.\nThe Carry Stacker settings are being synced from the host.\nChanges you make in here do not apply for the current heist."
			local options = {
				[1] = {
					text = "Okay",
					is_cancel_button = true
				}
			}
			QuickMenu:new(title, message, options, true)
		end
	end

	MenuCallbackHandler.BLT_CarryStacker_Close_Options = function(this)
		BLT_CarryStacker:Save()

		if BLT_CarryStacker:IsHostSyncEnabled() and LuaNetworking:IsMultiplayer() and LuaNetworking:IsHost() then
			BLT_CarryStacker:syncConfigToAll()
		end
	end

	MenuCallbackHandler.BLT_CarryStacker_toggleHostSync = function(this, item)
		BLT_CarryStacker:SetHostSyncEnabled((item:value() == "on" and true or false))

		if BLT_CarryStacker:IsHostSyncEnabled() and LuaNetworking:IsMultiplayer() and LuaNetworking:IsHost() then
			LuaNetworking:SendToPeers("BLT_CarryStacker_AllowMod", BLT_CarryStacker:IsHostSyncEnabled())
			BLT_CarryStacker:syncConfigToAll()
		end
	end

	MenuCallbackHandler.BLT_CarryStacker_Help = function(this, item)
		local title = "Carry Stacker Help"
		local message = "Carry Stacker has been rewritten almost entirely from scratch.\n\nWhy, you ask?\nWell, let's just say I didn't like the implementation of it before.\n\n" ..

				"This new version now allows you to carry every type of bag at once.\n" ..
				"As well, it now features movement penalty!\nThat's right, no more super-OP on this one.\n\n" ..

				"The system has a bit of math behind it. Think about your full movement speed as 100/100.\n" ..
				"Now, you have a \"Light\" Bag that applies 10% penalty to that. This makes it 90/100, since 10% of the 100 is 10.\n" ..
				"If you pick up another \"Light\" Bag, it will apply another 10%. This time, to the 90, which makes it 81/100.\n\n" ..

				"The higher the penalty (Slider in percentage), the lesser the amount of bags you can carry.\n" ..
				"The default values, for example, allow for a mix of 3 \"Light\" and 3 \"Heavy\" Bags.\n" ..
				"If your movement speed reaches 25/100, you can't pick up any more bags.\n" ..

				"__________________________________\n" ..

				"The sliders are for the different types of bags.\n\n" ..
				"Light:\nJewelry, Painting, Coke, Meth, Evidence\n\n" ..
				"Medium:\nMoney, Ammo, Samurai Armor, Equipment Bag, Artifact (Light)\n\n" ..
				"Heavy:\nGold, Person, Weapon, Circuit, Turret, Safe\n\n" ..
				"Very Heavy:\nArtifact (Heavy)\n\n" ..
				"Mega Heavy:\nEngine"
		local options = {
			[1] = {
				text = "Okay",
				is_cancel_button = true
			}
		}
		QuickMenu:new(title, message, options, true)
	end

	BLT_CarryStacker:Load()
	MenuHelper:LoadFromJsonFile(BLT_CarryStacker._path .. "menu/options.txt", BLT_CarryStacker, BLT_CarryStacker:getCompleteTable())
end)
