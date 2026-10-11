return function(game)
  io.stdout:setvbuf('no')
  local K=game.mods.exports.kanto_ascendant;local facts=K.backendGenerationRules67
  local out=assert(os.getenv('SEVII_QA_OUTPUT'));local J=require('src.link.Json')
  game:startNewGame{intro=false}
  game.save.flags.EVENT_BEAT_CHAMPION_RIVAL=true
  local S=assert(K.seviiExpedition)
  S.persist({version=1,stage=3,chapterOneComplete=true,samples={heat=true,drift=true}})
  require('tests.drivers.util').teleport(game,S.harbors[1],8,5,'right')
  local profile=K.generationRules.resolve(game)
  assert(profile.activeEpoch==4,'audit fixture must use normal post-report Sevii profile')
  local rewards={};for _,r in ipairs(K.equipmentRewards67.pool(game.data,{activeEpoch=3}))do rewards[r.item]=true end
  local rewardsByEpoch={}
  for epoch=2,7 do
    for _,r in ipairs(K.equipmentRewards67.pool(game.data,{activeEpoch=epoch}))do
      rewardsByEpoch[r.item]=rewardsByEpoch[r.item]or{}
      table.insert(rewardsByEpoch[r.item],epoch)
    end
  end
  local archive={};for _,r in ipairs(K.fieldTech.renewableTMs(game))do archive[r.id]=true end
  local wanderers={};for _,r in ipairs(K.legacyWanderers.rewardPool(game))do wanderers[r.item]=true end
  local sevii={};for _,shop in ipairs(S.population.berryShops)do
    for _,id in ipairs(S.population.berryStock(game,shop.id))do sevii[id]=shop.source end
  end
  for _,id in ipairs(S.population.apricornStock(game))do sevii[id]=S.population.apricornShop.source end
  for _,id in ipairs(S.population.researchBallStock(game))do sevii[id]=S.population.researchBallShop.source end
  for _,shop in ipairs(S.population.medicineShops)do
    for _,id in ipairs(S.population.medicineStock(game,shop.id))do sevii[id]=shop.source end
  end
  for _,shop in ipairs(S.population.recoveryShops)do
    for _,id in ipairs(S.population.recoveryStock(game,shop.id))do sevii[id]=shop.source end
  end
  -- Probe an explicitly expanded QA save. The actual acquisition/evolution
  -- driver separately exercises captures and native Bag consumption.
  local boundary=K.beyondKanto.isActive(game)
  if not boundary then assert(K.beyondKanto.activate(game,{decision='qa-item-audit-fixture'}))end
  for _,id in ipairs(S.population.evolutionStock(game))do sevii[id]=S.population.evolutionShop.source end
  local finds={};for _,row in ipairs(S.population.finds)do finds[row.item]={id=row.id,source=row.source}end
  local milestoneRewards={};for _,row in ipairs(S.population.rewards)do
    milestoneRewards[row.item]={id=row.id,requires=row.flag}
  end
  local trainerRewards={};for _,row in ipairs(S.trainers and S.trainers.allRows or{})do
    trainerRewards[row.reward]={trainer=row.id,source=row.source}
  end
  local towerReward=S.tower and S.tower.roofReward
  local towerSource=S.tower and S.tower.roof and S.maps[S.tower.roof.map].kaSeviiSource
  -- Ask the existing shop with actual eligible party members. A catalog
  -- entry or the mere presence of an evolution field is not a shop route.
  local evolution={};local probes={}
  for _,dex in ipairs({61,79,95,117,123,137,349,366})do
    local species=K.backendGiftSpecies67.byKey['dex:'..dex]
    if species then
      local mon=require('src.pokemon.Pokemon').new(game.data,species,50)
      game.save.party={mon}
      local probe={dex=dex,species=species,offers={},pending={}};probes[#probes+1]=probe
      for _,offer in ipairs(K.wave1EvolutionItems67.offers(game,mon))do
        evolution[offer.id]=evolution[offer.id]or{}
        table.insert(evolution[offer.id],dex)
        probe.offers[#probe.offers+1]=offer.id
      end
      for _,item in ipairs({'PRISM_SCALE','DEEP_SEA_TOOTH','DEEP_SEA_SCALE'})do
        probe.pending[item]=require('src.pokemon.Evolution').pendingFor(game,mon,{kind='item',item=item})or false
      end
    end
  end
  local report={schema='kasc.sevii-item-audit/v2',items={},activeEpoch=profile.activeEpoch,
    evolutionProbes=probes,hoennShopReadiness=K.wave1EvolutionItems67.hoennOffers,
    evolutionProbeScope='Fresh uncaught party fixtures in an explicitly expanded save; actual acquisition/evolution proof is separate in the native evolution driver.',
    scope='Registered Gen2/3 identities only. Live archive, reward and Sevii shop membership plus selected evolution offers; not a global proof of unobtainability. Held readiness is separate from field, capture and evolution support.'}
  local count,ready,ordinary=0,0,0
  for id,def in pairs(game.data.items)do
    local row=facts.item(id,3)or facts.item(id,2)
    local generation=row and row.generation or def.originGeneration or def.originEpoch
    if generation==2 or generation==3 then
      local readiness=def.kascEquipmentRewardEpochs
      local supported=readiness and readiness[3]==true or false
      local epochs={};for epoch=2,7 do if readiness and readiness[epoch]==true then epochs[#epochs+1]=epoch end end
      local effect=def.effect and game.data.item_effects and game.data.item_effects[def.effect]
      local move=def.machine and game.data.moves[def.machine.move]
      local nativeMove=move and game.data.move_effects and game.data.move_effects[move.effect]
      count=count+1;if supported then ready=ready+1 end;if rewards[id]then ordinary=ordinary+1 end
      report.items[#report.items+1]={id=id,name=def.name,generation=generation,price=def.price,
        keyItem=def.keyItem==true,fieldEffect=def.effect or false,machine=def.machine or false,
        battleReadyGen3=supported,existingOrdinaryReward=rewards[id]==true,
        heldReadyEpochs=epochs,ordinaryRewardEpochs=rewardsByEpoch[id]or{},
        registeredItemEffect=effect~=nil and type(effect.use)=='function',
        registeredBall=game.data.balls and game.data.balls[id]~=nil or false,
        renewableTMArchive=archive[id]==true,wandererRewardCurrentProfile=wanderers[id]==true,
        seviiShop=sevii[id]or false,evolutionShopForDex=evolution[id]or{},
        seviiTrainerReward=trainerRewards[id]or false,
        seviiTowerReward=id==towerReward and towerSource or false,
        seviiFind=finds[id]or false,
        seviiMilestoneReward=milestoneRewards[id]or false,
        machineMoveEffect=move and move.effect or false,
        machineMoveEffectRegistered=nativeMove~=nil,
        factsEffect=row and row.effect or false,flags=row and row.flags or{}}
    end
  end
  table.sort(report.items,function(a,b)return a.id<b.id end)
  local f=assert(io.open(out..'/item-access-audit.json','wb'));f:write(J.encode(report));f:close()
  print('SEVII_ITEM_AUDIT',count,'Gen2/3 definitions;',ready,'ready held effects;',ordinary,'existing ordinary rewards')
  love.event.quit()
end
