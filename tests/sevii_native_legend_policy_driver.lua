return function(game)
  io.stdout:setvbuf('no')
  local root=assert(os.getenv('SEVII_KASC_ROOT'));local out=assert(os.getenv('SEVII_QA_OUTPUT'))
  local U=require('tests.drivers.util');local Q=dofile(root..'/tests/habitat_playthrough/drivers/common.lua')(game)
  local K=game.mods.exports.kanto_ascendant;local S=assert(K.seviiExpedition);local P=assert(S.legendPolicy)
  local A=K.eventArchive;local Json=require('src.link.Json');local Pokemon=require('src.pokemon.Pokemon')
  game:startNewGame{intro=false};game.mods.modOptions.kanto_ascendant.living_world_enabled=false
  game.save.flags.EVENT_BEAT_CHAMPION_RIVAL=true
  game.save.flags.EVENT_FOLLOWED_OAK_INTO_LAB=true;game.save.flags.EVENT_GOT_STARTER=true
  game.save.party={Pokemon.new(game.data,'BLASTOISE',70)}
  S.persist({version=1,stage=3,chapterOneComplete=true,samples={heat=true,drift=true}})
  U.teleport(game,S.harbors[1],8,5,'right');Q.settle();K.generationRules.resolve(game)
  local blocked={}
  for _,campaign in ipairs(K.giftCodeCatalog.campaigns)do
    for _,event in ipairs(campaign.events)do
      local profile=A.profile(event.profileId)
      if P.dex(profile)==487 then
        assert(A.acquisitionAllowed(game,profile)==false)
        local receipt={version=1,digest=event.digests[1],campaignId=campaign.id,
          buildId=campaign.buildId,eventId=event.id,profileId=event.profileId}
        local mon,why=A.deliverGift(game,profile.id,'SEVII QA',receipt)
        assert(not mon and why=='story_reserved','direct archive delivery must block '..profile.id)
        blocked[#blocked+1]={profile=profile.id,key=profile.backendKey,species=profile.species}
      end
    end
  end
  assert(#blocked>=3,'base, egg and shiny egg Giratina profiles covered')
  local forms=0
  for key,row in pairs(K.backendNationalCatalog67.entries)do if row.nationalDex==487 then
    assert(not P.acquisitionAllowed(game,{backendKey=key}),'all canonical Giratina forms reserved')
    forms=forms+1
  end end
  assert(forms>=2,'base and Origin catalog identities covered')
  local gir=assert(K.backendGiftSpecies67.byKey['dex:487'])
  local Battle=require('src.battle.BattleState');local Items=require('src.inventory.ItemEffects')
  for _,species in ipairs({gir,'MOLTRES'})do
    local battle=Battle.newWild(game,species,70,{randomizerProtected=true})
    assert(battle.enemy.mon.species==species,'test target identity')
    game.save.inventory.MASTER_BALL=2
    local result=Items.use(game.data,game.save,'MASTER_BALL',nil,battle)
    assert(result=='failed'and game.save.inventory.MASTER_BALL==2,'blocked before Ball consumption')
    assert(battle:catchAttempt('MASTER_BALL')==false,'native catch hook blocks even Master Ball')
  end
  -- The first authorized Kanto Moltres path and ordinary Sevii species remain
  -- outside this area's exclusion. This is not an NG+ uniqueness proof.
  U.teleport(game,'VERMILION_CITY',18,12,'down');Q.settle()
  assert(P.captureAllowed(game,'MOLTRES'))
  assert(not P.captureAllowed(game,gir))
  U.teleport(game,S.harbors[1],8,5,'right');Q.settle()
  assert(P.captureAllowed(game,'WINGULL'))
  local ordinary=Battle.newWild(game,'WINGULL',30,{randomizerProtected=true})
  assert(Items.use(game.data,game.save,'MASTER_BALL',nil,ordinary)=='ball')
  assert(ordinary:catchAttempt('MASTER_BALL')==true,'ordinary native catch formula unchanged')
  -- Exercise redemption with an isolated diagnostic catalog/hash adapter.
  -- No production plaintext codes or shared player archive are accessed.
  local digest=string.rep('a',64);local other=string.rep('b',64)
  local profile=blocked[1].profile
  local catalog={schema='ka-offline-gift-code-catalog/v1',version=1,campaigns={{
    id='sevii_qa',buildId='sevii-qa',version=1,status='active',testOnly=true,events={
      {id='reserved',profileId=profile,version=1,digests={digest}},
      {id='ordinary',profileId='university_magikarp',version=1,digests={other}},
    }}}}
  local writes=0;local shared={}
  local dummy={path='mods/kanto_ascendant',read=function(_,path)return love.filesystem.read('mods/kanto_ascendant/'..path)end,
    hooks={wrap=function()end},events={on=function()end}}
  local now=100000
  local G=dofile(root..'/gift_codes.lua')(dummy,{catalog=catalog,eventArchive=A,enabled=function()return true end,
    allowTestFixtures=true,sha256=function(code)return code=='AAAAAAAA'and digest or other end,
    now=function()now=now+3;return now end,
    sharedArchive={storageHasArchive=function()return true end,load=function()return shared end,
      write=function(value)writes=writes+1;shared=value;return true end}})
  assert(G.catalogReady(),G.catalogError())
  local receipt={version=1,digest=digest,campaignId='sevii_qa',buildId='sevii-qa',eventId='reserved',profileId=profile}
  local before=#game.save.party
  assert(G.redeem(game,'AAAAAAAA').status=='story_reserved')
  assert(writes==0 and #game.save.party==before and not G.state().pendingReceipt,'new rejection never reserves a code')
  local state=A.state();state.giftCodes.pendingReceipt=receipt;A.persist(state)
  local writeSave=game.writeSave;game.writeSave=function()return false end
  assert(G.claimPending(game).status=='state_error','failed suspension save reported')
  game.writeSave=writeSave
  assert(G.state().pendingReceipt and not G.state().suspended[digest]and writes==0,'failed save retains original reservation')
  assert(G.claimPending(game).status=='story_reserved')
  assert(not G.state().pendingReceipt and G.state().suspended[digest]and writes==0,'old pending retained without shared archive mutation')
  assert(game:writeSave());game:restoreSave(assert(require('src.core.SaveData').load('red')));Q.settle()
  assert(G.state().suspended[digest]and not G.state().pendingReceipt,'suspended receipt survives reload')
  local result=G.redeem(game,'BBBBBBBB')
  assert(result.status=='box','unrelated ordinary gift still delivered: '..tostring(result.status))
  assert(A.findGiftReceipt(game,other),'ordinary gift is in real PC')
  -- A Pokemon owned before this expansion is not deleted or stripped of
  -- its validated archive identity. Use a copied policy-free delivery owner
  -- only to construct that historical fixture, then restore the real policy.
  local savedAllowed=P.acquisitionAllowed
  P.acquisitionAllowed=function()return true end
  local old=A.deliverGift(game,profile,'PRE-SEVII FIXTURE',receipt)
  P.acquisitionAllowed=savedAllowed
  assert(old,'historical fixture delivered')
  assert(A.battleCompatibleGift(old),'old gift compatibility retained')
  local count=#game.save.party
  assert(A.deliverGift(game,profile,'RETRY',receipt)==old and #game.save.party==count,'existing receipt recovery never duplicates')
  assert(G.reconcile(game),'existing delivered reservation recovery')
  assert(G.state().claimed[digest]and not G.state().suspended[digest],'recovered old delivery reconciled')
  assert(game:writeSave());game:restoreSave(assert(require('src.core.SaveData').load('red')));Q.settle()
  local saved=A.findGiftReceipt(game,digest);assert(saved and A.battleCompatibleGift(saved),'historical owned Giratina survives reload')
  local f=assert(io.open(out..'/sevii-legend-policy-audit.json','wb'))
  f:write(Json.encode({blockedProfiles=blocked,canonicalForms=forms,passed=true,ordinaryGiftPreserved=true,
    priorOwnedPreserved=true,ordinaryCapturePreserved=true,failedSavePreservesReservation=true}));f:close()
  print('SEVII_LEGEND_POLICY_PASS',#blocked,'Giratina profiles; direct gifts, code preflight, pending retention, ordinary PC delivery, historical ownership, Master Ball guard')
  love.event.quit()
end
