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

- 也可以不使用中继器，直接将多个电影方块连接起来，每个电影方块对应一个动作编号。
- 可以给每个电影方块添加动作编号例如0代表待机，4是走路，5是跑步
   - 也可以通过告示牌上的数字给电影方块添加动作，如果角色属性中已经包含了动作编号（推荐），将自动忽略相连的告示牌上的编号。告示牌的格式为%d+ %w+, 例如：
      - 0 待机
      - 4 走路
   - 支持在一个电影方块中指定多个动作编号和速度（不推荐，有BUG）。
- 走路和跑步有默认速度，也可以在speedscale速度中指定速度。
- 【重要】每个电影方块的第0帧的所有会做动画的骨骼都要有关键帧。 如果某个骨骼在0号没有K帧，而4号K帧了，可能导致0号动画错乱（使用了4号的动画）。

# This is a paracraft plugin (Mod)

## Usage

```lua
NPL.load("(gl)Mod/ParaXExporter/main.lua");
local ParaXExporter = commonlib.gettable("Mod.ParaXExporter");
ParaXExporter:ConvertFromBMaxToParaX("Mod/ParaXExporter/test/input.bmax", "temp/output.x");

-- export to ParaX with textures
ParaXExporter:ConvertFromBMaxToParaX("Mod/ParaXExporter/test/input.bmax", "temp/output.x", true, true);
-- or
ParaXExporter:Export("Mod/ParaXExporter/test/input.bmax", "temp/output.x", true, true);
```

Reference:
- [How To Create Paracraft Mod](https://github.com/LiXizhi/NPLRuntime/wiki/TutorialParacraftMod)
- [Download paracraft](http://www.paracraft.cn)



