return function(game)
  io.stdout:setvbuf('no')
  local root=assert(os.getenv('SEVII_KASC_ROOT'));local out=assert(os.getenv('SEVII_QA_OUTPUT'))
  local U=require('tests.drivers.util');local Q=dofile(root..'/tests/habitat_playthrough/drivers/common.lua')(game)
  local K=game.mods.exports.kanto_ascendant;local P=K.seviiExpedition.legendPolicy;local H=P.history
  local A=K.eventArchive;local L=K.legacyJourney.archive;local Json=require('src.link.Json')
  game:startNewGame{intro=false};game.mods.modOptions.kanto_ascendant.living_world_enabled=false
  game.save.flags.EVENT_BEAT_CHAMPION_RIVAL=true
  game.save.flags.EVENT_FOLLOWED_OAK_INTO_LAB=true;game.save.flags.EVENT_GOT_STARTER=true
  game.save.party={require('src.pokemon.Pokemon').new(game.data,'BLASTOISE',70)}
  assert(K.beyondKanto.activate(game,{decision='qa-legend-history-fixture'}))
  U.teleport(game,'VERMILION_CITY',18,12,'down');Q.settle()
  assert(game:writeSave())
  local vault,vaultWhy=K.legacyBankBridge.load(game)
  print('SEVII_HISTORY_BANK_PROBE',tostring(vault~=nil),tostring(vaultWhy))
  local ready,why=H.sync(game)
  assert(ready,'fresh history readable: '..tostring(why))
  local function profile(dex,egg)
    for _,c in ipairs(K.giftCodeCatalog.campaigns)do for _,e in ipairs(c.events)do
      local p=A.profile(e.profileId)
      if P.dex(p)==dex and(p.deliveryKind=='egg')==egg then return p end
    end end
    error('missing test profile '..dex)
  end
  local function receipt(p,ch)return {version=1,digest=string.rep(ch,64),
    campaignId='sevii-history-qa',buildId='isolated-qa',eventId='history-'..ch,profileId=p.id}end
  local function remove(mon)
    for _,list in ipairs({game.save.party,unpack(game.save.boxes)})do
      for i=#list,1,-1 do if list[i]==mon then table.remove(list,i);return end end
    end
    error('delivered test mon missing')
  end
  local egg=profile(480,true);local eggReceipt=receipt(egg,'c')
  assert(A.acquisitionAllowed(game,egg),'first legend gift permitted')
  local mon=assert(A.deliverGift(game,egg.id,'HISTORY QA',eggReceipt,{boxOnly=true}))
  assert(mon.isEgg and H.owned(game,egg),'actual egg delivery records ownership')
  assert(A.deliverGift(game,egg.id,'RETRY',eggReceipt)==mon,'same gift receipt recovers original')
  remove(mon) -- isolated release fixture; no PC-menu claim
  local first,reason=A.deliverGift(game,profile(480,false).id,'DUPLICATE',receipt(profile(480,false),'d'))
  assert(not first and reason=='legend_owned','released egg cannot be replaced by ordinary gift')
  assert(game:writeSave());game:restoreSave(assert(require('src.core.SaveData').load('red')));Q.settle()
  assert(H.owned(game,egg),'released legend remains recorded after actual reload')
  print('SEVII_HISTORY_GIFT_RELEASE_RELOAD_PASS')
  -- Delivery, mon and history are all local until the same save commits.
  local dialga=profile(483,false);local r=receipt(dialga,'e')
  local oldWrite=game.writeSave;game.writeSave=function()return false end
  local pending=assert(A.deliverGift(game,dialga.id,'FAILED SAVE QA',r,{boxOnly=true}))
  assert(H.owned(game,dialga)and game:writeSave()==false)
  game.writeSave=oldWrite
  game:restoreSave(assert(require('src.core.SaveData').load('red')));Q.settle()
  assert(not H.owned(game,dialga),'failed save creates no durable ownership without Pokemon')
  local delivered=assert(A.deliverGift(game,dialga.id,'RETRY AFTER LOAD',r,{boxOnly=true}))
  local forms=0
  for key,row in pairs(K.backendNationalCatalog67.entries)do if row.nationalDex==483 then
    assert(H.owned(game,{backendKey=key}),'every canonical Dialga form shares history')
    forms=forms+1
  end end
  assert(forms>=2,'alternative canonical forms covered')
  remove(delivered);assert(game:writeSave())
  print('SEVII_HISTORY_FAILED_SAVE_RETRY_PASS')
  -- Actual catch pipeline outside Sevii; new island encounter owners are a
  -- separate task. Random encounter construction and Master Ball are fixtures.
  for _,species in ipairs({assert(K.backendGiftSpecies67.byKey['dex:485']),'MOLTRES'})do
  assert(P.captureAllowed(game,species),'first unowned catch permitted outside restricted island pool')
  local b=require('src.battle.BattleState').newWild(game,species,50,{randomizerProtected=true})
  b.onFinish=function(result)game.overworld:afterBattle(result,b)end
  game.overworld:pushBattle(b)
  for _=1,1800 do if game.stack:top()==b and b.phase=='menu'then break end;Q.tap('a')end
  Q.catch(species,true,'down');Q.settle()
  assert(H.owned(game,species),'actual native catch records lineage ownership')
  local duplicate=require('src.battle.BattleState').newWild(game,species,50,{randomizerProtected=true})
  game.save.inventory.MASTER_BALL=2
  assert(require('src.inventory.ItemEffects').use(game.data,game.save,'MASTER_BALL',nil,duplicate)=='failed')
  assert(game.save.inventory.MASTER_BALL==2 and duplicate:catchAttempt('MASTER_BALL')==false,'duplicate catch refused before ball use and by final catch hook')
  assert(game:writeSave());game:restoreSave(assert(require('src.core.SaveData').load('red')));Q.settle()
  print('SEVII_HISTORY_NATIVE_CAPTURE_PASS',species)
  end
  -- Real archive transaction and fresh-save seeding, without carrying a
  -- legendary Pokemon. This is a controller/serialization test, not NG+ UI.
  game.save.boxes={};for i=1,12 do game.save.boxes[i]={}end
  game.save.party={game.save.party[1]}
  game.save.pokedex.owned={BLASTOISE=true}
  assert(game:writeSave())
  local state,err=L.beginJourney(game.save,{pact='journey',bankPolicy='sealed',itemPolicy='empty',
    runRules=L.safeRunRulesSnapshot(game.save),playerAvatar='BLUE'})
  assert(state,'real Legacy transaction: '..tostring(err))
  local fresh={party={},boxes={},flags={},modData={}}
  local seeded,seedErr=L.seedNewSave(fresh);assert(seeded,'fresh Legacy seed: '..tostring(seedErr))
  local history=fresh.modData.kanto_ascendant.hevo_persistent[H.KEY]
  assert(history['480']and history['483']and history['485']and history['146'],'history crosses real archive into fresh save')
  local raw=Json.decode(Json.encode(fresh))
  assert(raw.modData.kanto_ascendant.hevo_persistent[H.KEY]['485'],'fresh seed history serializes')
  local f=assert(io.open(out..'/legend-history.json','wb'))
  f:write(Json.encode({passed=true,eggRelease=true,failedSaveRetry=true,nativeCapture=true,nativeCapturedSpecies={'HEATRAN','MOLTRES'},
    actualLegacyTransaction=true,freshSeedOwned=history,
    scope='Isolated QA. Real gift delivery/catch/storage/reload and Legacy beginJourney/seedNewSave APIs. Release and initial champion/team/encounter/ball state are fixtures; no claim of native PC release or NG+ UI coverage.'}));f:close()
  print('SEVII_LEGEND_HISTORY_PASS');love.event.quit()
end
