local root=assert(os.getenv('KASC_ENGINE'))
package.path=root..'/?.lua;'..package.path
local Map=require('src.world.Map')
local J=dofile('starter_habitat_json.lua')
local dataRoot=assert(os.getenv('KASC_NATIVE_DATA'))
local function copy(v)if type(v)~='table'then return v end;local t={};for k,x in pairs(v)do t[k]=copy(x)end;return t end
local tables={maps=dofile(dataRoot..'/maps.lua'),tilesets=dofile(dataRoot..'/tilesets.lua'),
  encounters={},map_scripts={},map_songs={},trainers=dofile(root..'/data/generated/trainers.lua')}
local nativeSprites=dofile(dataRoot..'/sprites.lua')
local events,stored,warps={},{},{}
local content={}
local fieldPatch
local ledgePatch
local flyWarpsPatch,flyOrderPatch
content.field={patch=function(_,id,rows)
  if id=='waterTilesets'then fieldPatch=rows
  elseif id=='ledges'then ledgePatch=rows
  elseif id=='flyWarps'then flyWarpsPatch=rows
  elseif id=='flyOrder'then flyOrderPatch=rows
  else error(id)end
end}
for name,rows in pairs(tables)do
  content[name]={get=function(_,id)return rows[id]end,each=function()return pairs(rows)end,
    register=function(_,id,row)
      assert(not rows[id],'duplicate '..id);rows[id]=row
    end,
    patch=function(_,id,patch)for k,v in pairs(patch)do rows[id][k]=v end end}
