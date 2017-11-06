local master_PlayerCarry_perform_jump = PlayerCarry._perform_jump
function PlayerCarry:_perform_jump(jump_vec)
	if not BLT_CarryStacker:IsModEnabled() then
		master_PlayerCarry_perform_jump(self, jump_vec)
		return
	end

	if not managers.player:has_category_upgrade("carry", "movement_penalty_nullifier") then
		mvector3.multiply(jump_vec, BLT_CarryStacker.weight)
	end

	PlayerCarry.super._perform_jump(self, jump_vec)
end

local master_PlayerCarry_get_max_walk_speed = PlayerCarry._get_max_walk_speed
function PlayerCarry:_get_max_walk_speed(...)
	if not BLT_CarryStacker:IsModEnabled() then
		return master_PlayerCarry_get_max_walk_speed(self, ...)
	end

	local penalty = BLT_CarryStacker.weight
	if managers.player:has_category_upgrade("carry", "movement_penalty_nullifier") then
		penalty = 1
	else
		penalty = math.clamp(penalty * managers.player:upgrade_value("carry", "movement_speed_multiplier", 1), 0, 1)
	end
	
	return PlayerCarry.super._get_max_walk_speed(self, ...) * penalty
end

local master_PlayerCarry_get_walk_headbob = PlayerCarry._get_walk_headbob
function PlayerCarry:_get_walk_headbob(...)
	if not BLT_CarryStacker:IsModEnabled() then
		return master_PlayerCarry_get_walk_headbob(self, ...)
	end

	return PlayerCarry.super._get_walk_headbob(self, ...) * BLT_CarryStacker.weight
end

local master_PlayerCarry_check_action_run = PlayerCarry._check_action_run
function PlayerCarry:_check_action_run(...)
	if not BLT_CarryStacker:IsModEnabled() then
		master_PlayerCarry_check_action_run(self, ...)
		return
	end

	if BLT_CarryStacker.weight >= 0.75 or managers.player:has_category_upgrade("carry", "movement_penalty_nullifier") then
		PlayerCarry.super._check_action_run(self, ...)
	end
end
