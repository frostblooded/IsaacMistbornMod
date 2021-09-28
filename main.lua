local Mistborn = RegisterMod("Mistborn", 1)

Mistborn.COLLECTIBLE_INQUISITOR_SPIKE = Isaac.GetItemIdByName("Inquisitor spike")
local game = Game()
Mistborn.INQUISITOR_SPIKE_TEAR_VARIANT_ID = Isaac.GetEntityVariantByName("Inquisitor spike")
Mistborn.Active = false

Mistborn.StatIncreases = {
  DAMAGE = 0.15,
  FIRE_DELAY = -0.3,
  SHOT_SPEED = 0.03,
  MOVE_SPEED = 0.03,
  LUCK = 0.15
}

function initStatsCache()
  Mistborn.Stats = {
    Damage = 0,
    FireDelay = 0,
    ShotSpeed = 0,
    MoveSpeed = 0,
    Luck = 0
  }
end

MistbornConfig = {
  SPIKE_SPEED = 10
}

MIN_FIRE_DELAY = 5

function math.randomkey(t) --Selects a random item from a table
    local keys = {}
    
    for key, value in pairs(t) do
        keys[#keys+1] = key --Store keys in another table
    end
    
    return keys[math.random(1, #keys)]
end

function Mistborn:onUpdate(player)
  if Mistborn.Active then
    local shootingJoystick = player:GetShootingJoystick()
    
    if shootingJoystick:Length() > 0.1 then
      Mistborn.Active = false
      player:AnimateCollectible(Mistborn.COLLECTIBLE_INQUISITOR_SPIKE, "HideItem", "Idle")
      
      local spikeVelocity = shootingJoystick:Normalized() * MistbornConfig.SPIKE_SPEED
      local spawnedSpike = Isaac.Spawn(EntityType.ENTITY_TEAR, Mistborn.INQUISITOR_SPIKE_TEAR_VARIANT_ID, 0, player.Position, spikeVelocity, player):ToTear()
      
      spawnedSpike.CollisionDamage = 10
    end
  end
end

Mistborn:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, Mistborn.onUpdate)

function Mistborn:onUse(collectibleType, rng, player, useFlags, activeSlot, customVarData)
  if collectibleType ~= Mistborn.COLLECTIBLE_INQUISITOR_SPIKE then
    return
  end
  
  Mistborn.Active = true
  player:AnimateCollectible(Mistborn.COLLECTIBLE_INQUISITOR_SPIKE, "LiftItem", "Idle")
end

Mistborn:AddCallback(ModCallbacks.MC_USE_ITEM, Mistborn.onUse)

function Mistborn:TearUpdate(tear)
  if tear.Variant == Mistborn.INQUISITOR_SPIKE_TEAR_VARIANT_ID then
    tear:GetSprite().Rotation = tear.Velocity:GetAngleDegrees()
  end
end

Mistborn:AddCallback(ModCallbacks.MC_POST_TEAR_UPDATE, Mistborn.TearUpdate)

function AddRandomStat(player)
  local increaseKey = math.randomkey(Mistborn.StatIncreases)
  local increaseVal = Mistborn.StatIncreases[increaseKey]
  
  print("Adding stat " .. increaseKey)
  
  local increaseActions = {
    ["DAMAGE"] = function ()
      Mistborn.Stats.Damage = Mistborn.Stats.Damage + increaseVal
      player:AddCacheFlags(CacheFlag.CACHE_DAMAGE)
    end,
    ["FIRE_DELAY"] = function ()
      Mistborn.Stats.FireDelay = Mistborn.Stats.FireDelay + increaseVal
      player:AddCacheFlags(CacheFlag.CACHE_FIREDELAY)
    end,
    ["SHOT_SPEED"] = function ()
      Mistborn.Stats.ShotSpeed = Mistborn.Stats.ShotSpeed + increaseVal
      player:AddCacheFlags(CacheFlag.CACHE_SHOTSPEED)
    end,
    ["MOVE_SPEED"] = function ()
      Mistborn.Stats.MoveSpeed = Mistborn.Stats.MoveSpeed + increaseVal
      player:AddCacheFlags(CacheFlag.CACHE_SPEED)
    end,
    ["LUCK"] = function ()
      Mistborn.Stats.Luck = Mistborn.Stats.Luck + increaseVal
      player:AddCacheFlags(CacheFlag.CACHE_LUCK)
    end
  }
  
  increaseActions[increaseKey]()
  player:EvaluateItems()
end

function Mistborn:TakeDamage(damagedEntity, damageAmount, damageFlags, damageSource, damageCountdownFrames)
  if damageSource.Variant ~= Mistborn.INQUISITOR_SPIKE_TEAR_VARIANT_ID then
    return
  end
  
  local npc = damagedEntity:ToNPC()
  
  if npc and npc:IsActiveEnemy(true) then
    local data = npc:GetData()
    
    -- TODO: Do this in a better way
    local willDie = npc.HitPoints - damageAmount <= 0
    
    if willDie and not data.alreadyDied then
      data.alreadyDied = true
      local player = Isaac.GetPlayer(0)
      AddRandomStat(player)
    elseif damagedEntity.ParentNPC then
      data.alreadyDied = true
    end
  end
end

Mistborn:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, Mistborn.TakeDamage)

function Mistborn:EvalCache(player, cacheFlag)
  if cacheFlag == CacheFlag.CACHE_DAMAGE then
    player.Damage = player.Damage + Mistborn.Stats.Damage
  elseif cacheFlag == CacheFlag.CACHE_FIREDELAY then
    player.MaxFireDelay = player.MaxFireDelay + Mistborn.Stats.FireDelay
  elseif cacheFlag == CacheFlag.CACHE_SHOTSPEED then
    player.ShotSpeed = player.ShotSpeed + Mistborn.Stats.ShotSpeed
  elseif cacheFlag == CacheFlag.CACHE_SPEED then
    player.MoveSpeed = player.MoveSpeed + Mistborn.Stats.MoveSpeed
  elseif cacheFlag == CacheFlag.CACHE_LUCK then
    player.Luck = player.Luck + Mistborn.Stats.Luck
  end
end

Mistborn:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, Mistborn.EvalCache)

function Mistborn:GameStart(continued)
  if continued then
    return
  end
  
  local player = game:GetPlayer(0)
  initStatsCache()
  player:AddCacheFlags(CacheFlag.CACHE_ALL)
  player:EvaluateItems()
  player:AddCollectible(Mistborn.COLLECTIBLE_INQUISITOR_SPIKE, 3)
end

Mistborn:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, Mistborn.GameStart)

initStatsCache()