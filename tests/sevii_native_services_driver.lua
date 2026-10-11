return function(game)
 io.stdout:setvbuf('no')
 local root=assert(os.getenv('SEVII_KASC_ROOT'));local out=assert(os.getenv('SEVII_QA_OUTPUT'))
 local U=require('tests.drivers.util');local Q=dofile(root..'/tests/habitat_playthrough/drivers/common.lua')(game)
 local K=game.mods.exports.kanto_ascendant;local S=K.seviiExpedition;local P=S.population;local D=K.daycare
 local Pokemon=require('src.pokemon.Pokemon');local Json=require('src.link.Json')
 require('src.world.OverworldController').rollEncounter=function()return nil end
 game:startNewGame{intro=false};game.save.options.colors='redpp';game:applyOptions()
 game.mods.modOptions.kanto_ascendant.living_world_enabled=false
 game.save.flags.EVENT_FOLLOWED_OAK_INTO_LAB=true;game.save.flags.EVENT_GOT_STARTER=true
 local lead=Pokemon.new(game.data,'BLASTOISE',60);lead.moves={{id='SURF',pp=15}}
 local partner=Pokemon.new(game.data,'EEVEE',30);partner.nickname='SEVII QA'
 game.save.party={lead,partner};game.save.money=10000
 local function arrival(site)
  local entry
  for _,rows in pairs(S.links)do for _,w in ipairs(rows)do if w.map==site.map then entry=w;break end end;if entry then break end end
  assert(entry,'imported building entrance')
  U.teleport(game,site.map,entry.toX,entry.toY,entry.facing or'up');Q.settle();Q.faceObject(site.x,site.y)
 end
 local function answer(yes)
  for _=1,1800 do
   local t=game.stack:top()
   if t==game.overworld then Q.settle();return end
   if t.labels and t.onChoose then
    local wanted=yes and 1 or 2
    if t.pending~=nil then U.wait(1)elseif t.index~=wanted then Q.tap('down')else Q.tap('a')end
   elseif t.isTextBox or t.pages then Q.tap('a')else Q.tap('b')end
  end
  error('service dialog did not finish')
 end
 local function menu()
  for _=1,1800 do local t=game.stack:top();if t.items then return t end;Q.tap('a')end
  print('SERVICE_MENU_STATE',game.overworld.map.id,game.overworld.player.cellX,game.overworld.player.cellY,game.overworld.player.facing,tostring(Q.sceneReady()))
  for _,npc in ipairs(game.overworld.npcs or{})do print('SERVICE_NPC',npc.def.name,npc.cellX,npc.cellY,tostring(npc.frozen),tostring(npc.hidden))end
  for _,t in ipairs(game.stack.states)do print('SERVICE_SCREEN',t.screenId,t.title,tostring(t.isTextBox),tostring(t.items~=nil))end
  assert(U.shot(game,out..'/services-menu-missing.png'))
  error('shared nursery menu missing')
 end
 local function checkpoint()
  assert(game:writeSave());game:restoreSave(assert(require('src.core.SaveData').load('red')));Q.settle()
 end
 if os.getenv('SEVII_SERVICES_UI_ONLY')=='1'then
  game.save.flags.EVENT_BEAT_CHAMPION_RIVAL=true;arrival(P.nursery);Q.tap('a')
  local panel=menu();assert(panel.__vascHeaderLabel=='DAY-CARE')
  U.wait(30);assert(U.shot(game,out..'/services-four-island-nursery.png'))
  print('SEVII_ISLAND_SERVICES_UI_PASS');love.event.quit();return
 end
 arrival(P.spa);lead.hp=1;Q.tap('a');Q.settle();assert(lead.hp==1,'pre-League spa gate')
 arrival(P.nursery);Q.tap('a');Q.settle()
 local prior=D.status();assert(not prior or not prior.parents[1],'pre-League nursery gate')
 game.save.flags.EVENT_BEAT_CHAMPION_RIVAL=true;assert(K.beyondKanto.activate(game,{decision='qa-island-services'}))
 S.persist({stage=3,chapterOneComplete=true,samples={heat=true,drift=true}});K.generationRules.resolve(game)
 arrival(P.spa)
 lead=game.save.party[1];partner=game.save.party[2]
 lead.hp=1;lead.status='PAR';lead.moves[1].pp=1;partner.hp=0;partner.status='PSN'
 local heal=Json.encode(game.save.lastHeal);local money=game.save.money
 Q.tap('a');answer(false);assert(lead.hp==1 and lead.status=='PAR'and lead.moves[1].pp==1,'declined spa does nothing')
 Q.tap('a');answer(true)
 assert(lead.hp==lead.stats.hp and partner.hp==partner.stats.hp and not lead.status and not partner.status,'native spa healing/revival/status')
 assert(lead.moves[1].pp==game.data.moves.SURF.pp,'native PP recovery')
 assert(game.save.money==money and Json.encode(game.save.lastHeal)==heal,'free rest retains safe native blackout point')
 checkpoint();assert(game.save.party[1].hp==game.save.party[1].stats.hp,'rest survives load')
 local routeStaff
 for _,n in ipairs(game.data.maps.DAYCARE.objects)do if n.name=='DAYCARE_GENTLEMAN'then routeStaff={map='DAYCARE',x=n.x,y=n.y}end end
 assert(routeStaff)
 local function open(site)
  if site==P.nursery then arrival(site)
  else U.teleport(game,site.map,site.x,site.y+1,'up');Q.settle();Q.faceObject(site.x,site.y)end
  print('SERVICE_OPEN',site.map,game.overworld.player.cellX,game.overworld.player.cellY,game.overworld.player.facing)
  Q.tap('a');local t=menu()
  assert(t.title==(site==P.nursery and'FOUR ISLAND DAY-CARE'or'ROUTE 5 DAY-CARE'),'correct local nursery heading')
 end
 local function deposit(site)
  open(site);Q.choose(function(r)return r.value=='leave1'end);U.wait(5)
  local t=game.stack:top();assert(t.pickOnly,'native parent chooser')
  local wanted;for i,m in ipairs(game.save.party)do if m.nickname=='SEVII QA'then wanted=i end end;assert(wanted)
  for _=1,10 do if t.index==wanted then Q.tap('a');break end;Q.tap('down')end
  Q.settle();assert(D.status().parents[1].mon.nickname=='SEVII QA'and #game.save.party==1,'native deposit into shared slot')
 end
 local function count()
  local n=0
  for _,m in ipairs(game.save.party)do if m.nickname=='SEVII QA'then n=n+1 end end
  for _,e in pairs(D.status().parents)do if e.mon.nickname=='SEVII QA'then n=n+1 end end
  for _,box in ipairs(game.save.boxes)do for _,m in ipairs(box)do if m.nickname=='SEVII QA'then n=n+1 end end end
  return n
 end
 deposit(P.nursery);checkpoint();assert(count()==1 and #game.save.party==1,'one stored parent after load')
 local before=D.status().parents[1].steps
 U.teleport(game,'VERMILION_CITY',18,12,'down');Q.settle()
 for i=1,10 do Q.walkTo(i%2==1 and 19 or 18,12)end
 assert(D.status().parents[1].steps>before,'existing global training clock progresses')
 open(routeStaff);Q.choose(function(r)return r.value=='take1'end)
 local funds=game.save.money;game.save.money=0;answer(true)
 assert(D.status().parents[1]and count()==1 and #game.save.party==1,'Route 5 fee remains authoritative')
 game.save.money=funds
 open(routeStaff);Q.choose(function(r)return r.value=='take1'end);answer(true)
 assert(not D.status().parents[1]and #game.save.party==2 and count()==1 and game.save.money<funds,'Sevii deposit collected once on Route 5')
 deposit(routeStaff);checkpoint();assert(count()==1)
 open(P.nursery);assert(U.shot(game,out..'/services-four-island-nursery.png'))
 Q.choose(function(r)return r.value=='take1'end);funds=game.save.money;answer(true)
 assert(not D.status().parents[1]and #game.save.party==2 and count()==1 and game.save.money<funds,'Route 5 deposit collected once on Sevii')
 checkpoint();assert(count()==1 and not D.status().parents[1],'shared retrieval survives load')
 local f=assert(io.open(out..'/island-services.json','wb'))
 f:write(Json.encode({passed=true,spaDeclineAndHeal=true,spaNativePPStatusRevival=true,
  safeBlackoutPointRetained=true,preLeagueBlocked=true,nativeDepositAndRetrieveBothDirections=true,
  sharedTrainingClock=true,originalFeeEnforced=true,saveReload=true,
  fixtures='Post-League/team, travel to each imported building entrance and Route 5, controlled injuries and one insufficient-money case. All approaches, dialogue, parent selection, deposit/retrieval and rest use native UI. Not full inter-island travel or egg-production proof.'}));f:close()
 print('SEVII_ISLAND_SERVICES_NATIVE_PASS');love.event.quit()
end
