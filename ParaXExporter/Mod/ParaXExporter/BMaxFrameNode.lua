NPL.load("(gl)Mod/ParaXExporter/Bone.lua");
NPL.load("(gl)Mod/ParaXExporter/BlockConfig.lua");

local Bone = commonlib.gettable("Mod.ParaXExporter.Bone");
local BlockConfig = commonlib.gettable("Mod.ParaXExporter.BlockConfig");

NPL.load("(gl)Mod/ParaXExporter/BlockConfig.lua");

local BlockConfig = commonlib.gettable("Mod.ParaXExporter.BlockConfig");

local BMaxFrameNode = commonlib.inherit(commonlib.gettable("Mod.ParaXExporter.BMaxNode"), commonlib.gettable("Mod.ParaXExporter.BMaxFrameNode"));

function BMaxFrameNode:ctor()
	self.m_nParentIndex = 0;
end

function BMaxFrameNode:init(parser, x, y, z, template_id, block_data, bone_index)
	self.parser = parser;
	self.x = x;
	self.y = y;
	self.z = z;
	self.template_id = template_id;
	self.block_data = block_data;
	self.bone_index= bone_index;
	self.bone = Bone:new();

	return self;
end
	
function BMaxFrameNode:GetBone()
	return self.bone;
end


-- to do
function BMaxFrameNode:UpdatePivot()
	local pivot = {self.parser.m_centerPos.x + BlockConfig.g_blockSize * 0.5, self.y + BlockConfig.g_blockSize * 0.5, self.z - self.parser.m_centerPos.z + BlockConfig.g_blockSize * 0.5};
	--pivot = pivot * 3;
end

function BMaxFrameNode:GetParent()
	if (m_nParentIndex >= 0) then
		local pParent = self.m_nodes[m_nParentIndex];
		if pParent ~= nil then
			return pParent;
		end
	end
	return nil;
end

function BMaxFrameNode:GetParentBone(bRefresh)
	if bRefresh then
		
	end
end

function BMaxFrameNode:SetParentIndex(index)
	m_nParentIndex = index;
	local pParent = GetParent();
	if pParent ~= nil then
		
	end
end


--[[void ParaEngine::BMaxFrameNode::SetParentIndex(int32 val)
{
	m_nParentIndex = val;
	auto pParent = GetParent();
	if (pParent)
	{
		pParent->AddChild(this);
		m_pBone->parent = pParent->GetBoneIndex();
	}
	else
		m_pBone->parent = -1;
}--]]

--[[ParaEngine::Bone* BMaxFrameNode::GetParentBone(bool bRefresh)
{
	if (bRefresh)
	{
		SetParentIndex(-1);
		int cx = x;
		int cy = y;
		int cz = z;
		BlockDirection::Side side = BlockDirection::GetBlockSide(block_data);
		Int32x3 offset = BlockDirection::GetOffsetBySide(side);
		int dx = offset.x;
		int dy = offset.y;
		int dz = offset.z;
		int maxBoneLength = BMaxParser::MaxBoneLengthHorizontal;
		if (dy != 0){
			maxBoneLength = BMaxParser::MaxBoneLengthVertical;
		}
		for (int i = 1; i <= maxBoneLength; i++)
		{
			int x = cx + dx*i;
			int y = cy + dy*i;
			int z = cz + dz*i;
			BMaxFrameNode* parent_node = m_pParser->GetFrameNode(x, y, z);
			if (parent_node)
			{
				BlockDirection::Side parentSide = BlockDirection::GetBlockSide(parent_node->block_data);
				BlockDirection::Side opSide = BlockDirection::GetOpSide(parentSide);
				if (opSide != side || (dx + dy + dz) < 0)
				{
					// prevent acyclic links
					if (!IsAncestorOf(parent_node))
					{
						SetParentIndex(parent_node->GetIndex());
					}
				}
				break;
			}
		}
	}
	auto pParent = GetParent();
	return (pParent) ? pParent->GetBone() : NULL;
}--]]