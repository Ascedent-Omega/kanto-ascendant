return function(game)
 io.stdout:setvbuf('no')
 local root=assert(os.getenv('SEVII_KASC_ROOT'));local out=assert(os.getenv('SEVII_QA_OUTPUT'))
 local U=require('tests.drivers.util');local Q=dofile(root..'/tests/habitat_playthrough/drivers/common.lua')(game)
 Q.shot=function(name)assert(U.shot(game,out..'/moltres-continuity-'..name..'.png'))end
 local K=game.mods.exports.kanto_ascendant;local P=K.seviiExpedition.legendPolicy;local H=P.history
 local V=K.hoennMoltresVolcano67;local E=K.hoennEndgameRunEvents67;local A=K.eventArchive
 require('src.world.OverworldController').rollEncounter=function()return nil end
 game:startNewGame{intro=false};game.save.options.colors='redpp';game:applyOptions()
 game.mods.modOptions.kanto_ascendant.living_world_enabled=false
 game.save.flags.EVENT_FOLLOWED_OAK_INTO_LAB=true;game.save.flags.EVENT_GOT_STARTER=true
 game.save.flags.EVENT_BEAT_CHAMPION_RIVAL=true;game.save.hallOfFame={{}}
 local mon=require('src.pokemon.Pokemon').new(game.data,'BLASTOISE',100)
 mon.moves={{id='SURF',pp=15},{id='STRENGTH',pp=15},{id='ICE_BEAM',pp=10}}
 game.save.party={mon};game.save.inventory.SOULBADGE=true;game.save.inventory.RAINBOWBADGE=true
 U.teleport(game,'CINNABAR_ISLAND',14,7,'down');Q.settle()
 local profile
 for _,c in ipairs(K.giftCodeCatalog.campaigns)do for _,e in ipairs(c.events)do
  local p=A.profile(e.profileId)
  if P.dex(p)==146 and p.deliveryKind~='egg'and p.backendKey=='dex:146'then profile=p end
 end end
 assert(profile,'historical ordinary Moltres gift profile')
 local receipt={version=1,digest=string.rep('a',64),campaignId='sevii-moltres-qa',
  buildId='isolated-qa',eventId='moltres-a',profileId=profile.id}
 local old=assert(A.deliverGift(game,profile.id,'MOLTRES CONTINUITY QA',receipt,{boxOnly=true}))
 assert(H.owned(game,old),'actual old gift adopted')
 local function count()
  local n=0;for _,list in ipairs({game.save.party,unpack(game.save.boxes)})do for _,m in ipairs(list)do if H.key(m)=='146'then n=n+1 end end end;return n
 end
 assert(count()==1)
 local function checkpoint()
  assert(game:writeSave());game:restoreSave(assert(require('src.core.SaveData').load('red')));Q.settle()
 end
 checkpoint();assert(H.owned(game,'MOLTRES')and count()==1)
 assert(not V.recordWitness(game),'old ownership cannot bypass route')
 local ok,why=P.acquisitionAllowed(game,profile);assert(not ok and why=='legend_owned')
 local forms=0
 for key,row in pairs(K.backendNationalCatalog67.entries)do if row.nationalDex==146 then
  assert(H.owned(game,{backendKey=key}),'Moltres forms share ownership');forms=forms+1
 end end
 assert(forms>=2,'base and Galar forms')
 assert(V.openExpedition(game));Q.settle();assert(game.overworld.map.id==V.ENTRY_MAP)
 local function talk(x,y,yes)
  Q.faceObject(x,y);Q.tap('a');if yes then Q.yes()else Q.settle()end
 end
 talk(5,18)
 for _,p in ipairs{{5,15},{10,11},{14,15}}do talk(p[1],p[2])end
 talk(10,6,true);Q.walkTo(10,4,V.ASCENT_MAP);Q.settle();assert(game.overworld.map.id==V.ASCENT_MAP)
 for _,p in ipairs{{5,16},{10,16},{14,16}}do talk(p[1],p[2])end
 talk(10,13,true);Q.walkTo(10,11);U.hold(game,'up',1);Q.catch('MAGMAR',false,'down');Q.settle()
 for _,p in ipairs{{5,9},{10,8},{14,9}}do talk(p[1],p[2],true)end
 talk(10,6,true);Q.walkTo(10,4,V.MAP);Q.settle();assert(game.overworld.map.id==V.MAP)
 talk(8,5,true);assert(V.puzzleSolved(game),'actual drill and vent puzzle completed')
 local toggles=game.save.objectToggles[V.MAP]
 assert(toggles.KA_MOLTRES_VOLCANO==false and toggles.KA_MOLTRES_MEMORY==true,'feather visible; no second bird')
 Q.shot('feather')
 local oldWrite=game.writeSave;game.writeSave=function()return false end
 ok,why=V.recordWitness(game);assert(not ok and why=='save'and not E.completed(game,'MOLTRES'))
 game.writeSave=oldWrite
 talk(8,4,true)
 local done=E.state(game).completed.MOLTRES
 assert(done and done.captured==false and done.battleResult=='witnessed','real dialogue gives route seal without capture')
 assert(count()==1,'no duplicate Moltres created')
 assert(not V.recordWitness(game),'repeat ceremony refused')
 Q.walkTo(8,15,V.ASCENT_MAP);Q.settle();Q.walkTo(10,19,V.ENTRY_MAP);Q.settle()
 Q.walkTo(10,17);Q.walkTo(10,18);Q.tap('a');Q.yes();assert(game.overworld.map.id=='CINNABAR_ISLAND')
 checkpoint();assert(E.completed(game,'MOLTRES')and H.owned(game,'MOLTRES')and count()==1)
 local b=require('src.battle.BattleState').newWild(game,'MOLTRES',80,{randomizerProtected=true})
 game.save.inventory.MASTER_BALL=2
 assert(require('src.inventory.ItemEffects').use(game.data,game.save,'MASTER_BALL',nil,b)=='failed')
 assert(game.save.inventory.MASTER_BALL==2 and b:catchAttempt('MASTER_BALL')==false,'global final catch and pre-consumption guards')
 -- Isolated release fixture; the native PC release menu is not under test.
 for _,list in ipairs({game.save.party,unpack(game.save.boxes)})do for i=#list,1,-1 do if H.key(list[i])=='146'then table.remove(list,i)end end end
 checkpoint();assert(count()==0 and H.owned(game,'MOLTRES'),'released ownership survives load')
 local second,reason=A.deliverGift(game,profile.id,'DUPLICATE',{version=1,digest=string.rep('b',64),
  campaignId='sevii-moltres-qa',buildId='isolated-qa',eventId='moltres-b',profileId=profile.id},{boxOnly=true})
 assert(not second and reason=='legend_owned','released gift cannot be replaced')
 local L=K.legacyJourney.archive
 local state,err=L.beginJourney(game.save,{pact='journey',bankPolicy='sealed',itemPolicy='empty',
  runRules=L.safeRunRulesSnapshot(game.save),playerAvatar='BLUE'})
 assert(state,tostring(err));local fresh={party={},boxes={},flags={},modData={}}
 assert(L.seedNewSave(fresh));assert(fresh.modData.kanto_ascendant.hevo_persistent[H.KEY]['146'],'actual Legacy archive retains Moltres')
 E.reset(fresh);assert(not E.completed(fresh,'MOLTRES')and fresh.modData.kanto_ascendant.hevo_persistent[H.KEY]['146'])
 local f=assert(io.open(out..'/moltres-continuity.json','wb'))
 f:write(require('src.link.Json').encode({passed=true,forms= forms,actualGift=true,volcanoPuzzle=true,
  witnessedWithoutCapture=true,oneMoltresAfterReload=true,releaseProtected=true,actualLegacyTransaction=true,
  scope='Isolated QA: actual gift delivery, complete native volcano drill/vent route and Magmar battle/capture, feather interaction, failed-write retry, return to Cinnabar and reload, duplicate-ball/gift refusal and real Legacy beginJourney/seedNewSave. Champion/team/badges/initial Cinnabar position/entry API, Master Ball and removal of old Moltres are fixtures. No native PC release or NG+ UI or balance claim.'}));f:close()
 print('SEVII_NATIVE_MOLTRES_CONTINUITY_PASS');love.event.quit()
end
