-- Current Sevii weather seals, original Birth Island triangle and wish room.
-- Foundation, completed expedition and character path gates are explicit fixtures.
return function(game)
 io.stdout:setvbuf('no')
 local root=assert(os.getenv('SEVII_KASC_ROOT'));local out=assert(os.getenv('SEVII_QA_OUTPUT'))
 local mode=os.getenv('SEVII_HOENN_MODE')or'capture';assert(mode=='capture'or mode=='witness')
 local U=require('tests.drivers.util');local Q=dofile(root..'/tests/habitat_playthrough/drivers/common.lua')(game)
 Q.shot=function(name)assert(U.shot(game,out..'/hoenn-'..mode..'-'..name..'.png'))end
 local K=game.mods.exports.kanto_ascendant;local S=K.seviiExpedition;local H=S.legendPolicy.history
 local P,B,J,D,E=K.hoennLegendPortals67,K.hoennBirthIsland67,K.hoennJirachiFinale67,K.hoennDexCompletion67,K.hoennEndgameRunEvents67
 local A,L=K.eventArchive,K.legacyJourney.archive
 require('src.world.OverworldController').rollEncounter=function()return nil end
 game:startNewGame{intro=false};game.save.options.colors='redpp';game:applyOptions()
 game.mods.modOptions.kanto_ascendant.living_world_enabled=false
 game.save.flags.EVENT_FOLLOWED_OAK_INTO_LAB=true;game.save.flags.EVENT_GOT_STARTER=true
 game.save.flags.EVENT_BEAT_CHAMPION_RIVAL=true
 game.save.party={require('src.pokemon.Pokemon').new(game.data,'DRAGONITE',100)}
 game.save.inventory.HOENN_HONEY=1;game.save.inventory.HOENN_DEX=1
 assert(K.beyondKanto.activate(game,{decision='qa-original-hoenn-continuity'}))
 assert(S.begin(game))
 local expedition=S.state();expedition.expeditionComplete=true;expedition.seviiRiftSealed=true;S.persist(expedition)
 local profile,seal,doorVisit=K.legacyJourney.profile,K.legacyJourney.currentHevoSeal,K.legacyJourney.currentHevoDoorVisit
 K.legacyJourney.profile=function(...)
  local p=profile(...);p.completedPaths={red=true,green=true,blue=true};return p
 end
 K.legacyJourney.currentHevoSeal=function(_,character)return true,character end
 K.legacyJourney.currentHevoDoorVisit=function()return true end
 for _,id in ipairs(D.foundationOrder)do assert(D.record(game,id))end
 U.teleport(game,'VERMILION_CITY',18,12,'down');Q.settle();assert(game:writeSave());assert(H.sync(game))
 local function checkpoint()
  assert(game:writeSave());game:restoreSave(assert(require('src.core.SaveData').load('red')));Q.settle()
 end
 local function count(id)
  local n=0;for _,m in ipairs(game.save.party)do if m.species==id then n=n+1 end end
  for _,box in ipairs(game.save.boxes)do for _,m in ipairs(box)do if m.species==id then n=n+1 end end end
  return n
 end
 local ids={'GROUDON','KYOGRE','RAYQUAZA','DEOXYS','JIRACHI'}
 if mode=='witness'then
  for index,id in ipairs(ids)do
   local wanted=H.ids[id];local gift
   for _,campaign in ipairs(K.giftCodeCatalog.campaigns)do for _,event in ipairs(campaign.events)do
    local p=A.profile(event.profileId)
    if p and p.id==('backend_base_%04d'):format(wanted)then gift=p end
   end end
   assert(gift,'canonical gift '..id)
   local receipt={version=1,digest=string.rep(tostring(index),64),campaignId='sevii-hoenn-qa',
    buildId='isolated-qa',eventId='old-hoenn-'..index,profileId=gift.id}
   local mon=assert(A.deliverGift(game,gift.id,'CONTINUITY QA',receipt,{boxOnly=true}))
   assert(H.owned(game,id)and count(id)==1,'actual gift delivery '..id)
   -- Release fixture: remove the exact delivered object, retain its genuine
   -- acquisition receipts. This is not a PC-menu/release UI test.
   for _,box in ipairs(game.save.boxes)do for i=#box,1,-1 do if box[i]==mon then table.remove(box,i)end end end
   assert(count(id)==0 and not A.acquisitionAllowed(game,gift),'released gift cannot be duplicated '..id)
  end
  checkpoint()
 end
 local function visit(map,x,y)
  U.teleport(game,map,x,y+1,'up');Q.settle();Q.faceObject(x,y);Q.tap('a');U.wait(8)
 end
 local function approachWeather(character)
  local site=S.weatherTrio.sites[character]
  visit(site.map,site.x,site.y);Q.settle()
  if game.stack:top()==game.overworld then Q.tap('a');U.wait(8)end
  assert(game.stack:top().items,'current weather approach menu '..character)
  Q.choose(function(r)return r.value=='approach'end)
 end
 local function duplicateBlocked(id)
  local b=require('src.battle.BattleState').newWild(game,id,30,{randomizerProtected=true})
  game.save.inventory.MASTER_BALL=2
  assert(require('src.inventory.ItemEffects').use(game.data,game.save,'MASTER_BALL',nil,b)=='failed')
  assert(game.save.inventory.MASTER_BALL==2 and b:catchAttempt('MASTER_BALL')==false,'duplicate rejected before consumption '..id)
 end
 local function confirmCertificate()
  for _=1,1800 do
   local t=game.stack:top()
   if getmetatable(t)==J.Certificate then Q.shot('certificate');Q.tap('a');Q.settle();return end
   if t.labels and t.onChoose then
    if t.pending~=nil then U.wait(1)elseif t.index~=1 then Q.tap('up')else Q.tap('a')end
   elseif t.isTextBox or t.pages then Q.tap('a')else U.wait(1)end
  end
  error('native Jirachi certificate did not appear')
 end
 for _,character in ipairs{'RED','BLUE','GREEN'}do
  K.extendedCharacters.select(character);local row=P.rows[character]
  assert(P.available(game,character),'current weather prerequisite fixture')
  local closed,why=P.enter(game,row);assert(not closed and why=='moved-to-sevii','retired portal remains closed')
  if mode=='witness'then
   game.mods.modOptions.kanto_ascendant.hoenn_legend_portals=false
   approachWeather(character);Q.settle();assert(not P.witnessed(game,row),'option remains authoritative')
   game.mods.modOptions.kanto_ascendant.hoenn_legend_portals=true
  end
  approachWeather(character)
  if mode=='capture'then Q.catch(row.species,true,'down');Q.settle();assert(P.caught(game,row)and count(row.species)==1)
  else Q.answerChoice(true);Q.settle();assert(P.witnessed(game,row)and not P.caught(game,row)and count(row.species)==0)end
  checkpoint();assert(H.owned(game,row.species));duplicateBlocked(row.species)
  print('SEVII_CURRENT_HOENN_WEATHER_PASS',mode,row.species)
 end
 local report=D.report(game)
 assert(report.birthIslandReady and report.allPortalResearch,'original research chain remains open')
 assert(report.allPortalCaptures==(mode=='capture'),'research ceremonies never fabricate capture seals')
 assert(not B.available(game),'Birth Island additionally requires current-run events')
 E.mark(game,'MOLTRES',{captured=false,battleResult='witnessed'});E.mark(game,'REGIROCK',{captured=false,battleResult='witnessed'})
 assert(B.available(game));U.teleport(game,B.MAP,8,12,'up');Q.settle()
 for index=1,#B.trianglePositions-1 do
  local pos=B.trianglePositions[index];Q.faceObject(pos[1],pos[2]);Q.tap('a');Q.settle()
 end
 local pos=B.trianglePositions[#B.trianglePositions];Q.faceObject(pos[1],pos[2]);Q.tap('a');U.wait(8)
 if mode=='capture'then Q.catch('DEOXYS',true,'down');Q.settle();assert(count('DEOXYS')==1)
 else Q.yes();Q.settle();assert(count('DEOXYS')==0)end
 local receipt=E.state(game).completed.DEOXYS
 assert(receipt.captured==(mode=='capture')and receipt.battleResult==(mode=='capture'and'caught'or'witnessed'))
 checkpoint();assert(H.owned(game,'DEOXYS'));duplicateBlocked('DEOXYS')
 assert(J.available(game),'all original Hoenn ownership and research requirements satisfied')
 local entered,why=J.enter(game);assert(not entered and why=='convergence-door-only','old wish shortcut remains closed')
 visit(J.MAP,8,4)
 if mode=='capture'then Q.catch('JIRACHI',true,'down');Q.settle();assert(J.caught(game)and count('JIRACHI')==1)
 else confirmCertificate();assert(J.witnessed(game)and not J.caught(game)and count('JIRACHI')==0)end
 checkpoint();assert(H.owned(game,'JIRACHI'));duplicateBlocked('JIRACHI')
 K.legacyJourney.profile=profile;K.legacyJourney.currentHevoSeal=seal;K.legacyJourney.currentHevoDoorVisit=doorVisit
 game.save.party={game.save.party[1]};game.save.boxes={};for i=1,12 do game.save.boxes[i]={}end
 game.save.pokedex.owned={DRAGONITE=true};assert(game:writeSave())
 assert(L.beginJourney(game.save,{pact='journey',bankPolicy='sealed',itemPolicy='empty',
  runRules=L.safeRunRulesSnapshot(game.save),playerAvatar='BLUE'}))
 local fresh={party={},boxes={},flags={},modData={}};assert(L.seedNewSave(fresh))
 local persistent=fresh.modData.kanto_ascendant.hevo_persistent
 for _,id in ipairs(ids)do assert(persistent[H.KEY][tostring(H.ids[id])],'lifetime history across actual Legacy '..id)end
 if mode=='witness'then for _,id in ipairs{'GROUDON','KYOGRE','RAYQUAZA','JIRACHI'}do
  assert(persistent.secretUnlocks['KA_LEGEND_WITNESS_'..id]and not persistent.secretUnlocks['KA_LEGEND_CAPTURE_'..id],'witness stays distinct across Legacy '..id)
 end end
 local f=assert(io.open(out..'/hoenn-continuity-'..mode..'.json','wb'))
 f:write(require('src.link.Json').encode({passed=true,mode=mode,species=ids,actualLegacy=true,
  currentWeatherSites=true,retiredEntrancesClosed=true,wishRoomEntryFixture=true,trianglePlayed=true,duplicateBallsUnspent=true,
  fixtures='130-species foundation, Hoenn Honey/Dex, three prior paths and current character seals/door visits, completed Sevii expedition, post-League/team, travel including wish-room position; witness gifts use actual delivery owner, release uses direct exact-object removal; no full HEVO/NG+ UI run'}));f:close()
 print('SEVII_CURRENT_HOENN_CONTINUITY_PASS',mode);love.event.quit()
end
