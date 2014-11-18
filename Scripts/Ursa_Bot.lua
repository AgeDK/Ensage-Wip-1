-- Ursa Jungling + Roshan Script (BETA)!

-- We probably gonna need some libraries so let's get em

require("libs.Utils")
require("libs.ScriptConfig")

-- Script config, hotkeys, levelling etc
local config = ScriptConfig.new()
config:SetParameter("minHealth", 150)
config:Load()
local currentLevel = 0
local state = 1
local inStartPosition = false
local levels = {3,2,3,2,1,4,1,1,1,2,2,3,3,4,5,4,5,5,5,5,5,5,5,5,5}
-- Buy a salve, tango and stout shield
local startingItems = {44, 182, 39}

startJunglingTime = 29

-- Check player is level one, then buy all the starting items we need to JUNGLLEEEEEE
function BuyStartingItems(player)
  level = player.level
  if level == 1 then 
    for i, item in ipairs(startingItems) do
      entityList:GetMyPlayer():BuyItem(item)
    end
  end
  state = 2
end

function Tick(tick)
  if not PlayingGame() then return end
  if not SleepCheck() then return end Sleep(200)
    if client.gameState = Client.STATE_PICK then
      client:ExecuteCmd("dota_select_hero npc_dota_hero_ursa")
      currentLevel = 0
      state = 1
      return
    end
    local me = entityList:GetMyHero()
    if PlayingGame and me.alive then
      if currentLevel = 0 then
        if me.team == LuaEntity.TEAM_DIRE then
          StartPos = Vector(-333, 4880, 496)
          SpawnPos = Vector(7050, 6380, 496)
        elseif me.team = LuaEntity.TEAM_RADIANT then
          StartPos = Vector(256, -2346, 496)
          SpawnPos = Vector(-7077,-6780,496)
        end
      end
    
    if currentLevel ~= me.level then
      local ability = me.abilities
      local prev = SelectUnit(me)
      entityList:GetMyPlayer():LearnAbility(me:GetAbilitylevels[me.level]))
      SelectBack(prev)
    end
  
    if me.health == me.maxHealth and inStartPosition == false and state >= 3 then
      me:Move(StartPos)
      inStartPosition = true
      Sleep(500)
      return
    end
  
    if state == 2 and me:FindItem("item_tango" and me:FindItem("item_flask") and me:FindItem("item_stout_shield") then
      if inStartPosition == false then
        me:Move(StartPos)
      end
      state = 3
    end
  end
end
