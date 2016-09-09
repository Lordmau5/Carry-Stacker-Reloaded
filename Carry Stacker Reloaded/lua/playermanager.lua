local master_PlayerManager_set_carry = PlayerManager.set_carry
local master_PlayerManager_drop_carry = PlayerManager.drop_carry
local master_PlayerManager_can_carry = PlayerManager.can_carry
local master_PlayerManager_update = PlayerManager.update

local table = table
local managers = managers

local stack_table = {}
local weight = 1

function PlayerManager:refresh_stack_counter()
	managers.hud:remove_special_equipment("carrystacker")
	if #stack_table > 0 then
		managers.hud:add_special_equipment({id = "carrystacker", icon = "pd2_loot", amount = #stack_table})
	end
end

function PlayerManager:can_carry(carry_id)
	if not BLT_CarryStacker:IsModEnabled() then
		return master_PlayerManager_can_carry(self, carry_id)
	end

  local check_weight = PlayerManager:BLTCS_getCurrentWeight() * BLT_CarryStacker:getWeightForType(carry_id)
  if check_weight < 0.25 then
      return false
  end

	return true
end

local drop_all_carry_args = nil

function resetVars()
	weight = 1
  drop_all_carry_args = nil
  nextUpdate = nil
end

local lastUpdate, nextUpdate
function PlayerManager:update(t, dt)
	master_PlayerManager_update(self, t, dt)

	if nextUpdate == nil or t < nextUpdate then
		return
	end

	if PlayerStandard == nil or PlayerStandard.use_item_held == nil then return end

	if PlayerStandard:use_item_held() then
		drop_and_set_carry(self, drop_all_carry_args)
	end
end

function drop_and_set_carry(self, ...)
	lastUpdate = TimerManager:game():time()

	drop_all_carry_args = ...

	if #stack_table > 0 then
		if stack_table[#stack_table] ~= nil then
      local cdata = stack_table[#stack_table]
      weight = weight / BLT_CarryStacker:getWeightForType(cdata.carry_id)

      master_PlayerManager_drop_carry(self, ...)

			table.remove(stack_table, #stack_table)
	    if #stack_table > 0 then
        cdata = stack_table[#stack_table]
        master_PlayerManager_set_carry(self, cdata.carry_id, cdata.multiplier or 100, cdata.dye_initiated, cdata.has_dye_pack, cdata.dye_value_multiplier)

        nextUpdate = lastUpdate + 0.1
	    else
        weight = 1
        resetVars()
	    end

	    self:refresh_stack_counter()
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

  local cdata = self:get_my_carry_data()
  weight = weight * BLT_CarryStacker:getWeightForType(cdata.carry_id)
	table.insert(stack_table, cdata)

	self:refresh_stack_counter()
end

function PlayerManager:BLTCS_getCurrentWeight()
  return weight
end
