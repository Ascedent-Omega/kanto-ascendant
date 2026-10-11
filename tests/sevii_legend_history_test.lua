local callbacks={};local view={owned={},bank={},quarantine={},claimedGifts={}}
local vault={pokemon={}};local bankError,archiveError
local profiles={egg={backendKey='dex:480'},other={backendKey='dex:483'}}
local events={claimed={},giftCodes={claimed={}}}
local H=dofile('sevii_legend_history.lua')({id='kanto_ascendant',events={on=function(_,id,f)callbacks[id]=f end}},
 {dex=function(value)
   local key=type(value)=='table'and value.backendKey or type(value)=='string'and value
   if key=='form:origin'then return 483 end
   return key and tonumber(key:match('^dex:(%d+)$'))
 end},
 {journey={archive={seviiLegendView=function()if archiveError then return nil,archiveError end;return view end}},
  bankBridge=function()return{load=function()return vault,bankError end}end,
  eventArchive=function()return{state=function()return events end,profile=function(id)return profiles[id]end}end})
local g={save={party={},boxes={{}},pokedex={owned={},seen={UXIE=true}},modData={}}}
local n=0;local function check(v,msg)n=n+1;assert(v,msg)end
local function has(id)return H.owned(g,id)end
local function inRun(id)return H.ownedThisRun(g,id)end
check(H.sync(g),'fresh stores readable')
check(not has('UXIE'),'seen alone does not reserve legend')
for id,dex in pairs(H.ids)do check(H.key(id)==tostring(dex)and H.key({backendKey='dex:'..dex})==tostring(dex),'canonical key '..id)end
check(H.key('GIRATINA')==nil and H.key('MOLTRES')=='146','Moltres migrated; Giratina stays reserved')
local egg={species='UXIE',isEgg=true,eggSpecies='UXIE'}
check(not H.record(g,egg),'unissued object cannot reserve species')
g.save.boxes[1]={egg};check(H.record(g,egg),'delivered egg reserved')
g.save.boxes[1]={};check(has('UXIE'),'release cannot recreate egg legend')
check(H.sync(g),'released ownership persists through synchronization')
g.save.pokedex.owned.PALKIA=true;check(H.sync(g)and has('PALKIA'),'old caught dex adopted')
g.save.pokedex.owned={};check(has('PALKIA'),'clearing current dex cannot erase migrated receipt')
g.save.party={{species='HEATRAN'}};check(H.sync(g),'old party ownership adopted')
g.save.party={};check(has('HEATRAN'),'moving old mon away cannot reissue')
view.bank={{mon={species='CRESSELIA'}}};check(has('CRESSELIA'),'legacy bank witness')
vault.pokemon={{species='REGIGIGAS'}};check(has('REGIGIGAS'),'shared vault witness')
view.quarantine={{mon={species='SHAYMIN'}}};check(has('SHAYMIN'),'quarantined existing mon retained as ownership witness')
events.giftCodes.claimed.x={profileId='other'};check(H.sync(g)and has('form:origin'),'claimed gift covers alternative form')
events.giftCodes.claimed={};check(has('DIALGA'),'removed gift receipt cannot erase local lifetime record')
events.giftCodes.pendingReceipt={profileId='egg'}
local fresh={save={party={},boxes={{}},pokedex={owned={}},modData={}}}
local old=g;g=fresh;view={owned={},bank={},quarantine={},claimedGifts={}};vault={pokemon={}}
check(H.sync(g)and not has('UXIE'),'pending gift is not ownership')
view.claimedGifts.x={profileId='egg'};check(H.sync(g)and has('UXIE'),'shared delivered egg receipt adopted')
view.claimedGifts={};vault=nil;bankError='vault_not_found'
local yes,err=has('MANAPHY');check(not yes and not err,'never-created vault is empty')
bankError='corrupt';yes,err=has('MANAPHY');check(not yes and err=='bank_history_unavailable','corrupt vault cannot imply unowned')
bankError='shared_storage_capability_missing';view.bankAuthority='legacy_archive'
yes,err=has('MANAPHY');check(not yes and not err,'old host uses its explicitly authoritative Legacy bank')
view.bankAuthority='shared_vault'
yes,err=has('MANAPHY');check(not yes and err,'migrated shared vault cannot fall back to old bank')
view.bankAuthority=nil;bankError='corrupt'
yes,err=has('UXIE');check(yes and err,'known ownership retained with offline vault')
check(not H.sync(g)and has('UXIE'),'sync retains known evidence while external store unavailable')
vault={pokemon={}};bankError=nil;archiveError='future schema'
yes,err=has('MANAPHY');check(not yes and err=='legacy_history_unavailable','future archive cannot imply unowned')
archiveError=nil
local mon={species='DARKRAI'};g.save.party={mon}
callbacks['pokemon.caught']{game=g,mon=mon};g.save.party={}
check(has('DARKRAI'),'successful native caught event records delivered identity')
local reserve={species='MANAPHY'};g.save.orphaned={mons={reserve}}
check(H.record(g,reserve),'native full-box reserve retains exact delivered mon')
g.save.orphaned=nil;check(has('MANAPHY'),'reclaiming reserve cannot erase ownership')
local serialized=old.save.modData.kanto_ascendant.hevo_persistent.seviiLegendOwned
view.owned=serialized;g.save.modData={}
check(H.sync(g)and has('PALKIA')and has('HEATRAN')and has('DIALGA'),'new save imports lineage history without any Pokemon')
local freshRaid={save={party={},boxes={{}},pokedex={owned={}},modData={kanto_ascendant={rocket_recovery_raids_67={
 captureReceipts={darkrai_dream={species='DARKRAI',incident=1,attempts=2}},
 pendingCaptures={{key='regigigas_power',species='REGIGIGAS'}},captureAttempts={regigigas_power=5}}}}}}
