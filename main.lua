local Mistborn = RegisterMod("Mistborn", 1)

Mistborn.COLLECTIBLE_INQUISITOR_SPIKE = Isaac.GetItemIdByName("Inquisitor spike")
local game = Game()
Mistborn.INQUISITOR_SPIKE_TEAR_VARIANT_ID = Isaac.GetEntityVariantByName("Inquisitor spike")
Mistborn.Active = false

Mistborn.Stats = {
  Damage = 0
}

MistbornConfig = {
  SPIKE_SPEED = 10
}

function Mistborn:onUpdate(player)
	if game:GetFrameCount() == 1 then
		player:AddCollectible(Mistborn.COLLECTIBLE_INQUISITOR_SPIKE, 3)
  end
  
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
      Mistborn.Stats.Damage = Mistborn.Stats.Damage + 1
      Isaac.DebugString("Add damage")
      player:AddCacheFlags(CacheFlag.CACHE_DAMAGE)
      player:EvaluateItems()
    elseif damagedEntity.ParentNPC then
      data.alreadyDied = true
    end
  end
end

Mistborn:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, Mistborn.TakeDamage)

function Mistborn:EvalCache(player, cacheFlag)
  Isaac.DebugString("Eval cache: " .. tostring(cacheFlag))
  
  if cacheFlag == CacheFlag.CACHE_DAMAGE then
    player.Damage = player.Damage + Mistborn.Stats.Damage
  end
end

Mistborn:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, Mistborn.EvalCache)