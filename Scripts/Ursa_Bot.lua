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
require("libs.HeroInfo")

-- Script config, hotkeys, levelling etc
local config = ScriptConfig.new()
config:SetParameter("minHealth", 150)
config:SetParameter("Test", "L", config.TYPE_HOTKEY)
config:Load()

local currentLevel = 0
--=======================
--== States Explanation==
--=======================
-- 1 is in base, just spawned
-- 2 is bought items
-- 3 is have items and moved to start position, ready to jungle
-- 4 is need a tango
-- 5 is need a salve
-- 6 is have morbid mask
-- 7 is have smoke
-- 8 is have smoke and morbid mask and level 4 (Rosh Time)
local state = 1
local inStartPosition = false
local levels = {3,2,3,2,1,4,1,1,1,2,2,3,3,4,5,4,5,5,5,5,5,5,5,5,5}

-- Salve, tango and stout shield
local startingItems = {44, 182, 39}

-- Camp locations, Hard, Med, Rune, Easy, Lane (in that order)
local campLocationDire = {Vector(1041, 3511, 0), Vector(-477, 3881, 0), Vector(-1457, 2909, 0), Vector(-3033, 4790, 0), Vector(-4228, 3680, 0)}
-- Tango Locations for med x2, rune x2, hard camp x2
local tangoLocationDire = {Vector(-50.85, 3742.53, 0), Vector(165.21, 3691.02, 0), Vector(1560.37, 3535.23, 0), Vector(1733.77, 3430.63, 0), Vector(-1341.73, 2585.26, 0), Vector(-1176.96, 2642.51,0)}


-- Config for finding a camp
local target = nil
local foundCamp = false
local waitForSpawn = false
local campsVisited = 0

-- Things for tango
local tangoCamp = 0
local prevState = 0

-- Check player is level one, then buy all the starting items we need to JUNGLLEEEEEE
function BuyStartingItems(player)
  level = player.level
  if level == 1 then 
    for i, item in ipairs(startingItems) do
      entityList:GetMyPlayer():BuyItem(item)
    end
  end
  print("Set state to 2")
  state = 2
end

-- We want to find the jungle creep with the most health. Get that prick out the way first.
function FindCreepTarget()
  local lowenemy = nil
  local enemies = entityList:GetEntities({classId=CDOTA_BaseNPC_Creep_Neutral,alive=true,visible=true})
  for i,v in ipairs(enemies) do
    if v.spawned then
      if lowenemy == nil or not lowenemy.alive or not lowenemy.visible then
        lowenemy = v
      elseif (lowenemy.maxHealth) < (v.maxHealth) then
        lowenemy = v
      end
    end
  end
  target = lowenemy
end

function FindCampTarget()
  FindCreepTarget()
  if target == nil then
    if GetDistance2D(me, campLocationDire[2]) < 300 and campsVisited == 1 then
      if me.level >= 2 then
        me:SafeCastAbility(me:GetAbility(2))
        Sleep(100)
      end
      me:Move(campLocationDire[3])
      print("Going to rune camp")
      campsVisited = 2
      tangoCamp = 3
    elseif GetDistance2D(me, campLocationDire[3]) < 300 and campsVisited == 2 then
      if me.level < 2 then
        me:Move(campLocationDire[4])
        print("Going to easy camp")
        campsVisited = 3
      else
        me:SafeCastAbility(me:GetAbility(2))
        me:Move(campLocationDire[1])
        print("Going to hard camp")
        campsVisited = 3
        tangoCamp = 5
      end
    elseif GetDistance2D(me, campLocationDire[4]) < 300 and campsVisited == 3 then
      if me.level >= 2 then
        me:SafeCastAbility(me:GetAbility(2))
        Sleep(100)
      end
      me:Move(campLocationDire[5])
      print("Going to lane camp")
      campsVisited = 4
      tangoCamp = 0
    elseif GetDistance2D(me, campLocationDire[5]) < 300 and campsVisited == 4 then
      me:Move(StartPos)
      waitForSpawn = true
    elseif not waitForSpawn and campsVisited == 0 then
      print("Going to med camp")
      if me.level >= 2 then
        me:SafeCastAbility(me:GetAbility(2))
        Sleep(100)
      end
      me:Move(campLocationDire[2])
      tangoCamp = 1
      campsVisited = 1
    end
  else
    foundCamp = true
  end
end

-- Once camps spawn go look for a full camp. If all camps are empty then go wait for time to be xx:00 and new camps spawn. Once camps spawn go searching again. If we find a camp then attack the creep. Once that creep dies attack other creeps in camp. If camp empty, go searching again. 
function GoJungling()
  -- If we don't have a target, look for a camp.
  if foundCamp == false then
    FindCampTarget()
  end
        
  -- If we are waiting for a spawn, then
  if waitForSpawn == true then
    -- If the camps haven't respawned (ie seconds/60 isn't zero), move to the start position.
    if client.gameTime % 60 ~= 0 then
      me:Move(StartPos)
    -- Else they have spawned and we should go looking
    else
      waitForSpawn = false
      FindCampTarget()
    end
      -- If we have a target and that target is alive then attack it
  elseif target and target.alive then
    me:Attack(target)
  -- Else we have killed that target or killed the camp and we should go looking again.
  elseif not target or not target.alive then
    target = nil
    foundCamp = false
  end
