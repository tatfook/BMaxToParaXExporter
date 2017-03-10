local Common = commonlib.gettable("Mod.ParaXExporter.Common")
function Common:PrintTable(table)
	for i, v in pairs(table) do
		print (i, v);
	end
end