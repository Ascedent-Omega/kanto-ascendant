return function(game)
 io.stdout:setvbuf('no')
 local root=assert(os.getenv('SEVII_KASC_ROOT'));local out=assert(os.getenv('SEVII_QA_OUTPUT'))
 local U=require('tests.drivers.util');local Q=dofile(root..'/tests/habitat_playthrough/drivers/common.lua')(game)
 local K=game.mods.exports.kanto_ascendant;local S=K.seviiExpedition;local H=S.legendPolicy.history
 local R=K.rocketRecoveryRaids67;local runtime=K.rocketRecoveryRaids67Runtime;local data=K.rocketRecoveryRaids67Data
 local Json=require('src.link.Json');local Pokemon=require('src.pokemon.Pokemon')
 game:startNewGame{intro=false};game.mods.modOptions.kanto_ascendant.living_world_enabled=false
 game.save.flags.EVENT_FOLLOWED_OAK_INTO_LAB=true;game.save.flags.EVENT_GOT_STARTER=true
 game.save.flags.EVENT_BEAT_CHAMPION_RIVAL=true
 for _,id in ipairs{'BOULDERBADGE','CASCADEBADGE','THUNDERBADGE','RAINBOWBADGE','SOULBADGE','MARSHBADGE','VOLCANOBADGE','EARTHBADGE'}do game.save.inventory[id]=true end
 game.save.party={Pokemon.new(game.data,'BLASTOISE',100)}
 local hostage=Pokemon.new(game.data,'PIDGEY',20);hostage.nickname='RUECKKEHR'
 game.save.boxes[1]={hostage}
 assert(K.beyondKanto.activate(game,{decision='qa-rocket-sevii-transition'}))
 U.teleport(game,'VERMILION_CITY',18,12,'down');Q.settle()
 assert(H.sync(game));assert(R.start(game,'box'),'real isolated Box custody start')
 local function stored(s)game.save.modData.kanto_ascendant[R.stateKey]=s end
 local function pending(index,rows)
  local s=R.status();s.status='capture';s.instance=index;s.pendingCaptures=rows;s.captureIndex=1
  s.captureReceipts={};s.completed[data.instances[index].id]=true;s.rewardReceipts[data.instances[index].id]={qa=true}
  stored(s)
 end
 local function checkpoint()
  assert(game:writeSave());game:restoreSave(assert(require('src.core.SaveData').load('red')));Q.settle()
 end
 -- An in-flight historical Darkrai prompt can still be open at upgrade time.
 -- Its callback must re-check the source instead of starting a blocked battle.
 pending(2,{data.contraband[1]})
 local map=data.instances[2].map
 runtime.sync(game,map);U.teleport(game,map,17,10,'up');Q.settle()
 assert(runtime.talk(game,game.overworld,nil,'capture','darkrai_dream'))
 Q.settle()
 assert(game.overworld.map.id=='POKEMON_TOWER_1F','retired prompt returns to untouched host map')
 assert(R.status().instance==3 and R.status().status=='active','retired prompt advances campaign')
 assert(not H.owned(game,'DARKRAI')and not R.status().captureReceipts.darkrai_dream,'migration issues neither mon nor catch receipt')
 checkpoint();assert(R.status().instance==3,'transition survives real reload')
 print('SEVII_ROCKET_RETIRED_PROMPT_PASS')
 -- Regigigas now belongs to Sevii. The unrelated unowned Genesect rescue
 -- remains available; this catches the former numeric/string instance mismatch.
 pending(3,{data.contraband[2]});checkpoint()
 assert(R.currentCapture()and R.currentCapture().species=='GENESECT','unowned Genesect rescue survives install/load')
 assert(not H.owned(game,'REGIGIGAS'),'pending rescue never asserts ownership')
 print('SEVII_ROCKET_UNOWNED_PENDING_RELOAD_PASS')
 -- Historical captures, with neither current Pokemon nor owned Dex entries,
 -- must prevent a new specimen while allowing the raid to return its custody.
 pending(4,{data.contraband[3]})
 local s=R.status()
 s.captureReceipts={darkrai_dream={species='DARKRAI',incident=1,attempts=1},regigigas_power={species='REGIGIGAS',incident=1,attempts=2}}
 stored(s);checkpoint()
 assert(H.owned(game,'DARKRAI')and H.owned(game,'REGIGIGAS'),'old Rocket-only capture receipts adopted')
 assert(R.status().status=='complete'and R.status().campaignComplete,'owned final rescue finishes operation')
 local count=0
 for _,box in ipairs(game.save.boxes)do for _,m in ipairs(box)do if m.nickname=='RUECKKEHR'then count=count+1 end end end
 assert(count==1,'real Box custody returned exactly once')
 assert(not S.legendPolicy.raidCaptureAllowed(game,data.contraband[3]),'old Regigigas cannot be requeued')
 local captured=R.status();captured.captureReceipts={};stored(captured);game.save.pokedex.owned.REGIGIGAS=nil;game.save.pokedex.owned.DARKRAI=nil
 checkpoint();assert(H.owned(game,'DARKRAI')and H.owned(game,'REGIGIGAS'),'adopted history survives old-ledger reset')
 local state,err=K.legacyJourney.archive.beginJourney(game.save,{pact='journey',bankPolicy='sealed',itemPolicy='empty',
  runRules=K.legacyJourney.archive.safeRunRulesSnapshot(game.save),playerAvatar='BLUE'})
 assert(state,err)
 local fresh={party={},boxes={},flags={},modData={}}
 assert(K.legacyJourney.archive.seedNewSave(fresh))
 local history=fresh.modData.kanto_ascendant.hevo_persistent[H.KEY]
 assert(history['486']and history['491'],'Rocket-only history crosses actual Legacy transaction')
 local f=assert(io.open(out..'/rocket-sevii-transition.json','wb'))
 f:write(Json.encode({passed=true,retiredPromptReturned=true,unownedPendingReload=true,unownedPendingSpecies="GENESECT",oldReceiptsMigrated=true,
  custodyReturnedCount=count,legacySeed=history,
  scope='Isolated QA. Real Box custody, native Rocket dialogue/callback, save/load and Legacy transactions. Champion/badges/team, completed boss and pending rescue/capture receipts are historical fixtures. No claim of replaying Rocket trainer battles or catching Regigigas.'}));f:close()
 print('SEVII_ROCKET_TRANSITION_PASS');love.event.quit()
end
