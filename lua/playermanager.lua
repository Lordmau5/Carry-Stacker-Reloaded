local master_PlayerManager_set_carry = PlayerManager.set_carry
local master_PlayerManager_drop_carry = PlayerManager.drop_carry
local master_PlayerManager_can_carry = PlayerManager.can_carry

function PlayerManager:can_carry(carry_id)
	if not BLT_CarryStacker:IsModEnabled() then
		return master_PlayerManager_can_carry(self, carry_id)
	end
	return BLT_CarryStacker:CanCarry(carry_id)
end

function drop_and_set_carry(self, ...)
	local cdata = BLT_CarryStacker:RemoveCarry()

	if cdata then
		master_PlayerManager_drop_carry(self, ...)
		if #BLT_CarryStacker.stack > 0 then
			cdata = BLT_CarryStacker.stack[#BLT_CarryStacker.stack]
			master_PlayerManager_set_carry(self, cdata.carry_id, cdata.multiplier or 1, cdata.dye_initiated, cdata.has_dye_pack, cdata.dye_value_multiplier)
		end
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
	BLT_CarryStacker:AddCarry(self:get_my_carry_data())
	PlayerStandard:block_use_item()
end
