NPL.load("(gl)Mod/ParaXExporter/BlockDirection.lua");
NPL.load("(gl)Mod/ParaXExporter/BMaxModel.lua");

local BMaxMovieBlockNode = commonlib.inherit(commonlib.gettable("Mod.ParaXExporter.BMaxNode") ,commonlib.gettable("Mod.ParaXExporter.BMaxMovieBlockNode"));

local BlockDirection = commonlib.gettable("Mod.ParaXExporter.BlockDirection");
local BMaxModel = commonlib.gettable("Mod.ParaXExporter.BMaxModel");

function BMaxMovieBlockNode:ctor()
	self.animId = 4;
	self.movieLength = 30;

	self.actor_table = nil;
	self.asset_file = nil;
	self.bone_table = nil;

	self.lastBlock = nil;
	self.nextBlock = -1;
	self.hasConnect = false;
end

function BMaxMovieBlockNode:ConnectMovieBlock()
	if self.hasConnect then 
		return;
	end
	
	for i = 0, 5 do
		local node = self:GetNeighbour(i);
		if node then
			if node.template_id == BMaxModel.ReapeaterId then
				local side = BlockDirection:GetBlockSide(node.block_data)
				self:ConnectNode(node, side);
			elseif node.template_id == BMaxModel.BlockSignId then
				self:ParseAnimId(node)
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

function BMaxMovieBlockNode:ParseAnimId(blockSign)
	local signTitle = blockSign:GetSignTitle();
	if signTitle then
		local animId, name = string.match(signTitle, "(%d+) (%w+)$"); 
		self.animId = tonumber(animId);
	end
	
end

function BMaxMovieBlockNode:ParseMovieInfo()
	local commandTable = commonlib.LoadTableFromString(self.block_content[1]);
	local command = commandTable[1];

	local time = string.match(command, "/t (%d+) /end$");
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
					break;
				else 
					if asset_name == name then
						self.actor_table = actor_table;
						self.asset_file = asset_name;
						break;
					end
				end 
			end
		end
	end
end

function BMaxMovieBlockNode:ParseMoveSpeed()
	if self.actor_table then 
		local timeseries = self.actor_table.timeseries;
		if timeseries then
			local speedScaleTable = timeseries.speedscale;
			local speed = speedScaleTable.data;
			return speed[1];
		end
	end

	return 0;
end

function BMaxMovieBlockNode:GetAssetName(actor_table)
	if self.asset_file then
		return self.asset_file;
	end

	local timeseries = actor_table.timeseries;
	local asset_file = timeseries.assetfile;
	local file_name = asset_file.data[1];
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
