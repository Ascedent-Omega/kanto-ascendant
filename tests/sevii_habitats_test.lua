package.path=assert(os.getenv('KASC_ENGINE'))..'/?.lua;'..package.path
local J=dofile('starter_habitat_json.lua')
local function read(path)local f=assert(io.open(path,'rb'));local s=f:read('*a');f:close();return s end
local plan=J.decode(read('assets/sevii_local/habitats.json'))
local bundle=J.decode(read('assets/sevii_local/bundle.json'))
local required=J.decode(read('SEVII_SPECIES_REQUIREMENTS.json'))
local S={maps={},unlocked=function(g)return g.save.flags.EVENT_BEAT_CHAMPION_RIVAL==true end}
for _,m in ipairs(bundle.maps)do S.maps[m.id]=m end
local game={save={flags={EVENT_BEAT_CHAMPION_RIVAL=true}},data={pokemon={},encounters={}},epoch=4}
local B={byKey={},bySpecies={},spriteContentPaths=function(id)return {'fixture/'..id..'.png'}end}
for _,r in ipairs(required.ordinary)do
  local id='CANONICAL_'..r.dex
  B.byKey[r.key]=id;B.bySpecies[id]=r.key
  game.data.pokemon[id]={id=id,dex=r.dex,sourceDex=r.dex,originGeneration=r.generation}
end
local hooks={};local hoennOn=true;local unreadable;local beyond=true
local timeMode,fieldWeather='day','clear'
local mod={path='.',hooks={wrap=function(_,key,fn)hooks[key]=fn end},read=function(_,path)
  if path:match('^fixture/')then return path~=unreadable and '\137PNG\r\n\26\nfixture'or nil end
  return read(path)
end}
local options={json=J,backendSpecies=function()return B end,
  timeMode=function()return timeMode end,fieldWeather=function()return fieldWeather end,
  beyondKanto={peekIsActive=function()return beyond end},
  classicArt={['387']={front='fixture/turtwig-classic.png',back='fixture/turtwig-rear.png'}},
  fieldAccess={encountersEnabled=function()return hoennOn end,ordinaryAllowed=function()error('must not apply character pack gate')end},
  generationRules={peekSpeciesAvailable=function(g,id,def)return def.originGeneration<=g.epoch end}}
local E=dofile('sevii_encounters.lua')(mod,S,options);E.game=game
local checks=0;local function check(v,why)checks=checks+1;assert(v,why)end
local Encounter=require('src.world.Encounter')
local function refresh()
  for id in pairs(S.maps)do game.data.encounters[id]=E.encounters(game,id)end