g=freshRaid;view={owned={},bank={},quarantine={},claimedGifts={}};vault={pokemon={}}
check(H.sync(g)and has('DARKRAI'),'old Rocket receipt proves released or traded Darkrai ownership')
check(not has('REGIGIGAS'),'pending rescue and attempts are not captured ownership')
local raid=g.save.modData.kanto_ascendant.rocket_recovery_raids_67
raid.captureReceipts.regigigas_power={species='GENESECT'}
check(not has('REGIGIGAS'),'mismatched receipt cannot reserve unrelated species')
raid.captureReceipts.regigigas_power={species='REGIGIGAS'}
check(H.sync(g)and has('REGIGIGAS'),'old Regigigas Rocket receipt adopted')
raid.captureReceipts={};g.save.modData.kanto_ascendant.rocket_recovery_raids_67=nil
check(has('DARKRAI')and has('REGIGIGAS'),'removing/resetting old raid ledger cannot erase adopted ownership')
g.save.modData.kanto_ascendant.daycare_plus={parents={{mon={species='MANAPHY'}}},reservedEggs={{species='PHIONE',steps=2048}}}
check(H.sync(g)and has('MANAPHY'),'deposited physical special parent is owned')
check(has('PHIONE'),'already produced unclaimed daycare egg counts as ownership')
g.save.modData.kanto_ascendant.daycare_plus=nil
check(has('MANAPHY')and has('PHIONE'),'retrieval or pickup cannot erase adopted nursery ownership')
g.save.daycare={mon={species='CRESSELIA'}}
check(H.sync(g)and has('CRESSELIA'),'old vanilla daycare deposit adopted')
g.save.daycare=nil;check(has('CRESSELIA'),'vanilla retrieval preserves lifetime witness')
g.save.modData.kanto_ascendant.hevo_persistent.seviiLegendOwned='invalid'
yes,err=has('MANAPHY');check(not yes and err=='local_history_unavailable','malformed local history cannot imply unowned')
check(not H.sync(g)and g.save.modData.kanto_ascendant.hevo_persistent.seviiLegendOwned=='invalid','malformed history not overwritten')
g={save={party={},boxes={},modData={},kaHoennEndgameRunEvents67={completed={MOLTRES={captured=false,battleResult='win'}}}}}
view={owned={},bank={},quarantine={},claimedGifts={}};vault={pokemon={}}
check(H.sync(g)and not has('MOLTRES'),'old Moltres KO is not captured ownership')
g.save.kaHoennEndgameRunEvents67.completed.MOLTRES.captured=true
check(H.sync(g)and has('MOLTRES'),'old captured run receipt migrates')
g.save.kaHoennEndgameRunEvents67=nil;check(has('MOLTRES'),'run reset does not erase migrated capture')
g={save={party={},boxes={},modData={kanto_ascendant={hoenn_moltres_volcano_67={caught={captured=true}}}}}}
check(H.sync(g)and has('MOLTRES'),'historical volcano caught receipt migrates without current Pokemon')
g.save.modData.kanto_ascendant.hoenn_moltres_volcano_67=nil;check(has('MOLTRES'),'old owner cleanup cannot erase receipt')
view.owned={['146']=true};g={save={modData={}}}
check(H.sync(g)and has('MOLTRES'),'Moltres history imported from Legacy projection')
for _,id in ipairs{'REGIROCK','REGICE','REGISTEEL'}do
 view={owned={},bank={},quarantine={},claimedGifts={}};g={save={modData={},kaHoennEndgameRunEvents67={completed={[id]={captured=false,battleResult='win'}}}}}
 check(H.sync(g)and not has(id),'old sanctuary KO is not ownership '..id)
 g.save.kaHoennEndgameRunEvents67.completed[id].captured=true
 check(H.sync(g)and has(id),'old sanctuary capture migrated '..id)
 g.save.kaHoennEndgameRunEvents67=nil;check(has(id),'run reset retains guardian '..id)
 g={save={modData={kanto_ascendant={hoenn_research_sanctums_67={caught={[id]={captured=true}}}}}}}
 check(H.sync(g)and has(id),'old sanctuary owner receipt migrated '..id)
 g={save={modData={kanto_ascendant={hevo_persistent={hoennDexOwned={[id]=true}}}}}}
 check(H.sync(g)and has(id),'existing local Hoenn ownership adopted '..id)
 view.hoennDexOwned={[id]=true};g={save={modData={}}}
 check(H.sync(g)and has(id),'old Legacy Hoenn ownership adopted '..id)
 view.hoennDexOwned={};check(has(id),'imported Hoenn witness remains monotonic '..id)