end
local checks=0
local function check(v,m)checks=checks+1;assert(v,m)end
local allowHoenn=true
local hoennOpen=true
local hoennOn=true
local legacy=false
local legacyAllowed=false
local inherited={}
local species={bySpecies={WINGULL={assets={front='missing-wingull.png'}},NUMEL={assets={}}}}
local mod={path='.',content=content,
  read=function(_,path)local f=io.open(path,'rb');if not f then return end;local s=f:read('*a');f:close();return s end,
  save={get=function(_,k)return copy(stored[k])end,set=function(_,k,v)stored[k]=copy(v);return true end},
  world={warpTo=function(_,...)warps[#warps+1]={...};return true end},
  hooks={wrap=function()end},
  events={on=function(_,id,f)events[id]=f end}}
local cityBefore=copy(tables.maps.VERMILION_CITY)
local wandererMaps={}
local S=dofile('sevii_expedition.lua')(mod,{json=J,hoennSpecies=species,encounters=dofile('sevii_encounters.lua'),flight=dofile('sevii_flight.lua'),guide=dofile('sevii_guide.lua'),population=dofile('sevii_population.lua'),trainers=dofile('sevii_trainers.lua'),tower=dofile('sevii_tower.lua'),mysteries=dofile('sevii_mysteries.lua'),specialEncounters=dofile('sevii_special_encounters.lua'),lakeGuardians=dofile('sevii_lake_guardians.lua'),dreams=dofile('sevii_dreams.lua'),sleepingGiant=dofile('sevii_sleeping_giant.lua'),eonRoaming=dofile('sevii_eon_roaming.lua'),hoennRoamers={setExpansion=function()end},legacyWanderers={registerOutdoorMaps=function(rows)for _,row in ipairs(rows)do if row.outdoor then wandererMaps[row.id]=true end end end},tidalReturn=dofile('sevii_tidal_return.lua'),garden=dofile('sevii_garden.lua'),timeSpace=dofile('sevii_time_space.lua'),sevenTestimonies=dofile('sevii_seven_testimonies.lua'),chapters=dofile('sevii_chapters.lua'),forestRescue=dofile('sevii_forest_rescue.lua'),iceMemory=dofile('sevii_ice_memory.lua'),stationMission=dofile('sevii_station.lua'),ruinsMission=dofile('sevii_ruins.lua'),finaleMission=dofile('sevii_finale.lua'),apparition=dofile('sevii_apparition.lua'),fieldAccess={
  isLegacy=function()return legacy end,legacyFamilies=function()return inherited end,
  encountersEnabled=function()return hoennOn end,normalEnabled=function()return hoennOpen end,
  ordinaryAllowed=function()return legacyAllowed end},generationRules={
  peekSpeciesAvailable=function(_,name)return allowHoenn or name=='TENTACOOL'or name=='ODDISH'or name=='MACHOP'or name=='PONYTA'end}})
check(S.available,'expedition registered')
local fakeVoxel={mods={exports={VOXEL_ASCENDANT={lib={require=function()
  return{doubleActorLayoutVersion=1,doubleTextureCaptureVersion=1,doublePlatformVersion=1}
end}}}}}
check(not S.doubleVisualReady(fakeVoxel),'private VASC facade cannot authorize doubles')
local receipt={schema='kasc.sevii-double-visual/v1',ready=true,
  modes={MAP=true,DISCS=true,ARENA=true}}
fakeVoxel.mods.exports.VOXEL_ASCENDANT.capabilities={seviiDoubleBattle=receipt}
check(not S.doubleVisualReady(fakeVoxel),'missing Terrarium keeps singles')
receipt.modes.TERRARIUM=true;receipt.ready=1
check(not S.doubleVisualReady(fakeVoxel),'non-boolean readiness keeps singles')
receipt.ready=true
check(S.doubleVisualReady(fakeVoxel),'all four public visual modes acknowledged')
check(not S.flight.chartUnlocked(),'Sevii map hidden before first arrival')
check(#S.flight.points==7 and #flyOrderPatch.__append==7,
  'seven Sevii Fly destinations registered')
for island,point in ipairs(S.flight.points)do
  check(flyWarpsPatch[point.map].x==point.x
    and flyWarpsPatch[point.map].y==point.y
    and S.maps[point.map].outdoor and S.walkable(point.map,point.x,point.y),
    'safe outdoor Fly landing '..island)
  check(not Map.isFlyTown(S.maps[point.map]),
    'island Fly locked before station chapter '..island)
end
check(wandererMaps[S.ONE]and not wandererMaps[S.CENTER],
  'Legacy wanderers gain outdoor Sevii maps without Pokemon Centers')
local kantoCount=0;for _ in pairs(S.eonRoaming.kanto)do kantoCount=kantoCount+1 end
check(kantoCount==45,'all 45 base Kanto outdoor maps, including forest, Safari, docks and roofs')
for _,id in ipairs{'PALLET_TOWN','VERMILION_CITY','ROUTE_19','ROUTE_20','ROUTE_21','ROUTE_23','INDIGO_PLATEAU','VIRIDIAN_FOREST','SAFARI_ZONE_CENTER','SS_ANNE_BOW','CELADON_MART_ROOF'}do check(S.eonRoaming.maps[id],'expanded Kanto surface '..id)end
for _,id in ipairs{'MT_MOON_1F','SEAFOAM_ISLANDS_B1F','CELADON_MANSION_ROOF_HOUSE','VERMILION_POKECENTER','SAFARI_ZONE_SECRET_HOUSE','VIRIDIAN_FOREST_SOUTH_GATE','SS_ANNE_3F'}do check(not S.eonRoaming.maps[id],'indoor or cave excluded '..id)end
check(S.eonRoaming.maps[S.ONE]and not S.eonRoaming.maps[S.CENTER],'Eon outdoor/Center classification')
for id,m in pairs(S.maps)do
 if m.kaSeviiSource:find('Cave',1,true)or m.kaSeviiSource:find('DottedHole',1,true)or m.kaSeviiSource:find('House',1,true)then check(not S.eonRoaming.maps[id],'no cave/house roamer '..id)end
end
check(not S.threeHorizons and not S.specialEncounters.rows.GROUDON and not S.specialEncounters.rows.KYOGRE and not S.specialEncounters.rows.RAYQUAZA,'existing character portals retain sole authored access')
check(#S.trainers.rows==14,'fourteen optional island trainers')
check(#S.tower.rows==8 and #S.trainers.allRows==22,'eight additional tower trainers')
local counts={}
for _,row in ipairs(S.trainers.rows)do
 local island=S.maps[row.map].kaSeviiIsland;counts[island]=(counts[island]or 0)+1
 for _,d in ipairs{{0,1},{1,0},{0,-1},{-1,0}}do check(S.walkable(row.map,row.x+d[1],row.y+d[2]),'trainer has four free approaches '..row.id)end
end
for island=1,7 do check(counts[island]==2,'two trainers on island '..island)end
check(S.story.antagonist=='GIRATINA' and S.story.catchable==false
  and S.story.recurring and S.story.finale=='LOCAL_RIFT_SEALED','Giratina continuity contract')
local waterSet={};for _,id in ipairs(fieldPatch or{})do waterSet[id]=true end
for _,id in ipairs{'KA_SEVII_ONE','KA_SEVII_KINDLE','KA_SEVII_KINDLE_NORTH','KA_SEVII_TREASURE'}do
  check(waterSet[S.maps[id].tileset],'Surf supported on '..id)
end
local function runtime(id)return Map.new(tables.maps[id],tables.tilesets[tables.maps[id].tileset])end
for island,prefix in ipairs{'One','Two','Three','Four','Five','Six','Seven'}do
  local source=prefix..'Island_PokemonCenter_1F'
  local id=assert(S.location(source,0,0))
  local x=island==1 and 5 or 7
  local map=runtime(id)
  local nurse,visitors=0,0
  for _,object in ipairs(S.maps[id].objects)do
    check(nativeSprites[object.sprite]~=nil,'Center actor has an available sprite '..source)
    if object.name=='KA_SEVII_MEDIC'then
      nurse=nurse+1;check(object.x==x and object.y==2,'Joy stands behind the original counter '..source)
    elseif object.name:match('^KA_SEVII_CENTER_VISITOR_')then
      visitors=visitors+1
      check(tables.map_scripts[id].talk[object.text]~=nil,'Center visitor has dialogue '..source)
      check(map:isWalkableCell(object.x,object.y)and not map:warpAtCell(object.x,object.y),
        'Center visitor stands in reachable public space '..source)
    end
  end
  check(nurse==1 and visitors==(island==1 and 5 or 4),'Center staff and guests '..source)
  check(map:isCounterCell(x,3)and not S.walkable(id,x,3)and S.walkable(id,x,4),
    'Joy reachable across a solid original counter '..source)
  check(tables.map_songs[id]=='Music_Pokecenter','Center uses proper music '..source)
  local upperSource=prefix..'Island_PokemonCenter_2F'
  local upperId=assert(S.location(upperSource,0,0))
  local upperMap=runtime(upperId);local upperGuests=0
  for _,object in ipairs(S.maps[upperId].objects)do
    if object.name:match('^KA_SEVII_UPPER_VISITOR_')then
      upperGuests=upperGuests+1
      check(nativeSprites[object.sprite]~=nil,'upper Center guest has sprite '..upperSource)
      check(upperMap:isWalkableCell(object.x,object.y)and not upperMap:warpAtCell(object.x,object.y),
        'upper Center guest stands in public space '..upperSource)
      check(tables.map_scripts[upperId].talk[object.text]~=nil,
        'upper Center guest has dialogue '..upperSource)
    end
  end
  check(upperGuests==2,'upper Center has visitors '..upperSource)
end
local function reachable(id,sx,sy,tx,ty,water)
  local m=runtime(id);local queue={{sx,sy}};local seen={[sx..','..sy]=true};local at=1
  while queue[at]do
    local p=queue[at];at=at+1;if p[1]==tx and p[2]==ty then return true end
    for _,d in ipairs{{1,0},{-1,0},{0,1},{0,-1}}do
      local x,y=p[1]+d[1],p[2]+d[2];local k=x..','..y
      if not seen[k]and m:inBounds(x,y)and(m:isWalkableCell(x,y)or water and m:isWaterCell(x,y))then
        seen[k]=true;queue[#queue+1]={x,y}
      end
    end
  end
  return false
end
for id,m in pairs(S.maps)do
  check(#m.blocks==m.width*m.height,'map dimensions '..id)
  local map=runtime(id)
  for _,n in ipairs(m.objects)do
    check(map:isWalkableCell(n.x,n.y),'NPC on floor '..n.name)
  end
  for _,link in ipairs(S.links[id])do
    check(map:isWalkableCell(link.x,link.y),'door approachable '..id)
    check(runtime(link.map):isWalkableCell(link.toX,link.toY),'safe arrival '..link.map)
    for _,back in ipairs(S.links[link.map])do
      check(back.x~=link.toX or back.y~=link.toY,'no warp bounce')
      -- Multi-floor caves can return via another floor. The full directed
      -- world graph is covered by scripts/audit_sevii_geometry.py.
      if S.maps[link.map].index<=2108 then
        check(reachable(link.map,link.toX,link.toY,back.x,back.y,true),'return door reachable '..link.map)
      end
    end
    check(S.onStep({}, {map={id=id}},link.x,link.y),'real step dispatch')
    check(warps[#warps][1]==link.map,'correct destination')
  end
  for dir,conn in pairs(m.connections)do
    local opposite={north='south',south='north',east='west',west='east'}
    local back=S.maps[conn.map].connections[opposite[dir]]
    check(back and back.map==id and back.offset==-conn.offset,'reciprocal connection '..id)
  end
  for _,sealed in ipairs(m.kaSeviiSealed)do
    if sealed.x then check(not map:isWalkableCell(sealed.x,sealed.y),'unimported doorway sealed')end
  end
end
local city=runtime('VERMILION_CITY')
check(city:isWalkableCell(28,26),'ferry sailor cell')
check(city:isWalkableCell(27,26),'ferry return cell')
check(#tables.maps.VERMILION_CITY.objects==#cityBefore.objects+1,'add one sailor')
for i,w in ipairs(cityBefore.warps)do check(tables.maps.VERMILION_CITY.warps[i].destMap==w.destMap,'SS Anne warps unchanged')end
for _,o in ipairs(cityBefore.objects)do check(o.x~=28 or o.y~=26,'ferry avoids stock NPC')end
check(reachable(S.PORT,8,4,8,2),'harbor exit from ferry')
check(reachable(S.ONE,12,17,16,13),'researcher reachable')
check(reachable('KA_SEVII_KINDLE',0,61,17,61,true),'southern buoy reachable')
check(reachable('KA_SEVII_TREASURE',8,0,10,22,true),'beach buoy reachable by Surf')

local game={save={flags={},visited={}},data={pokemon={},encounters={},field={waterTilesets={}}},
  overworld={map={id='VERMILION_CITY'},player={cellX=27,cellY=26}}}
check(not S.depart(game),'pre-Champion departure denied')
check(not S.begin(game),'pre-Champion research denied')
game.overworld.map.id=S.PORT
check(not S.sail(game,2),'inter-island sailing also requires League completion')
game.overworld.map.id='VERMILION_CITY'
game.save.flags.EVENT_BEAT_CHAMPION_RIVAL=true
local voxelAllowed,voxelReason=S.depart(game)
check(not voxelAllowed and voxelReason=='voxel-required','Sevii ferry requires Voxel Ascendant')
game.mods={exports={VOXEL_ASCENDANT={}}}
check(S.depart(game),'postgame departure')
check(S.flight.chartUnlocked(),'Sevii map granted on first arrival')
check(S.state().stage==0,'travel does not auto-complete story')
check(S.begin(game)and not S.begin(game),'intro idempotent')
check(not S.report(),'cannot skip investigation')
check(not S.collect(game,'heat'),'remote collection refused')
for _,id in ipairs{'drift','heat'}do
  local p=S.samples[id];game.overworld.map.id=p.map
  game.overworld.player.cellX,game.overworld.player.cellY=p.x,p.y-1
  check(S.collect(game,id),'local measurement '..id)
  check(not S.collect(game,id),'duplicate sample rejected')
  stored=J.decode(require('src.link.Json').encode(stored))
  check(S.state().samples[id],'measurement survives JSON save/load')
end
check(S.state().stage==2 and S.report(),'investigation completes')
check(S.state().chapterOneComplete and not S.report(),'report once')
local C=S.chapters
local function near(site)
  game.overworld.map.id=site.map
  game.overworld.player.cellX,game.overworld.player.cellY=site.x-1,site.y
end
check(not C.readArchive(game),'archive requires actual presence')
near(C.sites.MIRROR_STONE)
check(not C.decode(game,{'SHORE','WAVE','STAR'}),'cannot skip archive clue')
near(C.sites.ARCHIVIST)
check(not C.report(game),'cannot report without decoded reflection')
check(C.readArchive(game),'archive clue recorded')
check(not C.readArchive(game),'archive clue idempotent')
near(C.sites.MIRROR_STONE)
check(not C.decode(game,{'STAR','WAVE','SHORE'}),'ordinary order rejected')
check(not C.decode(game,{'SHORE','WAVE','STAR','STAR'}),'extra symbol rejected')
check(not C.decode(game,nil),'invalid input rejected')
check(not S.state().chapters.two.decoded,'wrong answers do not advance quest')
check(C.decode(game,{'SHORE','WAVE','STAR'}),'reflected order accepted')
stored=J.decode(require('src.link.Json').encode(stored))
check(S.state().chapters.two.decoded,'reflection evidence survives save')
check(S.state().samples.drift and S.state().samples.heat and S.state().chapterOneComplete,'old chapter receipts preserved')
check(not C.decode(game,{'SHORE','WAVE','STAR'}),'no repeat reward')
near(C.sites.ARCHIVIST)
check(C.report(game),'local archive report completes chapter two')
check(not C.report(game),'archive report idempotent')
check(S.state().chapterTwoComplete and S.state().stage==3,'new chapter does not alter generation evidence stage')
check(S.returnToKanto(game),'return always available on island')
for island=1,7 do
  check(S.harbors[island]~=nil,'harbor for island '..island)
  game.overworld.map.id=S.PORT
  check(S.sail(game,island),'post-League route to island '..island)
  check(warps[#warps][1]==S.harbors[island],'ferry reaches correct harbor')
end
local visitedBeforeFlight=S.state()
for island,point in ipairs(S.flight.points)do
  check(S.flight.visited(game,island) and not game.save.visited[point.map],
    'island discovery does not bypass Fly gate '..island)
end
visitedBeforeFlight.chapterFiveComplete=true;S.persist(visitedBeforeFlight)
check(S.flight.sync(game),'station radio activates charted destinations')
for island,point in ipairs(S.flight.points)do
  check(S.flight.eligible(game,island) and game.save.visited[point.map]
    and Map.isFlyTown(S.maps[point.map]),
    'visited island Fly available after radio '..island)
  game.save.visited[point.map]=nil
end
visitedBeforeFlight.chapterFiveComplete=nil;S.persist(visitedBeforeFlight)
check(not S.sail(game,8),'unknown ferry destination refused')
local sound=require('src.core.Sound');local priorSound=sound.play;local cue
sound.play=function(_,name)cue=name end
local chapters=S.chapters;S.chapters=nil
local door=S.links[S.ONE][1]
check(S.onStep({data={}}, {map={id=S.ONE}},door.x,door.y)
  and cue=='Go_Inside','island Center door plays entry sound')
cue=nil
local returnDoor
for _,link in ipairs(S.links[S.CENTER])do if link.map==S.ONE then returnDoor=link;break end end
check(returnDoor and S.onStep({data={}}, {map={id=S.CENTER}},returnDoor.x,returnDoor.y)
  and cue=='Go_Outside','island Center exit plays outdoor sound')
S.chapters=chapters;sound.play=priorSound
game.overworld.map.id=S.ONE
check(not S.sail(game,2),'cannot sail from outside a harbor')
mod.world.warpTo=function()return false,'transition-busy'end
game.overworld.map.id='VERMILION_CITY'
check(not S.depart(game),'failed warp propagated')
check(S.state().stage==3,'failed travel preserves progress')
for _,id in ipairs{'NUMEL','TORKOAL','SPOINK','MACHOP','PONYTA','TENTACOOL','WINGULL','WAILMER','CARVANHA','ZIGZAGOON','ELECTRIKE','ODDISH'}do game.data.pokemon[id]={id=id}end
S.install(game)
local pcCollisionCount=0
for id,cells in pairs(S.solidFurniture)do
 for key in pairs(cells)do
  local x,y=key:match('^(%d+),(%d+)$');x,y=tonumber(x),tonumber(y)
  check(not S.walkable(id,x,y)and not runtime(id):isWalkableCell(x,y),
    'visible Sevii PC cabinet blocks movement '..id..' '..key)
  pcCollisionCount=pcCollisionCount+1
 end
end
check(pcCollisionCount==24,'all exposed Sevii PC cabinets protected')
for id,m in pairs(S.maps)do
  local map=runtime(id);local ts=tables.tilesets[m.tileset]
  for y=0,m.height*2-1 do for x=0,m.width*2-1 do
    local b=m.blocks[math.floor(y/2)*m.width+math.floor(x/2)+1]
    local expected=ts.sourceCellCollision[b+1][y%2*2+x%2+1]=='GRASS'
    check(map:isGrassCell(x,y)==expected,'native grass recognition '..id..' '..x..','..y)
  end end
  check(not map:isGrassCell(-1,0)and not map:isGrassCell(0,m.height*2),'out-of-bounds is never grass')
end
check(not city:isGrassCell(27,26),'native Kanto grass classification retained')
check(#game.data.encounters.KA_SEVII_KINDLE.grass.slots==10,'ten native slots')
check(game.data.encounters.KA_SEVII_KINDLE.kaProtected,'authored encounters protected')
local function contains(map,terrain,name)
  for _,slot in ipairs(game.data.encounters[map][terrain].slots)do if slot.species==name then return true end end
  return false
end
check(not contains('KA_SEVII_TREASURE','grass','WINGULL'),'missing optional sprites excluded')
check(contains('KA_SEVII_KINDLE','grass','NUMEL'),'unlocked Hoenn species available')
hoennOpen=false;S.install(game)
check(contains('KA_SEVII_KINDLE','grass','NUMEL'),'post-League island access does not require Honey')
hoennOpen=true;hoennOn=false;S.install(game)
check(not contains('KA_SEVII_KINDLE','grass','NUMEL'),'Hoenn encounters switch respected')
hoennOn=true;legacy=true;S.install(game)
check(contains('KA_SEVII_KINDLE','grass','NUMEL'),'Sevii closes unacquired legacy family gap')
inherited.NUMEL=true;S.install(game)
check(contains('KA_SEVII_KINDLE','grass','NUMEL'),'legacy inherited family retained')
inherited={};legacyAllowed=true;S.install(game)
check(contains('KA_SEVII_KINDLE','grass','NUMEL'),'legacy ordinary acquisition retained')
legacy=false;S.install(game)
game.save.flags.EVENT_BEAT_CHAMPION_RIVAL=false;S.install(game)
check(game.data.encounters.KA_SEVII_KINDLE.grass.rate==0,'no pre-League island encounters')
game.save.flags.EVENT_BEAT_CHAMPION_RIVAL=true;S.install(game)
for _,enc in pairs(game.data.encounters)do
  for _,group in pairs(enc)do if type(group)=='table'and group.slots then
    for _,slot in ipairs(group.slots)do
      check(slot.species~='MOLTRES'and slot.species~='GIRATINA'
        and slot.species~='REGIGIGAS'and slot.species~='ZYGARDE_10','no legendary duplicate')
    end
  end end
end
local count=#game.data.field.waterTilesets;S.install(game)
check(count==#game.data.field.waterTilesets,'Surf registration idempotent')
allowHoenn=false;S.install(game)
for _,group in pairs(game.data.encounters.KA_SEVII_KINDLE)do
  if type(group)=='table'and group.slots then for _,slot in ipairs(group.slots)do
    check(slot.species=='MACHOP'or slot.species=='PONYTA'or slot.species=='TENTACOOL','generation filter')
  end end
end
local viewLevel=0;local view={level=function()return viewLevel end,
  setLevel=function(_,level)viewLevel=level end}
local viewGame={save={},mods={exports={VOXEL_ASCENDANT={}}},overworld={map={id='VERMILION_CITY'}}}
S.syncVoxelView(viewGame,view)
viewGame.overworld.map.id=S.ONE;S.syncVoxelView(viewGame,view)
check(viewLevel==0,'first Sevii entry preserves the chosen 2D view')
viewLevel=5;viewGame.overworld.map.id=S.CENTER;S.syncVoxelView(viewGame,view)
check(viewLevel==5,'chosen Voxel camera survives an island door')
viewGame.overworld.map.id='VERMILION_CITY';S.syncVoxelView(viewGame,view)
check(viewLevel==0,'Kanto camera setting restored after return')
viewGame.overworld.map.id=S.ONE;S.syncVoxelView(viewGame,view)
check(viewLevel==5,'chosen Sevii camera restored on next ferry')
viewLevel=0;viewGame.overworld.map.id=S.CENTER;S.syncVoxelView(viewGame,view)
check(viewLevel==0,'chosen OFF survives an island door')
viewGame.overworld.map.id=S.ONE;S.syncVoxelView(viewGame,view)
check(viewLevel==0,'chosen OFF survives another island fragment')
viewGame.overworld.map.id='VERMILION_CITY';S.syncVoxelView(viewGame,view)
check(viewLevel==0,'return to Kanto restores its original OFF setting')
viewLevel=7;viewGame.overworld.map.id=S.ONE;S.syncVoxelView(viewGame,view)
check(viewLevel==0,'chosen Sevii OFF restored on next ferry')
viewGame.overworld.map.id='VERMILION_CITY';S.syncVoxelView(viewGame,view)
check(viewLevel==7,'return to Kanto restores its original nonzero camera')
local viewCalls=0;local originalSet=view.setLevel
view.setLevel=function(...)viewCalls=viewCalls+1;return originalSet(...)end
S.syncVoxelView(viewGame,view)
check(viewCalls==0 and viewLevel==7,'ordinary Kanto entry never changes the camera')
viewGame.save={};viewGame.overworld.map.id=S.ONE;S.syncVoxelView(viewGame,view)
check(viewLevel==7,'another save does not inherit the earlier Sevii choice')
viewLevel=0;S.syncVoxelView(viewGame,view)
viewGame.save=copy(viewGame.save);S.syncVoxelView(viewGame,view)
viewGame.overworld.map.id='VERMILION_CITY';S.syncVoxelView(viewGame,view)
check(viewLevel==7,'loading on Sevii retains the original Kanto camera for return')
local absent=dofile('sevii_expedition.lua')({read=function()end},{})
check(not absent.available,'no import means no mutation')
local guideRows=0
for island=1,7 do
  local map=S.maps[S.harbors[island]];local guide
  for _,n in ipairs(map.objects)do if n.name=='KA_SEVII_GUIDE'then guide=n end end
  check(guide and reachable(map.id,8,4,guide.x-1,guide.y),'guide reachable from landing')
  check(tables.map_scripts[map.id].talk.KA_SEVII_GUIDE~=nil,'guide interaction registered')
  local previous=''
  for _,entry in ipairs(S.guide.entries(game,island))do
    guideRows=guideRows+1
    check(entry.label>=previous,'guide alphabetic ordering');previous=entry.label
    check(entry.target.pool.island==island,'guide actual island')
    local text=assert(S.guide.describe(game,entry.id))
    check(text:find(S.maps[entry.target.pool.map].label,1,true),'guide actual map name')
    check(text:find(tostring(entry.target.row.level),1,true),'guide actual encounter level')
    check(not text:find('KA_SEVII',1,true),'no runtime map IDs in player text')
  end
end
check(guideRows==218,'guide lists all targets even if generation or art unavailable')
check(S.guide.describe(game,'GIRATINA')==nil,'no misleading Giratina catch directions')
for _,m in pairs(S.maps)do for _,n in ipairs(m.objects)do
  check(n.pushable==false,'authored story objects stay fixed; only finale runtime opts into pushing')
end end
-- A rejected host warp must not advance the moonlit trail; only the
-- successful authored door integration can consume the next route step.
local dreamState={expeditionComplete=true,seviiRiftSealed=true,
  mysteries={moonlitNight={briefed=true,awake=true,feather=true,trail=1}}}
S.persist(dreamState)
local originalWarp=mod.world.warpTo;local door=S.dreams.doors[1]
local dreamWorld={map={id=S.dreams.route[1]}}
mod.world.warpTo=function()return false end
check(not S.onStep(game,dreamWorld,door.x,door.y),'failed native warp stays put')
check(S.dreams.record().trail==1,'failed warp retains prior trail')
mod.world.warpTo=function()return true end
check(S.onStep(game,dreamWorld,door.x,door.y),'successful native warp accepted')
check(S.dreams.record().trail==2,'successful warp advances actual dream route')
mod.world.warpTo=originalWarp
print('PASS Sevii expedition: '..checks..' checks')
