OpenRA单人游戏中的任务模式是用lua脚本来描述情节的。下面通过第一个任务allies-01简单介绍一下。

地图文件的扩展名为 **.oramap** 他是文件夹的压缩包，不压缩也可以。比如OpenRA\mods\ra\maps\allies-01其中包含：
- map.bin  地图资源的二进制格式
- map.yaml  地图中角色坐标，其他规则说明。地图至少要包含上面这两个文件。
- rules.yaml  被map.yaml引用。定义了要用的脚本文件名等规则
- weapons.yaml  被map.yaml引用。
- allies01.lua 脚本文件


脚本调用的接口函数说明在 <https://docs.openra.net/en/latest/release/lua/>
|Global Tables |函数个数|
|--------------|----|
|Actor         |4   |
|Angle         |9   |
|Beacon        |1   |
|Camera        |1   |
|HSLColor      |39  |
|CPos          |2   |
|CVec          |2   |
|DateTime      |6   |
|Facing        |8   |
|Lighting      |5   |
|Map           |18  |
|Media         |10  |
|Player        |2   |
|Radar         |1   |
|Reinforcements|2   |
|Trigger       |34  |
|UserInterface |1   |
|Utils         |11  |
|WDist         |2   |
|WPos          |2   |
|WVec          |2   |
|Actor Properties / Commands |
|Ability       |6   |
|AmmoPool      |3   |
|Cloak         |1   |
|Combat        |8   |
|Experience    |6   |
|General       |32  |
|Movement      |12  |
|Power         |1   |
|Production    |5   |
|Support Powers|7   |
|Transports    |7   |
|Player Properties / Commands |
|Diplomacy     |1   |
|MissionObjectives|10|
|Player        |26  |
|Power         |4   |
|Production    |2   |
|Resources     |3   |

#### 主程序
``` lua
WorldLoaded = function()  -- 相当于 main
	player = Player.GetPlayer("Greece")  -- 用 表名.函数名 的方法调用接口函数
	england = Player.GetPlayer("England")
	ussr = Player.GetPlayer("USSR")
	--[[ Player.GetPlayer 返回游戏的一方。
	类似创建对象的感觉。
	本任务有三方：玩家主角希腊，平民英国和反派苏联。
	]]

	Trigger.OnObjectiveAdded(player, function(p, id)  -- 玩家增加目标时将目标内容显示出来
		Media.DisplayMessage(p.GetObjectiveDescription(id), "New " .. string.lower(p.GetObjectiveType(id)) .. " objective")
	end)
	Trigger.OnObjectiveCompleted(player, function(p, id)  -- 玩家完成目标时触发显示目标完成
		Media.DisplayMessage(p.GetObjectiveDescription(id), "Objective completed")
	end)
	Trigger.OnObjectiveFailed(player, function(p, id)  -- 玩家目标失败时触发显示失败
		Media.DisplayMessage(p.GetObjectiveDescription(id), "Objective failed")
	end)

	-- 玩家失败或者成功触发回调函数，播放成功或者失败的音效
	Trigger.OnPlayerLost(player, MissionFailed)
	Trigger.OnPlayerWon(player, MissionAccomplished)

	-- 给玩家增加任务目标
	FindEinsteinObjective = player.AddPrimaryObjective("Find Einstein.")
	TanyaSurviveObjective = player.AddPrimaryObjective("Tanya must survive.")
	EinsteinSurviveObjective = player.AddPrimaryObjective("Einstein must survive.")
	CivilProtectionObjective = player.AddSecondaryObjective("Protect all civilians.")

	-- 运行初始活动
	RunInitialActivities()

	-- 设置实验室被毁触发的回调函数
	Trigger.OnKilled(Lab, LabDestroyed)
	-- 设置油泵被毁触发的回调函数
	Trigger.OnKilled(OilPump, OilPumpDestroyed)

	-- 获取反派方所有的地面攻击单位
	sovietArmy = ussr.GetGroundAttackers()

	-- 设置防守实验室单位全部消灭的回调函数
	labGuardsTeam = { LabGuard1, LabGuard2, LabGuard3 }
	Trigger.OnAllKilled(labGuardsTeam, LabGuardsKilled)

	-- 设置平民相关的回调函数
	collateralDamage = false
	civilianTeam = { Civilian1, Civilian2 }
	Trigger.OnAnyKilled(civilianTeam, CiviliansKilled)
	Trigger.OnKilled(Civilian1, LostMate)

	SetUnitStances()

	-- 创建Camera-
	Trigger.AfterDelay(DateTime.Seconds(5), function() Actor.Create("camera", true, { Owner = player, Location = BaseCameraPoint.Location }) end)

	Camera.Position = InsertionLZ.CenterPosition
end
```

#### 保护平民的任务
```lua
	-- @fn WorldLoaded
	collateralDamage = false
	civilianTeam = { Civilian1, Civilian2 }
	Trigger.OnAnyKilled(civilianTeam, CiviliansKilled)  -- 任何一个平民被杀
	Trigger.OnKilled(Civilian1, LostMate)  -- 平民1被杀

CiviliansKilled = function()
	player.MarkFailedObjective(CivilProtectionObjective)  -- 标记目标失败
	Media.PlaySpeechNotification(player, "ObjectiveNotMet")  -- 播放任务失败语言
	collateralDamage = true
end

LostMate = function()
	if not Civilian2.IsDead then  -- 平民2没死的话
		Civilian2.Panic()  -- 它疯了
	end
end
```