end
for _,id in ipairs{'LATIAS','LATIOS'}do
 view={owned={},bank={},quarantine={},claimedGifts={}}
 local eon={roamers={[id]={dvs={special=7},hp=1,recovery=3}},caught={}}
 g={save={modData={kanto_ascendant={hoenn_roamers_67=eon}}}}
 check(H.sync(g)and not has(id),'roamer identity and KO recovery are not ownership '..id)
 eon.caught[id]={};check(not has(id),'empty old receipt not ownership '..id)
 eon.caught[id]={map='ROUTE_1',level=40}
 check(H.sync(g)and has(id),'stored old roamer receipt migrated '..id)
 eon.caught={};check(has(id),'removed original receipt cannot erase history '..id)
 g={save={modData={kanto_ascendant={hoenn_roamers_67={caught={[id]={adopted=true}}}}}}}
 check(H.sync(g)and has(id),'historical Dex adoption proves ownership '..id)
 view.owned={[tostring(H.ids[id])]=true};g={save={modData={}}}
 check(H.sync(g)and has(id),'canonical Eon ownership enters fresh run '..id)
end
for _,id in ipairs{'KYOGRE','GROUDON','RAYQUAZA','JIRACHI'}do
 view={owned={},bank={},quarantine={},claimedGifts={}};g={save={modData={kanto_ascendant={hevo_persistent={secretUnlocks={['KA_LEGEND_WITNESS_'..id]=true}}}}}}
 check(H.sync(g)and not has(id),'research witness never invents prior ownership '..id)
 g.save.modData.kanto_ascendant.hevo_persistent.secretUnlocks['KA_LEGEND_CAPTURE_'..id]=true
 check(H.sync(g)and has(id),'historical capture seal adopted '..id)
 g.save.modData.kanto_ascendant.hevo_persistent.secretUnlocks={};check(has(id),'clearing old seal cannot erase capture '..id)
 view.secretUnlocks={['KA_LEGEND_CAPTURE_'..id]=true};g={save={modData={}}}
 check(H.sync(g)and has(id),'archive-only old capture seal adopted '..id)
 view.secretUnlocks={};check(has(id),'archive-only witness retained locally '..id)
