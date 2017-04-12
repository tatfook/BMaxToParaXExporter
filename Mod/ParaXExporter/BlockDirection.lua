local BlockDirection = commonlib.gettable("Mod.ParaXExporter.BlockDirection");

BlockDirection.left = 0;
BlockDirection.right = 1;
BlockDirection.front = 2;
BlockDirection.back = 3;
BlockDirection.top = 4;
BlockDirection.bottom = 5;
BlockDirection.none = 6;

BlockDirection.s_oppositeDirection = {BlockDirection.right, BlockDirection.left, BlockDirection.back, BlockDirection.front, BlockDirection.bottom, BlockDirection.top, BlockDirection.none};

function BlockDirection:GetBlockSide(v)
	if v == 1 then
		return BlockDirection.left;
	elseif v == 0 then
		return BlockDirection.right;
	elseif v == 3 then
		return BlockDirection.front;
	elseif v == 2 then
		return BlockDirection.back;
	elseif v == 5 then
		return BlockDirection.top;
	elseif v == 4 then
		return BlockDirection.bottom;
	end

	return BlockDirection.none;
end

function BlockDirection:GetOffsetBySide(side)
	local dx = 0;
	local dy = 0;
	local dz = 0;

	if side == BlockDirection.left then
		dx = 1;
	elseif side == BlockDirection.right then
		dx = -1;
	elseif side == BlockDirection.front then
		dz = 1;
	elseif side == BlockDirection.back then
		dz = -1;
	elseif side == BlockDirection.top then
		dy = 1;
	elseif side == BlockDirection.bottom then
		dy = -1;
	end

	return {x = dx, y = dy, z = dz};

end

function BlockDirection:GetOpSide(side)
	return BlockDirection.s_oppositeDirection[side + 1];
end

function BlockDirection:IsGroundSide(side)
	return side ~= BlockDirection.top and side ~= BlockDirection.bottom;
end