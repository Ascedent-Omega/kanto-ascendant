-- The level-100 team fixture yields level-100 legends under the current authored scaling policy.
return function(game)
  io.stdout:setvbuf('no')
  local root=assert(os.getenv('SEVII_KASC_ROOT'));local out=assert(os.getenv('SEVII_QA_OUTPUT'))
  local U=require('tests.drivers.util');local Q=dofile(root..'/tests/habitat_playthrough/drivers/common.lua')(game)
  Q.shot=function(name)assert(U.shot(game,out..'/dreams-'..name..'.png'))end
  local K=game.mods.exports.kanto_ascendant;local S=K.seviiExpedition
  local D,E,P=S.dreams,S.specialEncounters,S.legendPolicy
  local N=dofile(root..'/tests/sevii_journey_navigation.lua')(game,S,Q)
  require('src.world.OverworldController').rollEncounter=function()return nil end
  game:startNewGame{intro=false};game.save.options.colors='redpp';game:applyOptions()
  game.mods.modOptions.kanto_ascendant.living_world_enabled=false
  game.save.flags.EVENT_FOLLOWED_OAK_INTO_LAB=true;game.save.flags.EVENT_GOT_STARTER=true
  game.save.flags.EVENT_BEAT_CHAMPION_RIVAL=true
  local mon=require('src.pokemon.Pokemon').new(game.data,'BLASTOISE',100)
  mon.moves={{id='SURF',pp=15},{id='STRENGTH',pp=15},{id='ICE_BEAM',pp=10}}
  game.save.party={mon};game.save.inventory.SOULBADGE=true;game.save.inventory.RAINBOWBADGE=true
  assert(K.beyondKanto.activate(game,{decision='qa-moonlight-aftermath-fixture'}))
  Q.extraWarpAt=function(m,x,y)for _,w in ipairs(S.links[m.id]or{})do if w.x==x and w.y==y then return true end end;return false end
  U.teleport(game,S.harbors[5],8,5,'down');Q.settle()
  N.talk(D.sites.ILSE);Q.settle();assert(not D.record().briefed,'actual nurse refuses unfinished expedition')
  local state=S.state();state.stage=3;state.chapterOneComplete=true;state.samples={heat=true,drift=true}
  state.expeditionComplete=true;state.seviiRiftSealed=true;S.persist(state);K.generationRules.resolve(game)
  N.talk(D.sites.ILSE);Q.settle();assert(D.record().briefed)
  N.talk(D.sites.JORI);Q.settle();assert(not D.record().awake,'resident needs feather')
  local function checkpoint()
    assert(game:writeSave());game:restoreSave(assert(require('src.core.SaveData').load('red')));Q.settle()
  end
  local function choose(id)
    for _=1,1800 do
      local panel=game.stack:top()
      if panel.items then
        local wanted;for i,row in ipairs(panel.items)do if row.value==id then wanted=i end end
        assert(wanted,'missing dream choice '..id)
        for _=1,60 do if panel.index==wanted then Q.tap('a');return end;Q.tap(panel.index>wanted and'up'or'down')end
        error('dream choice stuck')
      end
      assert(panel~=game.overworld,'dream menu unexpectedly closed');Q.tap('a')
    end
    error('dream menu not reached')
  end
  local captures={}
  local function catch(id)
    N.talk(D.sites[id]);choose('battle');local b
    for _=1,1800 do local top=game.stack:top();if top.enemy and top.phase=='menu'then b=top;break end;Q.tap('a')end
    local species=assert(K.backendGiftSpecies67.byKey['dex:'..E.rows[id].dex])
    assert(b and b.enemy.mon.species==species and b.enemy.mon.level==100)
    assert(P.captureAllowed(game,species,b)and not P.captureAllowed(game,species),'authored capture only')
    for _,mv in ipairs(b.enemy.mon.moves)do assert(game.data.moves[mv.id]and not tostring(game.data.moves[mv.id].effect):find('UNSUPPORTED',1,true),'supported dream legend move '..mv.id)end
    local safe,reason=require('src.battle.BattleSafety').inspect(game,b)
    assert(not safe and reason=='battle_origin_unsupported','custom checkpoint protected')
    Q.catch(species,true,'down');Q.settle();checkpoint()
    local count=0
    for _,list in ipairs({game.save.party,unpack(game.save.boxes)})do for _,m in ipairs(list)do if m.species==species then count=count+1 end end end
    assert(count==1 and P.history.owned(game,species)and S.state().specialCaptures[id],'one saved legendary '..id)
    N.talk(D.sites[id]);Q.settle();local ok,why=E.start(game,id);assert(not ok and why=='legend_owned')
    captures[#captures+1]={id=id,species=species,count=count};print('SEVII_DREAM_CAPTURE_RELOAD_PASS',id)
  end
  N.talk(D.sites.FEATHER);Q.settle();checkpoint();assert(D.record().feather,'recovered feather survives reload')
  N.talk(D.sites.CRESSELIA);Q.settle();assert(not D.record().awake)
  local available,why=E.availability(game,'CRESSELIA');assert(not available and why=='trial-required','capture waits for rescue')
  N.talk(D.sites.JORI);Q.settle();assert(D.record().awake,'actual resident wakes')
  catch('CRESSELIA')
  N.talk(D.sites.LANTERN);Q.settle();assert(D.record().trail==1,'actual lantern starts trail')
  N.go(D.route[1],5,2);U.hold(game,'up',1);U.wait(40);Q.settle()
  assert(D.record().lostWay and not D.record().trail,'actual wrong door loop resets light trail')
  N.talk(D.sites.LANTERN);Q.settle();assert(D.record().trail==1)
  for i,door in ipairs(D.doors)do
    N.go(door.map,door.toX,door.toY);Q.settle()
    assert(D.record().trail==i+1,'real door advances trail '..i)
    if i==4 then checkpoint();assert(D.record().trail==5,'mid-maze progress survives reload')end
  end
  assert(D.record().refugeReady)
  N.talk(D.sites.DARKRAI);Q.settle();assert(D.record().quiet and not D.record().feather,'actual final stone receives feather')
  available,why=E.availability(game,'DARKRAI');assert(not available and why=='trial-required','report required before encounter: '..tostring(why))
  N.talk(D.sites.ILSE);Q.settle();checkpoint();assert(D.record().complete,'actual house report completes story')
  assert(S.chapters.journal():find('A MOONLIT NIGHT COMPLETE',1,true))
  N.talk(D.sites.JORI);Q.settle();assert(D.record().awake,'resident remains well after report/load')
  catch('DARKRAI');N.sail(0);assert(game.overworld.map.id=='VERMILION_CITY')
  local f=assert(io.open(out..'/moonlit-night.json','wb'))
  f:write(require('src.link.Json').encode({passed=true,steps=N.steps,seams=N.seams,doors=N.doors,ferries=N.sails,
    captures=captures,featherReload=true,nativeWrongDoor=true,nineRealDoors=true,midMazeReload=true,questComplete=true,
    scope='Isolated QA: physical routes from harbor, feather recovery, waking resident, wrong same-room door, nine consecutive real Lost Cave doors, mid-maze save/load, quiet refuge, house report, two native catches/reloads and return to Orania. Initial champion/finale/team/badges/harbor position, disabled ordinary spawns and Master Balls are fixtures; not a balance proof.'}));f:close()
  print('SEVII_NATIVE_MOONLIT_NIGHT_PASS',#captures,N.steps,N.seams,N.doors,N.sails);love.event.quit()
end
