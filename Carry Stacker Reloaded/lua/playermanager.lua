local master_PlayerManager_set_carry = PlayerManager.set_carry
local master_PlayerManager_drop_carry = PlayerManager.drop_carry
local master_PlayerManager_can_carry = PlayerManager.can_carry
local master_PlayerManager_update = PlayerManager.update

function PlayerManager:refresh_stack_counter()
	managers.hud:remove_special_equipment("carrystacker")
	if #BLT_CarryStacker.stack > 0 then
		managers.hud:add_special_equipment({id = "carrystacker", icon = "pd2_loot", amount = #BLT_CarryStacker.stack})
	end
end

function PlayerManager:can_carry(carry_id)
	if not BLT_CarryStacker:IsModEnabled() then
		return master_PlayerManager_can_carry(self, carry_id)
	end
	return BLT_CarryStacker:CanCarry(carry_id)
end

function drop_and_set_carry(self, ...)
	if #BLT_CarryStacker.stack > 0 then
		local cdata = BLT_CarryStacker.stack[#BLT_CarryStacker.stack]
		BLT_CarryStacker.weight = BLT_CarryStacker.weight / BLT_CarryStacker:getWeightForType(cdata.carry_id)

		master_PlayerManager_drop_carry(self, ...)

		table.remove(BLT_CarryStacker.stack, #BLT_CarryStacker.stack)
		if #BLT_CarryStacker.stack > 0 then
			cdata = BLT_CarryStacker.stack[#BLT_CarryStacker.stack]
			master_PlayerManager_set_carry(self, cdata.carry_id, cdata.multiplier or 1, cdata.dye_initiated, cdata.has_dye_pack, cdata.dye_value_multiplier)
		else
			BLT_CarryStacker.weight = 1
		end
		self:refresh_stack_counter()
	end
end

function PlayerManager:drop_carry( ... )
	if not BLT_CarryStacker:IsModEnabled() then
		master_PlayerManager_drop_carry(self, ... )
		return
	end

	drop_and_set_carry(self, ...)
end

function PlayerManager:set_carry( ... )
	if not BLT_CarryStacker:IsModEnabled() then
		master_PlayerManager_set_carry(self, ... )
		return
	end

	master_PlayerManager_set_carry(self, ...)

	local cdata = self:get_my_carry_data()
	BLT_CarryStacker.weight = BLT_CarryStacker.weight * BLT_CarryStacker:getWeightForType(cdata.carry_id)
	table.insert(BLT_CarryStacker.stack, cdata)
	PlayerStandard:block_use_item()

	self:refresh_stack_counter()
end
