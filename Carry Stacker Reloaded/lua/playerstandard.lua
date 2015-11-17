local btn_use_item_held = false

local master_PlayerStandard_update = PlayerStandard.update
function PlayerStandard:update(t, dt)
	master_PlayerStandard_update(self, t, dt)

	if self ~= nil then
		if self._get_input ~= nil then
			btn_use_item_held = self._controller:get_input_bool("use_item")
		end
	end
end

function PlayerStandard:use_item_held()
	return btn_use_item_held
end
