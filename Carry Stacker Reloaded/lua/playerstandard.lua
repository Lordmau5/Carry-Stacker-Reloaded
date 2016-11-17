local btn_use_item_held = false
local block_use_item_from
local master_PlayerStandard_check_use_item = PlayerStandard._check_use_item

local master_PlayerStandard_update = PlayerStandard.update
function PlayerStandard:update(t, dt)
	master_PlayerStandard_update(self, t, dt)

	if self ~= nil then
		if self._get_input ~= nil then
			btn_use_item_held = self._controller:get_input_bool("use_item")
		end
	end
end

function PlayerStandard:_check_use_item(t, input)
	if block_use_item_from ~= nil then
		if TimerManager:game():time() - block_use_item_from < 0.1 then
			return false
		end
	end
	return master_PlayerStandard_check_use_item(self, t, input)
end

function PlayerStandard:use_item_held()
	return btn_use_item_held
end

function PlayerStandard:block_use_item()
	block_use_item_from = TimerManager:game():time()
end
