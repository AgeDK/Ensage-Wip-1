-- Ursa (currently only dire) Jungling + Roshan Script (BETA)!

-- ===================
-- == Features V1.0 ==
-- ===================
-- Works only on dire, jungles blindly with nothing smart
-- Buys morbid mask and smoke then goes to kill Roshan.
-- Will use tango if you're on half health. Always use tango while killing first camp
-- Will salve when you're at (maxHealth-salve healing)
-- Takes you to and kills Roshan when you're level 4 and max health/mana with stout shield, smoke and morbid mask

-- =======================
-- == Upcoming features ==
-- =======================
-- Smart jungling - will prioritize high xp low damage camps at the start for fast level 4
-- Stand in clever spots so that only one creep attacks us at a time
-- Ursa wombo combo! Overpower, blink, earthshock, phase boots CHASE AND KILL
-- Support for diffusal blade - are they getting away? DIFFU! Do they have a buff we don't want them to have? (Ghost scepter, omniknight etc) DIFFU! By the way, if you don't buy diffu on ursa you suck
-- Auto phase if they're faster than you
-- Auto earthshock if enemy hero in range
-- Did we die with aegis? Are we alone, has our team abandoned us?! Let's blink the fuck away.
-- Check rune before we kill Roshan - a DD would be very useful!

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

-- Salve, tango and stout shield
local startingItems = {44, 182, 39}

-- Camp locations, Hard, Med, Rune, Easy, Lane
campLocationDire = {Vector(1224, 3593, 496), Vector(391, 3772, 496), Vector(-1441, 2708, 496), Vector(-4286, 3618, 496), Vector(-3043, 4643, 496)}

-- Config for finding a camp
target = nil
foundCamp = false
waitForSpawn = false

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

-- We want to find the jungle creep with the most health. Get that prick out the way first.
function FindCreepTarget()
  local lowenemy = nil
  local enemies = entityList:GetEntities({classId=CDOTA_BaseNPC_Creep_Neutral,alive=true,visible=true})
  for i,v in ipairs(enemies) do
    if v.spawned then
      if lowenemy == nil then
        lowenemy = v
      elseif (lowenemy.maxHealth) < (v.maxHealth) then
        lowenemy = v
      end
    end
  end
  target = lowenemy
end

function FindCampTarget()
  me:Move(campLocationDire[2])
  FindCreepTarget()
  
  if target == nil then
    me:Move(campLocationDire[3])
    FindCreepTarget()
    
    if target == nil and me.level >= 2 then
      me:Move(campLocationDire[1])
      FindCreepTarget()
      
    elseif target == nil and me.level <= 2 then
      me:Move(campLocationDire[4])
      FindCreepTarget()
      
      if target == nil then
        me:Move(campLocationDire[5])
        FindCreepTarget()
        
        if target == nil then
          me:Move(StartPos)
          waitForSpawn = true
        end
      end
    end
  else
    foundCamp = true
  end
end

        
function DeliverByCourier()
  local me = entityList:GetMyHero()
  local cour = entityList:FindEntities({classId = CDOTA_Unit_Courier,team = me.team,alive = true})[1]
  if cour then
    client:ExecuteCmd("dota_courier_deliver")
    if cour.flying and cour.alive then
      client:ExecuteCmd("dota_courier_burst")  
    end
  end
end

function Tick(tick)
  
  -- Check we're actually in a game and it's not paused and we're not waiting for something
  if client.loading then return end
  if not PlayingGame() or client.paused then return end
  if not SleepCheck() then return end Sleep(200)
  
  -- Pick Ursa!
  if client.gameState == Client.STATE_PICK then
    client:ExecuteCmd("dota_select_hero npc_dota_hero_ursa")
    currentLevel = 0
    state = 1
    return
  end
  
  -- Get our hero so we can access the attributes.
  local me = entityList:GetMyHero()
  
  -- Check we're playing, we're spawned in and find out which team we're on.
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
    
    -- Auto level up based on my skill build. Feel free to change this but it is a great build. Levels are at the top. 1, 2, 3 or 4 for each of ursa's skills. 5 for stats.
    if currentLevel ~= me.level then
      local ability = me.abilities
      local prev = SelectUnit(me)
      entityList:GetMyPlayer():LearnAbility(me:GetAbility(levels[me.level]))
      SelectBack(prev)
    end
    
    -- If we've picked Ursa and spawned in, buy our starting items
    if state == 1 then
      BuyStartingItems(me)
    end
  
    -- If we have our starting items in our inventory then let's go to the jungle.
    if state == 2 and me:FindItem("item_tango") and me:FindItem("item_flask") and me:FindItem("item_stout_shield") then
      if inStartPosition == false then
        me:Move(StartPos)
        inStartPosition = true
      end
      state = 3
    end
    
    if inStartPosition == true and state == 3 then
      -- Once camps spawn go look for a full camp. If all camps are empty then go wait for time to be xx:00 and new camps spawn. Once camps spawn go searching again. If we find a camp then attack the creep.
      if client.gameTime >= 30 then
        if foundCamp == false then
          FindCampTarget()
        end
      elseif waitForSpawn == true then
        if client.gameTime % 60 ~= 0 then
          me:Move(StartPos)
        else
          waitForSpawn = false
          FindCampTarget()
        end
      else
        me:Attack(target)
      end
    end
      
    -- Let's sort out item purchasing
    local playerEntity = entityList:getEntities({classId=CDOTA_PlayerResource})[1]
    local gold = playerEntity:GetGold(me.playerId)
    
    -- Let's get a tasty morbid mask!
    if state == 3 and gold >= 900 then
      entityList:GetMyPlayer():BuyItem(26)
      DeliverByCourier()
      state = 4
    end
    
    -- Let's get our smoke
    if state == 4 and gold >= 100 then
      entityList:GetMyPlayer():BuyItem(188)
      if me.level == 4 then
        me:Move(SpawnPos)
        state = 6
      end
      state = 5
    end
      
  end
end


-- Just a Test
function Key(msg,code)
  if client.chat or client.console or client.loading then return end
  if IsKeyDown(config.Test) then
    local me = entityList:GetMyHero()
    client:ExecuteCmd("say state = "..state.." inPosition = "..(inPosition and 1 or 0).."TIME ="..client.gameTime)
    print("X="..client.mousePosition.x.."; Y="..client.mousePosition.y.."; Team="..me.team"; Hero Position="..me.position)
  end
end

script:RegisterEvent(EVENT_TICK,Tick)
script:RegisterEvent(EVENT_KEY,Key)