end
view={owned={},bank={},quarantine={},claimedGifts={}}
g={save={modData={},kaHoennEndgameRunEvents67={completed={DEOXYS={map='KA_HOENN_BIRTH_ISLAND',level=30,captured=false}}}}}
check(H.sync(g)and has('DEOXYS'),'old catch-only Deoxys event with default captured=false migrated')
g.save.kaHoennEndgameRunEvents67=nil;check(has('DEOXYS'),'Deoxys event reset cannot repeat acquisition')
g={save={modData={},kaHoennEndgameRunEvents67={completed={DEOXYS={map='KA_HOENN_BIRTH_ISLAND',level=30,captured=false,battleResult='witnessed'}}}}}
check(H.sync(g)and not has('DEOXYS'),'new research ceremony is not an old capture')
g.save.kaHoennEndgameRunEvents67.completed.DEOXYS.battleResult='win'
check(not has('DEOXYS'),'KO cannot invent Deoxys ownership')
for _,r in ipairs{{'DEOXYS','hoenn_birth_island_67','KA_HOENN_BIRTH_ISLAND'},{'JIRACHI','hoenn_jirachi_finale_67','KA_HOENN_WISH_CHAMBER'}}do
 g={save={modData={kanto_ascendant={[r[2]]={caught={map=r[3],level=30}}}}}}
 check(H.sync(g)and has(r[1]),'old local catch receipt adopted '..r[1])
 g={save={modData={kanto_ascendant={[r[2]]={caught={map=r[3],level=30,captured=true,battleResult='caught'}}}}}}
 check(H.sync(g)and has(r[1]),'explicit new catch receipt adopted '..r[1])
end
for _,id in ipairs{'ARTICUNO','ZAPDOS','MEWTWO','RAIKOU','ENTEI','SUICUNE','LUGIA','HO_OH','CELEBI'}do
 view={owned={},bank={},quarantine={},claimedGifts={}};vault={pokemon={}}
 g={save={party={},boxes={},pokedex={owned={}},modData={kanto_ascendant={postgame={catches={[id]=true}}}}}}
 check(H.sync(g)and has(id),'old postgame capture migrates '..id)
 g.save.modData.kanto_ascendant.postgame=nil
 check(has(id),'NG+ run reset cannot reissue '..id)
 view.owned={[tostring(H.ids[id])]=true};g={save={modData={}}}
 check(H.sync(g)and has(id),'Legacy ownership reaches new run '..id)
end
view={owned={},bank={},quarantine={},claimedGifts={}};vault={pokemon={}}
g={save={party={},boxes={},pokedex={owned={}},modData={kanto_ascendant={postgame={catches={ARTICUNO=false}}}}}}
check(H.sync(g)and not has('ARTICUNO'),'failed encounter does not invent bird ownership')
g.save.modData.kanto_ascendant.postgame.catches.ARTICUNO=true
check(H.sync(g)and has('ARTICUNO'),'successful old static catch adopted')
g={save={party={},boxes={},pokedex={owned={}},modData={}}}
events.giftCodes.claimed.bird={profileId='bird'};profiles.bird={species='ZAPDOS'}
check(H.sync(g)and has('ZAPDOS'),'delivered old bird gift is ownership evidence')
events.giftCodes.claimed={};check(has('ZAPDOS'),'clearing gift ledger cannot create another bird')
g={save={party={},boxes={},pokedex={owned={}},modData={}}}
view.bank={{mon={species='MEW'}}}
check(H.sync(g)and has('MEW'),'old bank Mew is protected without current party')
check(inRun('MEW'),'an original-run upgrade treats prior ownership as spent')
g.save={party={},boxes={},pokedex={owned={}},modData={kanto_ascendant={
  legacy_journey={runId='ng-one'},hevo_persistent={seviiLegendOwned={['151']=true}}}}}
check(has('MEW')and not inRun('MEW'),'NG+ preserves lifetime history but opens its new encounter')
local newMew={species='MEW'};g.save.party={newMew}
check(H.record(g,newMew)and inRun('MEW'),'new run capture closes only that run')
g.save.modData.kanto_ascendant.legacy_journey.runId='ng-two';g.save.party={}
check(has('MEW')and not inRun('MEW'),'next NG+ run can encounter the legend again')
print('PASS Sevii legend history: '..n..' checks')
