ParaX 3D模型导出
===

ParaX 3D模型导出 是[paracraft](http://paracraft.cn/)的Mod插件。 目的是让用户可以
* 把[电影方块](https://github.com/LiXizhi/ParaCraft/wiki/item_MovieClip)中的角色保存为ParaX 3D模型
* ParaX 3D模型可导入到Paracraft世界的中作为3D人物模型使用

# 使用方法
* Ctrl + 左键 选择一个或多个[电影方块](https://github.com/LiXizhi/ParaCraft/wiki/item_MovieClip)以及方块之间的中继器以及红石线
![](https://cloud.githubusercontent.com/assets/5568155/26064580/fef2d6c4-39c3-11e7-8196-1c9794a56469.png) 

* 点击保存，并选择ParaX 动画模型导出
![](https://cloud.githubusercontent.com/assets/5568155/26064728/63696686-39c4-11e7-9947-c4d60f8d438b.png)
# This is a paracraft plugin (Mod)

## Usage

```lua
NPL.load("(gl)Mod/ParaXExporter/main.lua");
local ParaXExporter = commonlib.gettable("Mod.ParaXExporter");
ParaXExporter:ConvertFromBMaxToParaX("Mod/ParaXExporter/test/input.bmax", "temp/output.x");

-- export to ParaX with textures
ParaXExporter:ConvertFromBMaxToParaX("Mod/ParaXExporter/test/input.bmax", "temp/output.x", true);
-- or
ParaXExporter:Export("Mod/ParaXExporter/test/input.bmax", "temp/output.x", true);
```

Reference:
- [How To Create Paracraft Mod](https://github.com/LiXizhi/NPLRuntime/wiki/TutorialParacraftMod)
- [Download paracraft](http://www.paracraft.cn)



