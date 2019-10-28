NPL.load("(gl)Mod/ParaXExporter/BlockDirection.lua");
NPL.load("(gl)Mod/ParaXExporter/BMaxModel.lua");
NPL.load("(gl)Mod/ParaXExporter/Common.lua");



local Common = commonlib.gettable("Mod.ParaXExporter.Common");
local BMaxMovieBlockNode = commonlib.inherit(commonlib.gettable("Mod.ParaXExporter.BMaxNode") ,commonlib.gettable("Mod.ParaXExporter.BMaxMovieBlockNode"));

local BlockDirection = commonlib.gettable("Mod.ParaXExporter.BlockDirection");
local BMaxModel = commonlib.gettable("Mod.ParaXExporter.BMaxModel");

BMaxMovieBlockNode.DefaultSpeed = 4;

function BMaxMovieBlockNode:ctor()
	self.movieLength = 30;

	self.actor_table = nil;
	self.asset_file = nil;
	self.bone_table = nil;

	self.lastBlock = nil;
	self.nextBlock = -1;
	self.hasConnect = false;
	self.blockSignNode = nil;

	self.m_speeds = {};
	self.m_animTimes = {};
	self.m_animIds = {};
end

function BMaxMovieBlockNode:ConnectMovieBlock()
	if self.hasConnect then 
		return;
	end
	
	for i = 0, 5 do
		local nextSide = BlockDirection:GetBlockSide(i)
		local node = self:GetNeighbour(nextSide );
		if node then
			if node.template_id == BMaxModel.ReapeaterId and i == node.block_data then
				-- print("t", i, node.block_data, self.x, self.y, self.z, node.x, node.y, node.z);
				local side = BlockDirection:GetBlockSide(node.block_data);
				self:ConnectNode(node, side);
			elseif node.template_id == BMaxModel.BlockSignId then
				self.blockSignNode = node;
			end
		end
	end

	self.hasConnect = true;
end

function BMaxMovieBlockNode:ConnectNode(node, side)
	if not node then
		return nil;
	end

	for i = 0, 5 do
		local opSide = BlockDirection:GetOpSide(side);
		local nextSide = BlockDirection:GetBlockSide(i);
		
		local nextNode = node:GetNeighbour(nextSide);

		if nextNode and opSide ~= nextSide and BlockDirection:IsGroundSide(nextSide) then
			if nextNode.template_id == BMaxModel.MovieBlockId then
				-- print("side", nextSide, opSide, nextNode.x, nextNode.y, nextNode.z);
				nextNode.lastBlock = self:GetIndex();
				self.nextBlock = nextNode:GetIndex();
				nextNode:ConnectMovieBlock();
				return;
			elseif nextNode.template_id == BMaxModel.WiresId then
				self:ConnectNode(nextNode, nextSide);
			end
		end
	end
end

function BMaxMovieBlockNode:HasLastBlock()
	return self.lastBlock ~= nil;
end



function BMaxMovieBlockNode:ParseMovieInfo()
	local commandTable = commonlib.LoadTableFromString(self.block_content[1]);
	local command = commandTable[1];

	local time = tonumber(string.match(command, "/t%s+([%d%.]+)%s+/end$") or 1000) or 1000;
	self.movieLength = time * 1000;
end

function BMaxMovieBlockNode:ParseActor(name)
	local actors = self.block_content[2];

	for k, v in ipairs(actors) do
		local attr = v.attr;
		if attr ~= nil and attr.id == BMaxModel.ActorId then
			local actor_table = commonlib.LoadTableFromString(v[1])
			local asset_name = self:GetAssetName(actor_table);
			if asset_name then
				if not self:HasLastBlock() then
					self.actor_table = actor_table;
					self.asset_file = asset_name;
					self:ParseMovieDetail();
					break;
				else 
					if asset_name == name then
						self.actor_table = actor_table;
						self.asset_file = asset_name;
						self:ParseMovieDetail();
						break;
					end
				end 
			end
		end
	end
end

function BMaxMovieBlockNode:ParseMovieDetail()
	if self.actor_table then 
		local timeseries = self.actor_table.timeseries;
		if timeseries then
			self:ParseAnimId(timeseries);
			self:ParseSpeed(timeseries);
		end
	end

	
	return 0;
end

function BMaxMovieBlockNode:ParseSpeed(timeseries)
	local speedScaleTable = timeseries.speedscale or {};
	local speedData = speedScaleTable.data or {};
	if #speedData > 0 then
		for _, speed in ipairs(speedData) do
			table.insert(self.m_speeds, speed)
		end
	else 
		for _, animId in ipairs(self.m_animIds) do
			if animId == 4 or animId == 5 then
				table.insert(self.m_speeds, BMaxMovieBlockNode.DefaultSpeed);
				return;
			end
		end

		table.insert(self.m_speeds, 0);
	end		
end

function BMaxMovieBlockNode:ParseAnimId(timeseries)

	local signAnimId = self:GetSignAnimId();
	
	local animTable = timeseries.anim or {};
	local animData = animTable.data or {};
	local animTimeData = animTable.times or {};
	if #animData > 0 and #animTimeData > 0 then
		for _, animId in ipairs(animData) do
			table.insert(self.m_animIds, animId)
		end

		for _, animTime in ipairs(animTimeData) do
			table.insert(self.m_animTimes, animTime)
		end

	elseif signAnimId then
		table.insert(self.m_animIds, signAnimId);
		table.insert(self.m_animTimes, 0);
	else 
		table.insert(self.m_animIds, 0);
		table.insert(self.m_animTimes, 0);
	end

end

function BMaxMovieBlockNode:GetSignAnimId()
	if self.blockSignNode then
		local signTitle = self.blockSignNode:GetSignTitle();
		if signTitle then
			local animIdStr, name = string.match(signTitle[1], "(%d+) (%w+)$"); 
			local animId = tonumber(animId);
			if animId then
				return animId;
			end
		end
	end
end

function BMaxMovieBlockNode:GetAssetName(actor_table)
	if self.asset_file then
		return self.asset_file;
	end

	local timeseries = actor_table.timeseries;
	local asset_file = timeseries.assetfile;
	local file_name = asset_file and asset_file.data[1] or "";
	local name, extension = string.match(file_name, "(.+)%.(%w+)$");

	if (extension == "bmax") then
		return file_name;
	end

	return nil;
end

function BMaxMovieBlockNode:GetAnimData()
	if self.actor_table then 
		local timeseries = self.actor_table.timeseries;
		if timeseries then
			return timeseries.bones;
		end
	end
end