end
refresh()
check(E.coverage(game).available==218,'complete ordinary coverage')
beyond=false
check(E.coverage(game).available==0,'sealed Kanto save cannot spawn expansion species')
local allowed,reason=E.availability(game,E.bySpecies.FEEBAS.row)
check(not allowed and reason=='beyond-kanto-sealed','guide explains sealed boundary')
beyond=true
local found={}
for map,groups in pairs(game.data.encounters)do
  for terrain,pool in pairs(groups)do if type(pool)=='table'and pool.rate and pool.rate>0 then
    check(#pool.slots==10,'native slot cardinality')
    for roll=0,255 do
      local n=0;local mon=Encounter.roll({grass=pool},function()n=n+1;return n==1 and 0 or roll end)
      check(mon~=nil,'native probability bucket must yield a species')
      found[mon.species]=true
    end
  end end
end
for _,row in ipairs(required.ordinary)do check(found[B.byKey[row.key]],'actually rollable '..row.id)end
for _,character in ipairs{'RED','GREEN','BLUE'}do
  game.character=character;refresh()
  for _,id in ipairs(required.characters[character].missingSpecies)do
    local target=assert(E.bySpecies[id]);local species=B.byKey[target.row.key]
    local pool=game.data.encounters[target.pool.map][target.pool.terrain=='water'and'water'or'grass']
    local present=false;for _,slot in ipairs(pool.slots)do present=present or slot.species==species end
    check(present,character..' missing-family acquisition '..id)
  end
end
check(not E.bySpecies.GIRATINA and not E.bySpecies.MOLTRES,'no legendary additions')
game.epoch=3;refresh();check(E.coverage(game).available==125,'Gen3 selection excludes Gen4')
game.epoch=1;refresh();check(E.coverage(game).available==0,'explicit Gen1 selection respected')
game.epoch=4;hoennOn=false;refresh();check(E.coverage(game).available==93,'Hoenn content switch respected')
hoennOn=true;game.save.flags.EVENT_BEAT_CHAMPION_RIVAL=false;refresh();check(E.coverage(game).available==0,'League gate')
game.save.flags.EVENT_BEAT_CHAMPION_RIVAL=true;refresh()
local pool=plan.pools[1];local terrain=pool.terrain;local definition=game.data.encounters[pool.map]
local ctx={mapId=pool.map,terrain=terrain};local slot=definition[terrain=='water'and'water'or'grass'].slots[1]
local accepted=hooks['encounter.roll'](function()return {species=slot.species,level=slot.level}end,definition,ctx)
check(accepted and accepted.kaProtected,'ordinary roll protection')
check(not hooks['encounter.roll'](function()return{species='MOLTRES',level=60}end,definition,ctx),'foreign forced roll rejected')
check(hooks['encounter.species'](function()error('foreign substitution executed')end,accepted,ctx)==accepted,'authored identity preserved')
beyond=false
check(not hooks['encounter.species'](function()error('stale substitution')end,accepted,ctx),'sealed boundary rejects previously cached slots')
beyond=true;game.epoch=1
check(not hooks['encounter.species'](function()error('stale substitution')end,accepted,ctx),'profile change rejects previously cached slots')
game.epoch=4
for mid,pools in pairs(E.byMap)do if pools.grass and pools.grass.terrain=='grass'then
  check(not hooks['encounter.roll'](function()error('outdoor path rolled as indoor')end,game.data.encounters[mid],{mapId=mid,terrain='indoor'}),'outdoor path safe')
end end
local untouched={species='PIDGEY',level=3}
check(hooks['encounter.species'](function()return untouched end,{}, {mapId='ROUTE_1',terrain='grass'})==untouched,'Kanto hook unchanged')
unreadable='fixture/CANONICAL_442.png'
local missing=dofile('sevii_encounters.lua')(mod,S,options)
check(missing.coverage(game).available==217,'missing graphics block exactly that species')
unreadable='fixture/turtwig-classic.png'
local missingClassic=dofile('sevii_encounters.lua')(mod,S,options)
check(missingClassic.coverage(game).available==217,'missing classic card blocks padded starter fallback')
check(not missingClassic.availability(game,missingClassic.bySpecies.TURTWIG.row),'starter needs correctly placed battle card')
unreadable=nil
B.bySpecies.CANONICAL_442='dex:487'
check(not E.availability(game,E.bySpecies.SPIRITOMB.row),'canonical identity mismatch rejected')
B.bySpecies.CANONICAL_442='dex:442'
local function rareSlots(id)
  local target=E.bySpecies[id];local pool=target.pool
  local encounter=E.encounters(game,pool.map)[pool.terrain=='water'and'water'or'grass']
  local count=0;for _,slot in ipairs(encounter.slots)do
    if slot.species==B.byKey[target.row.key]then count=count+1 end
  end
  return count,encounter.rate,pool.map
end
local spiritDay=rareSlots('SPIRITOMB')
timeMode='night';local spiritNight=rareSlots('SPIRITOMB')
check(spiritDay==1 and spiritNight>=4,'Spiritomb stays rare but improves at night')
timeMode='day'
local feebasDry=rareSlots('FEEBAS')
fieldWeather='rain';local feebasRain=rareSlots('FEEBAS')
check(feebasDry==1 and feebasRain>feebasDry,'Feebas responds to real field rain')
fieldWeather='clear';local _,castformDry=rareSlots('CASTFORM')
fieldWeather='rain';local _,castformRain,castformMap=rareSlots('CASTFORM')
check(castformDry==3 and castformRain==18,'single-species Castform area has weather-dependent rate')
local liveRate
local active=dofile('sevii_encounters.lua')(mod,S,options);active.game=game
hooks['encounter.roll'](function(def)liveRate=def.grass.rate;return nil end,
  game.data.encounters[castformMap],{mapId=castformMap,terrain='grass'})
check(liveRate==18,'weather change applies to the next native roll without a map reload')
fieldWeather='clear'
check(E.coverage(game).available==218,'all rare species remain catchable outside peak windows')
local evidence=dofile('generation_evidence.lua')({id='kanto_ascendant'})
local save={flags={},party={},modData={kanto_ascendant={sevii_expedition_v1={stage=3,chapterOneComplete=true,samples={drift=true,heat=true}}}}}
check(evidence.collect({data={pokemon={}}},save).epoch==1,'Sevii receipts alone do not bypass League')
save.flags.EVENT_BEAT_CHAMPION_RIVAL=true
check(evidence.collect({data={pokemon={}}},save).epoch==4,'Sevii investigation advances AUTO to Gen4')
save.modData.kanto_ascendant.sevii_expedition_v1.samples.heat=false
check(evidence.collect({data={pokemon={}}},save).epoch==3,'incomplete investigation only Gen3')
save.modData.kanto_ascendant.sevii_expedition_v1.stage='corrupt'
check(evidence.collect({data={pokemon={}}},save).epoch==1,'invalid stage is not evidence')
-- The native roll consumes definition.grass for Surf as well: the host
-- step controller packs the map water table into that native slot.
local waterPools=0
for _,pool in ipairs(plan.pools)do if pool.terrain=='water'then
  local shared=E.encounters(game,pool.map);local sharedGrass=shared.grass
  local delivered
  local result=hooks['encounter.roll'](function(def)
    delivered=def
    return Encounter.roll(def,function()return 0 end)
  end,{grass=shared.water},{mapId=pool.map,terrain='water'})
  check(result and result.species==shared.water.slots[1].species,'native Surf slot supplied '..pool.map)
  check(delivered.grass==delivered.water,'owned water packed into native grass slot '..pool.map)
  check(shared.grass==sharedGrass,'shared source definition retained '..pool.map)
  waterPools=waterPools+1
end end
check(waterPools>0,'owned Surf pools covered')
local kantoWater={grass={rate=18,slots={{species='MAGIKARP',level=5}}}}
local forwarded
hooks['encounter.roll'](function(def)forwarded=def;return nil end,kantoWater,{mapId='ROUTE_20',terrain='water'})
check(forwarded==kantoWater,'Kanto native water definition forwarded unchanged')
print('PASS Sevii habitat coverage: '..checks..' checks; 218 native-rollable targets, all three character gaps')
