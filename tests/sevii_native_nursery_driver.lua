return function(game)
 io.stdout:setvbuf('no')
 local root=assert(os.getenv('SEVII_KASC_ROOT'));local out=assert(os.getenv('SEVII_QA_OUTPUT'))
 local U=require('tests.drivers.util');local Q=dofile(root..'/tests/habitat_playthrough/drivers/common.lua')(game)
 local K=game.mods.exports.kanto_ascendant;local S=K.seviiExpedition;local D=K.daycare;local H=S.legendPolicy.history
 local Pokemon=require('src.pokemon.Pokemon');local Json=require('src.link.Json')
 game:startNewGame{intro=false};game.mods.modOptions.kanto_ascendant.living_world_enabled=false
 game.save.flags.EVENT_FOLLOWED_OAK_INTO_LAB=true;game.save.flags.EVENT_GOT_STARTER=true
 game.save.flags.EVENT_BEAT_CHAMPION_RIVAL=true;game.save.party={Pokemon.new(game.data,'BLASTOISE',70)}
 assert(K.beyondKanto.activate(game,{decision='qa-sevii-nursery'}))
 S.persist({stage=3,chapterOneComplete=true,expeditionComplete=true,seviiRiftSealed=true,samples={heat=true,drift=true}})
 K.generationRules.resolve(game);assert(K.generationRules.switchMode(game,'gen4'))
 U.teleport(game,'VERMILION_CITY',18,12,'down');Q.settle();D.install(game)
 require('src.world.OverworldController').rollEncounter=function()return nil end
 local phione=assert(K.backendGiftSpecies67.byKey['dex:489']);local manaphy=assert(K.backendGiftSpecies67.byKey['dex:490'])
 local function stored(s)game.save.modData.kanto_ascendant.daycare_plus=s end
 local function parent(species,ot,defense,special)
  local mon=Pokemon.new(game.data,species,10);mon.otId=ot;mon.dvs.defense=defense;mon.dvs.special=special
  return{mon=mon,depositLevel=10,steps=0}
 end
 local s=D.status();s.parents={parent(manaphy,101,3,5),parent('DITTO',202,7,6)};s.reservedEggs={};s.eggStepsToCheck=1;stored(s)
 assert(H.sync(game)and H.owned(game,manaphy),'deposited parent reserves lifetime identity')
 assert(not D.compatible(game,s.parents[1].mon,s.parents[2].mon),'special pair cannot breed')
 for i=1,6 do Q.walkTo(i%2==1 and 19 or 18,12)end
 local after=D.status()
 assert(#after.reservedEggs==0 and after.parents[1].mon.species==manaphy and after.parents[1].steps>0,'real walking trains parent without creating egg')
 local ok,why=D.reserveEgg(phione,2048,'QA NEW','new-special');assert(not ok and why=='sevii_special_offspring','research reservation cannot bypass source rule')
 -- A previously produced egg is an existing acquisition, not a request to
 -- manufacture a replacement. Preserve its pickup and subsequent hatching.
 s=D.status();s.reservedEggs={{species=phione,steps=2048,origin='PRE-SEVII DAY-CARE',researchKey='old-special',dvs={attack=4,defense=3,speed=7,special=5}}};stored(s)
 assert(H.sync(game)and H.owned(game,phione),'previously produced waiting egg counts as ownership')
 assert(not S.legendPolicy.acquisitionAllowed(game,{species=phione}),'queued historical egg blocks additional gift')
 assert(D.reserveEgg(phione,2048,'RETRY','old-special')and #D.status().reservedEggs==1,'old reservation retry is idempotent')
 local message,taken=D.takeReservedEgg(game,1);assert(taken,message)
 local egg=game.save.party[#game.save.party];assert(egg.isEgg and egg.eggSpecies==phione and #D.status().reservedEggs==0,'historical egg physically delivered once')
 local text,hatched=D.hatchEgg(game,egg);assert(hatched and not egg.isEgg and egg.species==phione,text)
 assert(game:writeSave());game:restoreSave(assert(require('src.core.SaveData').load('red')));Q.settle()
 assert(H.owned(game,phione)and H.owned(game,manaphy),'parent and old egg lineage survive native reload')
 -- A normal pair still produces a real nursery egg through the world-step
 -- event. The successful RNG roll and parent deposit are explicit fixtures.
 s=D.status();s.parents={parent('MAGIKARP',101,3,5),parent('DITTO',202,7,6)};s.reservedEggs={};s.eggStepsToCheck=1;stored(s)
 assert(D.compatible(game,s.parents[1].mon,s.parents[2].mon),'ordinary pair still compatible')
 local random=love.math.random
 love.math.random=function(...)local a,b=...;if a==0 and b==255 then return 0 end;return random(...)end
 Q.walkTo(19,12);love.math.random=random
 assert(#D.status().reservedEggs==1 and D.status().reservedEggs[1].species=='MAGIKARP','native world step produced ordinary egg')
 message,taken=D.takeReservedEgg(game,1);assert(taken,message)
 local ordinary=game.save.party[#game.save.party];assert(ordinary.isEgg and ordinary.eggSpecies=='MAGIKARP','ordinary egg pickup preserved')
 assert(game:writeSave());game:restoreSave(assert(require('src.core.SaveData').load('red')));Q.settle()
 local eggs=0;for _,m in ipairs(game.save.party)do if m.isEgg and m.eggSpecies=='MAGIKARP'then eggs=eggs+1 end end
 assert(eggs==1,'one ordinary egg after reload')
 local f=assert(io.open(out..'/sevii-nursery.json','wb'))
 f:write(Json.encode({passed=true,blockedSpecialProduction=true,oldReservedEggDelivered=true,oldEggHatched=true,
  ordinaryEggProduced=true,ordinaryEggCount=eggs,depositedParentHistory=true,
  scope='Isolated QA: native world-step breeding/parent training, old reserved egg pickup/hatch APIs, actual save/load and canonical history. Parents, historical reservation, champion/profile and successful ordinary RNG roll are fixtures; not a full Day-Care deposit/retrieval/hatching UI walkthrough.'}));f:close()
 print('SEVII_NATIVE_NURSERY_PASS');love.event.quit()
end