#### 找到爱因斯坦的任务
```lua
	-- @fn WorldLoaded
	labGuardsTeam = { LabGuard1, LabGuard2, LabGuard3 }
	Trigger.OnAllKilled(labGuardsTeam, LabGuardsKilled)  -- 守卫被杀死

LabGuardsKilled = function()
	CreateEinstein()  -- 创建爱因斯坦并增加做直升机逃跑的任务

	Trigger.AfterDelay(DateTime.Seconds(2), function()  -- 2秒钟后
		Actor.Create(FlareType, true, { Owner = england, Location = ExtractionFlarePoint.Location })  -- 创建信号弹
		Media.PlaySpeechNotification(player, "SignalFlareNorth")
		SendExtractionHelicopter()  -- 派遣救援直升机
	end)

	Trigger.AfterDelay(DateTime.Seconds(10), function()  -- 10秒钟后
		Media.PlaySpeechNotification(player, "AlliedReinforcementsArrived")
		Actor.Create("camera", true, { Owner = player, Location = CruiserCameraPoint.Location })
		SendCruisers()  -- 派遣巡洋舰
	end)

	Trigger.AfterDelay(DateTime.Seconds(12), function()  -- 12秒钟后
		for i = 0, 2 do
			Trigger.AfterDelay(DateTime.Seconds(i), function()
				Media.PlaySoundNotification(player, "AlertBuzzer")
			end)
		end
		Utils.Do(sovietArmy, function(a)  -- 遍历反派所有的地面部队
			if not a.IsDead and a.HasProperty("Hunt") then -- 如果没有死并且有hunt属性
				Trigger.OnIdle(a, a.Hunt)  -- 如果空闲就触发hunt
			end
		end)
	end)
end

CreateEinstein = function()
	player.MarkCompletedObjective(FindEinsteinObjective)  -- 标记完成找到爱因斯坦任务
	Media.PlaySpeechNotification(player, "ObjectiveMet")
	einstein = Actor.Create(EinsteinType, true, { Location = EinsteinSpawnPoint.Location, Owner = player })  -- 创建爱因斯坦
	einstein.Scatter()  -- 爱因斯坦瞎跑出来
	Trigger.OnKilled(einstein, RescueFailed)  -- 爱因斯坦死了会触发失败
	ExtractObjective = player.AddPrimaryObjective("Wait for the helicopter and extract Einstein.")  -- 增加爱因斯坦做直升机逃跑的任务目标
	Trigger.AfterDelay(DateTime.Seconds(1), function() Media.PlaySpeechNotification(player, "TargetFreed") end)
end

SendExtractionHelicopter = function()
	heli = Reinforcements.ReinforceWithTransport(player, ExtractionHelicopterType, nil, ExtractionPath)[1]  -- 增援救援直升飞机
	if not einstein.IsDead then  -- 如果爱因斯坦没死
		Trigger.OnRemovedFromWorld(einstein, EvacuateHelicopter)  -- 爱因斯坦坐进飞机后，飞机撤退并销毁对象
	end
	Trigger.OnKilled(heli, RescueFailed)  -- 直升机被灭的话任务失败
	Trigger.OnRemovedFromWorld(heli, HelicopterGone)  -- 直升机成功撤退触发任务完成情况
end

EvacuateHelicopter = function()
	if heli.HasPassengers then
		heli.Move(ExtractionExitPoint.Location)
		heli.Destroy()
	end
end

HelicopterGone = function()
	if not heli.IsDead then
		Media.PlaySpeechNotification(player, "TargetRescued")
		Trigger.AfterDelay(DateTime.Seconds(1), function()
			player.MarkCompletedObjective(ExtractObjective)
			player.MarkCompletedObjective(EinsteinSurviveObjective)
			if not player.IsObjectiveFailed(TanyaSurviveObjective) then
				player.MarkCompletedObjective(TanyaSurviveObjective)
			end
			if not collateralDamage then
				player.MarkCompletedObjective(CivilProtectionObjective)
			end
		end)
	end
end

SendCruisers = function()
	local i = 1
	Utils.Do(CruisersReinforcements, function(cruiser)
		local ca = Actor.Create(cruiser, true, { Owner = england, Location = SouthReinforcementsPoint.Location + CVec.New(2 * i, 0) })
		ca.Move(Map.NamedActor("CruiserPoint" .. i).Location)
		i = i + 1
	end)
end
```

#### 其他触发事件
```lua
	-- @fn WorldLoaded
	Trigger.OnKilled(Lab, LabDestroyed)  -- 实验室被毁

LabDestroyed = function()
	if not einstein then  -- 没有爱因斯坦（他还没被创建出来）
		RescueFailed()
	end
end

RescueFailed = function()
	Media.PlaySpeechNotification(player, "ObjectiveNotMet") -- 播放任务失败语言
	player.MarkFailedObjective(EinsteinSurviveObjective)  -- 标记目标失败
end
```

```lua
	-- @fn WorldLoaded
	Trigger.OnKilled(OilPump, OilPumpDestroyed)  -- 油泵被毁

OilPumpDestroyed = function()
	Trigger.AfterDelay(DateTime.Seconds(5), SendJeeps)  -- 5秒后增援吉普车
end

SendJeeps = function()
	Reinforcements.Reinforce(player, JeepReinforcements, InsertionPath, DateTime.Seconds(2))  -- 增援两辆吉普
	Media.PlaySpeechNotification(player, "ReinforcementsArrived")  -- 播放援军到达
end
```