end

function EatTango()
  print("In tango method")
  local tango = me:FindItem("item_tango")
  if tango then
    if not me:DoesHaveModifier("modifier_tango_heal") and not me:DoesHaveModifier("modifier_flask_healing") then
      print("Trying to eat tango")
      me:SafeCastItem(tango.name, tangoLocationDire[tangoCamp])
      Sleep(500)
      if not me:DoesHaveModifier("modifier_tango_heal") then
        print("Trying to eat other tango")
        me:SafeCastItem(tango.name, tangoLocationDire[tangoCamp + 1])
        Sleep(500)
        state = prevState
      else
        state = prevState
      end
    end
  else
    state = prevState
  end
end

    
      
  -- if state = eat a tango state
  -- a variable tango check should be set based on which camp we walk to
  -- use tango
  -- if we get tango buff then go back to jungling state
  -- if we don't, eat other tango and go back to jungling state

        
function DeliverByCourier()
  me = entityList:GetMyHero()
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
  if not IsIngame() or client.paused then return end
  if not SleepCheck() then return end Sleep(200)
  
  -- Pick Ursa!
  if client.gameState == Client.STATE_PICK then
    client:ExecuteCmd("dota_select_hero npc_dota_hero_ursa")
    currentLevel = 0
    print("Set state to 1")
    state = 1
    return
  end
  
  -- Get our hero so we can access the attributes.
  me = entityList:GetMyHero()
  
  -- Each time camps respawn, set how many we've visited to zero
  if math.floor(client.gameTime % 60) == 0 then
    campsVisited = 0
    waitForSpawn = false
    end
  
  -- Check we're playing, we're spawned in and find out which team we're on.
  if PlayingGame() and me.alive then
    if currentLevel == 0 then
      if me.team == LuaEntity.TEAM_DIRE then
        StartPos = Vector(-447, 4402, 0)
        SpawnPos = Vector(7050, 6380, 0)
      elseif me.team == LuaEntity.TEAM_RADIANT then
        StartPos = Vector(256, -2346, 0)
        SpawnPos = Vector(-7077,-6780,0)
      end
    end
    
    -- Auto level up based on my skill build. Feel free to change this but it is a great build. Levels are at the top. 1, 2, 3 or 4 for each of ursa's skills. 5 for stats.
    if currentLevel ~= me.level then
      local ability = me.abilities
      local prev = SelectUnit(me)
      entityList:GetMyPlayer():LearnAbility(me:GetAbility(levels[me.level]))
      currentLevel = currentLevel + 1
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
      print("Set state to 3")
      state = 3
    end
    
    if me.health <= (me.maxHealth - 150) then
      print("Need a tango!")
      print("Set state to 4")
      prevState = state
      state = 4
      EatTango()
    end
    
    -- If we're ready to start jungling and we haven't bought any items yet
    if inStartPosition == true and state == 3 or state > 5 and state < 8 then
      -- If first spawn has happened
      if client.gameTime >= 30 then        
        GoJungling()
      end
    end
      
    -- Let's sort out item purchasing
    local playerEntity = entityList:GetEntities({classId=CDOTA_PlayerResource})[1]
    local gold = playerEntity:GetGold(me.playerId)
    
    -- Let's get a tasty morbid mask!
    if state == 3 and gold > 900 then
      entityList:GetMyPlayer():BuyItem(26)
      Sleep(200)
      DeliverByCourier()
      print("Set state to 6")
      state = 6
    end
    
    -- Let's get our smoke
    if state == 6 and gold > 100 then
      entityList:GetMyPlayer():BuyItem(188)
      if me.level == 4 then
        me:Move(SpawnPos)
        print("Set state to 8")
        state = 8
      end
      if me:FindItem("item_smoke_of_deceit") then
        print("Set state to 7")
        state = 7
      end
    end
      
  end
end


-- Just a Test
function Key(msg,code)
  if client.chat or client.console or client.loading then return end
  if IsKeyDown(config.Test) then
    local me = entityList:GetMyHero()
    client:ExecuteCmd("say state = "..state.." inPosition = "..(inPosition and 1 or 0).."TIME ="..client.gameTime)
    print("X="..client.mousePosition.x.."; Y="..client.mousePosition.y.."; Team="..me.team)
  end
end

script:RegisterEvent(EVENT_TICK,Tick)
script:RegisterEvent(EVENT_KEY,Key)
