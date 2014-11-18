-- Ursa Jungling + Roshan Script (BETA)!

-- We probably gonna need some libraries so let's get em

require("libs.Utils")
require("libs.ScriptConfig")

-- Script config, hotkeys, levelling etc
local config = ScriptConfig.new()
config:SetParameter("minHealth", 150)
config:SetParameter("Test", "L", config.TYPE_HOTKEY)
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
  if client.loading then return end
  if not PlayingGame() or client.paused then return end
  if not SleepCheck() then return end Sleep(200)
  
  if client.gameState == Client.STATE_PICK then
    client:ExecuteCmd("dota_select_hero npc_dota_hero_ursa")
    currentLevel = 0
    state = 1
    return
  end
  
  local me = entityList:GetMyHero()
  
  if PlayingGame and me.alive then
    if currentLevel == 0 then
      if me.team == LuaEntity.TEAM_DIRE then
        StartPos = Vector(-333, 4880, 496)
        SpawnPos = Vector(7050, 6380, 496)
      elseif me.team == LuaEntity.TEAM_RADIANT then
        StartPos = Vector(256, -2346, 496)
        SpawnPos = Vector(-7077,-6780,496)
      end
    end
    
    if currentLevel ~= me.level then
      local ability = me.abilities
      local prev = SelectUnit(me)
      entityList:GetMyPlayer():LearnAbility(me:GetAbility(levels[me.level]))
      SelectBack(prev)
    end
    
    if state == 1 then
      BuyStartingItems(me)
    end
  
    if state == 2 and me:FindItem("item_tango") and me:FindItem("item_flask") and me:FindItem("item_stout_shield") then
      if inStartPosition == false then
        me:Move(StartPos)
        inStartPosition == true
      end
      state = 3
    end
    
    -- TODO Start farming!!
    if me.health == me.maxHealth and inStartPosition == true and state == 3 then
      -- Start farming here
    end
    
  end
end


-- Just a Test
function Key(msg,code)
  if client.chat or client.console or client.loading then return end
  if IsKeyDown(config.Test) then
    local me = entityList:GetMyHero()
    client:ExecuteCmd("say state = "..state.." inPosition = "..(inPosition and 1 or 0).."TIME ="..client.gameTime)
    print("X="..client.mousePosition.x.."; Y="..client.mousePosition.y.."; Team="..me.team;"Hero Position="..me.position)
  end
end


script:RegisterEvent(EVENT_TICK,Tick)
script:RegisterEvent(EVENT_KEY,Key)
