-- Private seven-island world. Data is rebuilt from the player's BPRD
-- ROM. No changes are registered when that local import is absent.
return function(mod, opts)
  opts = opts or {}
  local S = { available=false, maps={}, KEY='sevii_expedition_v1',
    ONE='KA_SEVII_ONE', PORT='KA_SEVII_HARBOR', CENTER='KA_SEVII_CENTER' }
  -- Authored continuity contract for later chapters; this module registers
  -- no Giratina species, battle, gift or catch route.
  S.story={antagonist='GIRATINA',realm='DISTORTION_WORLD',catchable=false,
    recurring=true,finale='LOCAL_RIFT_SEALED',legendaryDuplicates=false}
  local raw = mod:read('assets/sevii_local/bundle.json')
  if type(raw) ~= 'string' then return S end
  local bundle = opts.json.decode(raw)
  assert(bundle.schema == 'kasc.sevii-bprd/v1', 'unsupported Sevii import')
  assert(bundle.romSha1 == '18a3758ceeef2c77b315144be2c3910d6f1f69fe', 'Sevii ROM identity mismatch')
  if mod.content.items then
    assert(not mod.content.items:get('GS_BALL'),'GS Ball item ID conflict')
    mod.content.items:register('GS_BALL',{
      id='GS_BALL',name=opts.i18n and opts.i18n.text('GS BALL','GS-BALL')or'GS BALL',
      price=0,pocket='KEY_ITEM',keyItem=true,tossable=false,needsTarget=false,
      lootExcluded=true,progressionItem=true,
    })
  end
  local function copy(v)
    if type(v)~='table' then return v end
    local t={};for k,x in pairs(v)do t[k]=copy(x)end;return t
  end
  local function tr(en,de) return opts.i18n and opts.i18n.text(en,de) or en end
  local function box(game,text,done)
    game.stack:push(require('src.render.TextBox').new(game,text,done))
  end
  function S.state()
    local previous=mod.save:get(S.KEY)
    local s=copy(previous or {})
    -- v1 already sold all three marine evolution items. Keep that stock on
    -- upgraded saves even if the player has used or sold the old supplies.
    if type(previous)=='table'and previous.version==1
        and (tonumber(previous.stage)or 0)>0 and s.evolutionResearch==nil then
      s.evolutionResearch={legacyMarine=true,found={}}
    end
    s.version=2;s.samples=s.samples or {};s.stage=tonumber(s.stage)or 0
    return s
  end
  local function persist(s)
    local ok,why=mod.save:set(S.KEY,s)
    assert(ok~=false,why or 'Sevii save failed')
  end
  S.persist=persist
  function S.unlocked(game)
    local save=game and game.save
    return save and ((save.flags and save.flags.EVENT_BEAT_CHAMPION_RIVAL==true)
      or (opts.legacyJourney and opts.legacyJourney.isActive(save)==true)) or false
  end
  function S.voxelReady(game)
    local exports=game and game.mods and game.mods.exports
    return exports and exports.VOXEL_ASCENDANT~=nil or false
  end
  function S.doubleVisualReady(game)
    local exports=game and game.mods and game.mods.exports
    local voxel=exports and exports.VOXEL_ASCENDANT
    local capability=voxel and voxel.capabilities and voxel.capabilities.seviiDoubleBattle
    local modes=type(capability)=='table'and capability.modes
    return type(capability)=='table'
      and capability.schema=='kasc.sevii-double-visual/v1'
      and capability.ready==true and type(modes)=='table'
      and modes.MAP==true and modes.DISCS==true
      and modes.ARENA==true and modes.TERRARIUM==true or false
  end
  local tiles={}
  -- The imported FRLG Centers have a solid service-counter cell between the
  -- player and the nurse. Mark its original art tile as a counter so the
  -- engine's existing two-cell nurse interaction works without moving Joy
  -- into the public aisle.
  local centerCounters={}
  for _,m in ipairs(bundle.maps)do
    if m.kaSeviiSource and m.kaSeviiSource:match('PokemonCenter_1F$')then
      local x,y=m.kaSeviiSource=='OneIsland_PokemonCenter_1F'and 5 or 7,3
      local atlas
      for _,entry in ipairs(bundle.tilesets)do if entry.id==m.tileset then atlas=entry;break end end
      assert(atlas,'Sevii Center tileset missing')
      local block=m.blocks[math.floor(y/2)*m.width+math.floor(x/2)+1]
      -- Map:cellTile reads the bottom-left 8px tile of the 16px cell.
      local tile=atlas.blocks[block+1][(y%2)*8+4+(x%2)*2+1]
      assert(atlas.sourceCellCollision[block+1][y%2*2+x%2+1]=='WALL',
        'Sevii Center counter must remain solid')
      centerCounters[m.tileset]=tile
    end
  end
  S.grassTiles={}
  local animationAssets={}
  local function animationPath(path,ts,extent,tile)
    local context='map='..ts.id:gsub('^KA_SEVII_TILES_','KA_SEVII_')..' tile='..tostring(tile)
    assert(type(path)=='string'and path:match('^assets/sevii_local/animations/[a-f0-9]+%.png$'),
      'invalid Sevii animation asset '..context..' path='..tostring(path))
    if not animationAssets[path]then
      local bytes=mod:read(path)
      assert(type(bytes)=='string'and bytes:sub(1,8)=='\137PNG\r\n\26\n',
        'missing/corrupt Sevii animation asset '..context..' path='..path)
      local ok,pixels=pcall(require('src.render.Assets').imageData,mod.path..'/'..path)
      assert(ok and pixels and pixels.getDimensions,
        'undecodable Sevii animation asset '..context..' path='..path)
      local w,h=pixels:getDimensions();animationAssets[path]={w,h}
    end
    assert(animationAssets[path][1]==extent and animationAssets[path][2]==extent,
      'wrong Sevii animation dimensions '..context..' path='..path)
    return mod.path..'/'..path
  end
  for _,ts in ipairs(bundle.tilesets)do
    assert(not mod.content.tilesets:get(ts.id),'Sevii tileset ID conflict')
    if centerCounters[ts.id]then ts.counterTiles={centerCounters[ts.id]}end
    if ts.animatedTiles then
      local owner=ts.kaSeviiTileAnimations
      assert(owner and owner.schema=='kasc.sevii-tile-animation/v1'and owner.counterMax==640,
        'invalid Sevii animation owner '..tostring(ts.id))
      assert(type(owner.groups)=='table'and #owner.groups>0 and #ts.animatedTiles>0,
        'empty Sevii animation definition '..ts.id)
      local seen={}
      for _,spec in ipairs(ts.animatedTiles)do
        assert(spec.kind=='frames'and spec.period==1
          and type(spec.tile)=='number'
          and type(spec.sequence)=='table'and #spec.sequence>0 and #spec.sequence<=640
          and type(spec.images)=='table'and #spec.images>1,
          'invalid Sevii animation tile '..tostring(ts.id)..' '..tostring(spec.tile))
        for _,tile in ipairs(spec.tiles or{spec.tile})do
          assert(type(tile)=='number'and tile%1==0 and tile>=0
            and tile<ts.imageWidth*ts.imageHeight/64 and not seen[tile],
            'invalid/duplicate Sevii animation tile '..ts.id..' '..tostring(tile))
          seen[tile]=true
        end
        for _,index in ipairs(spec.sequence)do assert(type(index)=='number'and index%1==0
          and index>=1 and index<=#spec.images,'invalid Sevii animation sequence '..ts.id)end
        for i,path in ipairs(spec.images)do spec.images[i]=animationPath(path,ts,8,spec.tile)end
      end
      for _,group in ipairs(owner.groups or{})do
        assert((group.kind=='surface'or group.kind=='flower'or group.kind=='steam')
          and group.period==1 and type(group.tiles)=='table'and #group.tiles==4
          and type(group.images)=='table'and #group.images>1
          and type(group.overlays)=='table'and #group.overlays==#group.images
          and type(group.sequence)=='table'and #group.sequence>0 and #group.sequence<=640,
          'invalid Sevii animation cell '..ts.id..' '..tostring(group.sourceMid))
        local first=group.tiles[1]
        assert(type(first)=='number'and first%1==0 and first>=0
          and group.tiles[2]==first+1 and group.tiles[3]==first+ts.tilesPerRow
          and group.tiles[4]==first+ts.tilesPerRow+1
          and group.tiles[4]<ts.imageWidth*ts.imageHeight/64,
          'invalid Sevii animation cell slots '..ts.id..' '..tostring(first))
        for _,index in ipairs(group.sequence)do
          assert(type(index)=='number'and index%1==0 and index>=1 and index<=#group.images,
            'invalid Sevii animation cell sequence '..ts.id..' '..first)
        end
        assert(group.kind~='steam'or group.background,'missing Sevii steam background '..ts.id..' '..first)
        if group.background then group.background=animationPath(group.background,ts,16,first)end
        for _,field in ipairs{'images','overlays'}do
          for i,path in ipairs(group[field]or{})do group[field][i]=animationPath(path,ts,16,first)end
        end
      end
    end
    ts.image=mod.path..'/'..ts.image
    mod.content.tilesets:register(ts.id,ts);tiles[ts.id]=ts
    local grass={};for _,tile in ipairs(ts.grassTiles or{})do grass[tile]=true end
    S.grassTiles[ts.id]=grass
  end
  local waterIds={}
  for id,ts in pairs(tiles)do if #ts.waterTiles>0 then waterIds[#waterIds+1]=id end end
  table.sort(waterIds)
  mod.content.field:patch('waterTilesets',waterIds)
  for _,m in ipairs(bundle.maps)do
    assert(not mod.content.maps:get(m.id),'Sevii map ID conflict')
    for id,existing in mod.content.maps:each()do
      assert(existing.index~=m.index,'Sevii map index conflict: '..id)
    end
    S.maps[m.id]=m
  end
  if (tonumber(bundle.revision)or 0)>=8 then
    assert(opts.sourceElevation,'Sevii source elevation adapter unavailable')
    S.sourceElevation=opts.sourceElevation(mod,S.maps)
  end
  if opts.legacyWanderers and opts.legacyWanderers.registerOutdoorMaps then
    -- Retain the normal Legacy cadence, rewards and map limits. Only open-air
    -- island maps join the existing placement pool; interiors stay excluded.
    opts.legacyWanderers.registerOutdoorMaps(bundle.maps)
  end
  S.solidFurniture={}
  function S.walkable(map,x,y)
    local m=S.maps[map];if not m or x<0 or y<0 or x>=m.width*2 or y>=m.height*2 then return false end
    if S.solidFurniture[map]and S.solidFurniture[map][x..','..y]then return false end
    local b=m.blocks[math.floor(y/2)*m.width+math.floor(x/2)+1]
    local kind=tiles[m.tileset].sourceCellCollision[b+1][y%2*2+x%2+1]
    return kind=='FLOOR' or kind=='GRASS'
  end
  -- Story and habitat authors address original FireRed cells. Runtime
  -- fragments are an implementation detail and must not leak into quests.
  function S.location(source,x,y)
    for id,m in pairs(S.maps)do
      if m.kaSeviiSource==source then
        local o,size=m.kaSeviiSourceOrigin,m.kaSeviiSourceSize
        if x>=o[1]and y>=o[2]and x<o[1]+size[1]and y<o[2]+size[2]then
          return id,x-o[1],y-o[2]
        end
      end
    end
  end
  -- The ROM's source collision marks the near edge of these PC cabinets as
  -- floor. Their Sevii voxel models occupy those exact cells, so keep the
  -- navigation grid in sync with the visible furniture in every view mode.
  local pcCabinets={
    'OneIsland_House1','OneIsland_House2','TwoIsland_House',
    'TwoIsland_CapeBrink_House','ThreeIsland_House2','ThreeIsland_House3',
    'ThreeIsland_House4','ThreeIsland_House5','FourIsland_House1',
    'FourIsland_House2','FiveIsland_House1','FiveIsland_House2',
    'SixIsland_House','SixIsland_WaterPath_House2',
    'SevenIsland_SevaultCanyon_House',
  }
  local function solid(source,x,y)
    local id,lx,ly=S.location(source,x,y)
    assert(id,'missing PC collision '..source)
    S.solidFurniture[id]=S.solidFurniture[id]or{}
    S.solidFurniture[id][lx..','..ly]=true
  end
  for _,source in ipairs(pcCabinets)do solid(source,1,2)end
  solid('SixIsland_WaterPath_House1',0,2)
  for _,source in ipairs{
    'TwoIsland_PokemonCenter_1F','ThreeIsland_PokemonCenter_1F',
    'FourIsland_PokemonCenter_1F','FiveIsland_PokemonCenter_1F',
    'SixIsland_PokemonCenter_1F','SevenIsland_PokemonCenter_1F',
  }do solid(source,8,6)end
  solid('OneIsland_PokemonCenter_1F',10,6)
  solid('TrainerTower_Lobby',4,9)
  local function isPortal(map,x,y)
    for _,w in ipairs(S.maps[map].kaSeviiWarps)do
      if w.x==x and w.y==y then return true end
    end
    return false
  end
  S.links={}
  local ledges={}
  for id,m in pairs(S.maps)do
    S.links[id]={}
    for _,row in ipairs(m.kaSeviiLedges or{})do
      ledges[#ledges+1]={tileset=row.tileset,standingTile=row.standingTile,
        ledgeTile=row.ledgeTile,facing=row.facing,input=row.input}
    end
    for _,w in ipairs(m.kaSeviiWarps)do
      local target=S.maps[w.destMap];local dest
      for _,candidate in ipairs(target.kaSeviiWarps)do
        if candidate.sourceIndex==w.destWarp then dest=candidate;break end
      end
      assert(dest,'missing Sevii warp target')
      local landing
      for _,d in ipairs{{0,1,'down'},{0,-1,'up'},{1,0,'right'},{-1,0,'left'}}do
        local x,y=dest.x+d[1],dest.y+d[2]
        local map=target.id
        if target.kaSeviiSource then
          map,x,y=S.location(target.kaSeviiSource,x+target.kaSeviiSourceOrigin[1],y+target.kaSeviiSourceOrigin[2])
        end
        if map and S.walkable(map,x,y)and not isPortal(map,x,y)then
          landing={map=map,x=x,y=y,facing=d[3]};break
        end
      end
      assert(landing,'no safe Sevii warp landing: '..target.id..' warp '..dest.sourceIndex)
      S.links[id][#S.links[id]+1]={x=w.x,y=w.y,map=landing.map,
        toX=landing.x,toY=landing.y,facing=landing.facing}
    end
  end
  if #ledges>0 then mod.content.field:patch('ledges',ledges)end
  function S.refreshCellPictures(game,metadata,marked)
    local ow=game and game.overworld;local m=ow and ow.map and S.maps[ow.map.id]
    if not m or not mod.world.activeBlockAt or not mod.world.replaceBlock then return end
    for _,row in ipairs(m[metadata]or{})do
      local mask=0
      for _,cell in ipairs(row.cells)do
        if marked[cell.x..','..cell.y]then mask=mask+cell.bit end
      end
      local target=assert(row.variants[tostring(mask)],'missing Sevii block variant')
      local current=mod.world:activeBlockAt(m.id,row.x,row.y)
      if current~=nil and current~=target then mod.world:replaceBlock(row.x,row.y,target)end
    end
  end
  function S.refreshIce(game)
    local ow=game and game.overworld;local s=S.state()
    local cracks=ow and s.iceVisit and s.iceVisit.map==ow.map.id and s.iceVisit.cracks or{}
    S.refreshCellPictures(game,'kaSeviiIceBlocks',cracks)
  end
  function S.onStep(game,ow,x,y)
    for _,link in ipairs(S.links[ow.map.id]or{})do
      if x==link.x and y==link.y then
        if S.chapters and S.chapters.beforeWarp then S.chapters.beforeWarp(game,ow,x,y,link)end
        local from=ow.map.id
        local moved=mod.world:warpTo(link.map,link.toX,link.toY,link.facing)==true
        if moved and game and game.data then
          local target=S.maps[link.map]
          require('src.core.Sound').play(game.data,
            target and target.outdoor and 'Go_Outside' or 'Go_Inside')
        end
        if moved and S.dreams then S.dreams.onWarp(game,from,link)end
        return moved
      end
    end
    for _,link in ipairs(S.maps[ow.map.id]and S.maps[ow.map.id].kaSeviiFalls or{})do
      if x==link.x and y==link.y then
        local s=S.state();local key=x..','..y
        local ice=s.iceVisit and s.iceVisit.map==ow.map.id and s.iceVisit or {map=ow.map.id,cracks={}}
        if ice.cracks[key]then
          return mod.world:warpTo(link.map,link.toX,link.toY,'down')==true
        end
        ice.cracks[key]=true;s.iceVisit=ice;persist(s);S.refreshIce(game)
        return false
      end
    end
    return S.chapters and S.chapters.onStep and S.chapters.onStep(game,ow,x,y)or false
  end
  local function npc(map,name,sprite,text,x,y)
    assert(S.walkable(map,x,y),'Sevii NPC placed on solid cell: '..name)
    local m=S.maps[map]
    m.objects[#m.objects+1]={index=#m.objects+1,name=name,sprite=sprite,
      movement='STAY',range='DOWN',text=text,x=x,y=y,pushable=false}
  end
  S.samples={
    drift={map='KA_SEVII_TREASURE',x=10,y=23},
    heat={map='KA_SEVII_KINDLE',x=17,y=62},
  }
  npc(S.ONE,'KA_SEVII_RESEARCHER','SPRITE_SCIENTIST','KA_SEVII_RESEARCH',16,12)
  S.harbors={}
  for id,m in pairs(S.maps)do
    if m.kaSeviiSource and m.kaSeviiSource:match('Island_Harbor$')then
      S.harbors[m.kaSeviiIsland]=id
      npc(id,'KA_SEVII_CAPTAIN','SPRITE_SAILOR','KA_SEVII_FERRY',7,4)
      npc(id,'KA_SEVII_GUIDE','SPRITE_SCIENTIST','KA_SEVII_GUIDE',9,5)
    elseif id~=S.CENTER and m.kaSeviiSource and m.kaSeviiSource:match('PokemonCenter_1F$')then
      npc(id,'KA_SEVII_MEDIC','SPRITE_NURSE','KA_SEVII_HEAL',7,2)
    end
  end
  npc(S.CENTER,'KA_SEVII_MEDIC','SPRITE_NURSE','KA_SEVII_HEAL',5,2)
  local centerVisitorTalks={}
  local centerVisitors={
    {1,'SPRITE_COOLTRAINER_M',6,8,
      'That machine links the islands? I thought it was just a really big PC!',
      'Die Maschine verbindet die Inseln? Ich dachte, das wäre nur ein riesiger PC!'},
    {1,'SPRITE_HIKER',3,7,
      'A climb on Mt. Ember can wear out even a tough team. Glad Joy is here.',
      'Der Aufstieg am Glutberg schlaucht selbst ein starkes Team. Gut, dass Joy hier ist.'},
    {1,'SPRITE_COOLTRAINER_F',7,4,
      'The sea routes are changing. My partner sensed it before the instruments did.',
      'Die Strömungen ändern sich. Mein Partner hat es vor den Messgeräten gespürt.'},
    {2,'SPRITE_GIRL',2,6,
      'The ferry captain said the current was rough today. My Pokemon needed a rest.',
      'Der Kapitän sagte, die Strömung sei heute stark. Meine Pokemon brauchten eine Pause.'},
    {2,'SPRITE_COOLTRAINER_M',10,7,
      'I came for a quick heal. Now I want to see what is beyond the cape!',
      'Ich wollte nur kurz heilen. Jetzt will ich wissen, was hinter dem Kap liegt!'},
    {3,'SPRITE_HIKER',2,6,
      'The berry forest looks peaceful. Keep an eye on the paths all the same.',
      'Der Beerenforst wirkt friedlich. Behalte die Wege trotzdem im Auge.'},
    {3,'SPRITE_GIRL',10,7,
      'My Pokemon always perks up when we reach an island Center.',
      'Mein Pokemon blüht jedes Mal auf, wenn wir ein Insel-Center erreichen.'},
    {4,'SPRITE_YOUNGSTER',2,6,
      'One step on the ice and I slipped! Joy patched up my partner.',
      'Ein Schritt aufs Eis und schon lag ich da! Joy hat meinen Partner versorgt.'},
    {4,'SPRITE_COOLTRAINER_F',10,7,
      'We trained by the cave until the wind turned. Time for a breather.',
      'Wir haben an der Höhle trainiert, bis der Wind drehte. Zeit für eine Pause.'},
    {5,'SPRITE_HIKER',2,6,
      'The warehouse road is longer than it looks on the map.',
      'Der Weg zum Lagerhaus ist länger, als er auf der Karte aussieht.'},
    {5,'SPRITE_COOLTRAINER_M',10,7,
      'I keep my team ready before I head into the meadow.',
      'Bevor ich zur Wiese gehe, mache ich mein Team fit.'},
    {6,'SPRITE_GIRL',2,6,
      'Out on the Water Path, a full team is worth more than a shortcut.',
      'Auf dem Wasserweg ist ein fittes Team mehr wert als jede Abkürzung.'},
    {6,'SPRITE_HIKER',10,7,
      'Those old stones have seen more travelers than we ever will.',
      'Diese alten Steine haben schon mehr Reisende gesehen als wir je sehen werden.'},
    {7,'SPRITE_COOLTRAINER_F',2,6,
      'The ruins can wait. My Pokemon deserve a rest first.',
      'Die Ruinen können warten. Meine Pokemon haben sich erst eine Pause verdient.'},
    {7,'SPRITE_COOLTRAINER_M',10,7,
      'When I get stronger, I will explore every chamber out there!',
      'Wenn ich stärker bin, erkunde ich dort draußen jede Kammer!'},
    {1,'SPRITE_SCIENTIST',11,8,
      'The link room is busy again. Good thing the nurse keeps us going.',
      'Im Verbindungsraum ist wieder viel los. Gut, dass Schwester Joy uns fit hält.'},
    {1,'SPRITE_GIRL',9,7,
      'I came in from the hot springs. Even my Pokemon look relaxed!',
      'Ich komme gerade von den heißen Quellen. Sogar meine Pokemon sind entspannt!'},
    {2,'SPRITE_HIKER',4,7,
      'A short rest, then I am off to the cape.',
      'Eine kurze Pause, dann geht es weiter zum Kap.'},
    {2,'SPRITE_GIRL',12,8,
      'The little shop here always has something useful for the trip.',
      'Der kleine Laden hier hat immer etwas Nützliches für die Reise.'},
    {3,'SPRITE_COOLTRAINER_F',4,7,
      'Our team made it back from the forest. That was close!',
      'Unser Team ist aus dem Wald zurück. Das war knapp!'},
    {3,'SPRITE_HIKER',12,8,
      'The island is bigger than I thought. Better stock up before I leave.',
      'Die Insel ist größer als gedacht. Ich nehme lieber noch Vorräte mit.'},
    {4,'SPRITE_GIRL',4,7,
      'A warm Center after the ice cave? I could stay here all day.',
      'Nach der Eishöhle ist es hier so gemütlich. Ich könnte bleiben!'},
    {4,'SPRITE_COOLTRAINER_M',12,8,
      'We will try the cave again after a good rest.',
      'Nach einer guten Pause versuchen wir es in der Höhle noch mal.'},
    {5,'SPRITE_GIRL',4,7,
      'The meadow was lovely, but my team is glad to be indoors.',
      'Die Wiese war schön, aber mein Team freut sich auf eine Pause.'},
    {5,'SPRITE_COOLTRAINER_F',12,8,
      'I want everyone healed before we head back to the warehouse.',
      'Vor dem Lagerhaus soll mein ganzes Team wieder fit sein.'},
    {6,'SPRITE_COOLTRAINER_M',4,7,
      'We crossed the water together. Now everyone gets a rest.',
      'Wir haben das Meer zusammen überquert. Jetzt ruhen sich alle aus.'},
    {6,'SPRITE_GIRL',12,8,
      'The old paths are quiet today. I wonder what lies beyond them.',
      'Die alten Wege sind heute still. Was wohl dahinter liegt?'},
    {7,'SPRITE_HIKER',4,7,
      'Those ruins are a maze. I am checking my map before I go back.',
      'Die Ruinen sind ein Labyrinth. Erst schaue ich noch mal auf die Karte.'},
    {7,'SPRITE_GIRL',12,8,
      'I saw a strange light by the chambers. Nobody believes me!',
      'Bei den Kammern habe ich ein seltsames Licht gesehen. Niemand glaubt mir!'},
  }
  for index,row in ipairs(centerVisitors)do
    local island,sprite,x,y,en,de=unpack(row)
    local source=({'One','Two','Three','Four','Five','Six','Seven'})[island]..'Island_PokemonCenter_1F'
    local id,lx,ly=S.location(source,x,y)
    local name='KA_SEVII_CENTER_VISITOR_'..index
    npc(id,name,sprite,name,lx,ly)
    centerVisitorTalks[name]=function(game,ow,n,done)box(game,tr(en,de),done);return true end
  end
  local upperVisitorLines={
    {{'Those machines look complicated. Celio must know them inside out!',
       'Die Geräte sehen kompliziert aus. Celio kennt sie bestimmt in- und auswendig!'},
     {'I am waiting for a friend who took the next ferry.',
       'Ich warte auf einen Freund, der die nächste Fähre genommen hat.'}},
    {{'Everyone meets here before heading out to the cape.',
       'Bevor es zum Kap geht, treffen sich hier alle.'},
     {'My partner likes the quiet up here after a long voyage.',
       'Nach einer langen Fahrt mag mein Partner die Ruhe hier oben.'}},
    {{'I wonder how far the signal reaches across the sea.',
       'Wie weit das Signal wohl über das Meer reicht?'},
     {'The forest is lively today. Up here I can catch my breath.',
       'Im Wald ist heute viel los. Hier oben kann ich kurz durchatmen.'}},
    {{'The sea breeze follows you even up the stairs!',
       'Die Meeresbrise kommt sogar die Treppe hoch!'},
     {'After the ice cave, I needed a quiet place to warm up.',
       'Nach der Eishöhle brauchte ich einen ruhigen Ort zum Aufwärmen.'}},
    {{'The old equipment still gets plenty of attention.',
       'Die alten Geräte ziehen immer noch neugierige Blicke auf sich.'},
     {'My team is resting downstairs. I will be back soon.',
       'Mein Team ruht sich unten aus. Ich bin gleich wieder da.'}},
    {{'I came here to compare maps with another traveler.',
       'Ich treffe mich hier mit jemandem, um unsere Karten zu vergleichen.'},
     {'The sea routes keep changing. It is good to share what we learn.',
       'Die Seewege ändern sich ständig. Gut, wenn wir uns austauschen.'}},
    {{'Those ruins have been there for ages. The stories keep changing.',
       'Die Ruinen sind uralt. Nur die Geschichten darüber ändern sich.'},
     {'I will set out again once my partner is ready.',
       'Sobald mein Partner bereit ist, ziehen wir wieder los.'}},
  }
  for island,lines in ipairs(upperVisitorLines)do
    local source=({'One','Two','Three','Four','Five','Six','Seven'})[island]..'Island_PokemonCenter_2F'
    for n,pair in ipairs(lines)do
      local id,x,y=S.location(source,n==1 and 4 or 10,5)
      local name='KA_SEVII_UPPER_VISITOR_'..island..'_'..n
      npc(id,name,n==1 and'SPRITE_COOLTRAINER_M'or'SPRITE_GIRL',name,x,y)
      local en,de=pair[1],pair[2]
      centerVisitorTalks[name]=function(game,ow,actor,done)box(game,tr(en,de),done);return true end
    end
  end
  if opts.flight then S.flight=opts.flight(mod,S)end
  for id,p in pairs(S.samples)do
    npc(p.map,'KA_SEVII_BUOY_'..id,'SPRITE_POKE_BALL','KA_SEVII_SAMPLE_'..id,p.x,p.y)
  end
  function S.begin(game)
    if not S.unlocked(game)then return false,'champion-required' end
    local s=S.state();if s.stage~=0 then return false,'already-started' end
    s.stage=1;persist(s);return true
  end
  function S.collect(game,id)
    local p=S.samples[id];local ow=game and game.overworld;local player=ow and ow.player
    if not(p and ow.map.id==p.map and player
        and math.abs(player.cellX-p.x)+math.abs(player.cellY-p.y)==1)then
      return false,'not-at-sample'
    end
    local s=S.state()
    if s.stage~=1 then return false,'research-not-active' end
    if s.samples[id]then return false,'already-collected' end
    s.samples[id]=true
    if s.samples.drift and s.samples.heat then s.stage=2 end
    persist(s);return true
  end
  function S.report()
    local s=S.state();if s.stage~=2 then return false,'samples-incomplete' end
    s.stage=3;s.chapterOneComplete=true;persist(s);return true
  end
  function S.depart(game)
    if not S.unlocked(game)then return false,'champion-required' end
    if not S.voxelReady(game)then return false,'voxel-required'end
    local ow=game and game.overworld
    if not(ow and ow.map.id=='VERMILION_CITY')then return false,'not-at-port' end
    local arrived,why=mod.world:warpTo(S.PORT,8,4,'down')
    if arrived and S.flight then S.flight.visit(game,1)end
    return arrived,why
  end
  function S.returnToKanto(game)
    if not(game and game.overworld and S.maps[game.overworld.map.id])then
      return false,'not-on-sevii'
    end
    return mod.world:warpTo('VERMILION_CITY',27,26,'left')
  end
  function S.sail(game,island)
    if island==0 then return S.returnToKanto(game)end
    if not S.unlocked(game)then return false,'champion-required'end
    local ow=game and game.overworld
    local current=ow and S.maps[ow.map.id]
    if not(current and S.harbors[current.kaSeviiIsland]==ow.map.id)then return false,'not-at-harbor'end
    local target=S.harbors[island]
    if not target then return false,'unknown-island'end
    local arrived,why=mod.world:warpTo(target,8,4,'left')
    if arrived and S.flight then S.flight.visit(game,island)end
    return arrived,why
  end
  local function ferry(game,ow,n,done)
    local items={{label=tr('VERMILION CITY','ORANIA CITY'),value=0}}
    local labels={'EINS','ZWEI','DREI','VIER','FÜNF','SECHS','SIEBEN'}
    for island=1,7 do
      if S.harbors[island] and S.harbors[island]~=ow.map.id then
        items[#items+1]={label=tr('ISLAND '..island,'EILAND '..labels[island]),value=island}
      end
    end
    if done then done()end
    game.stack:push(require('src.ui.ListMenu').new(game,tr('FERRY DESTINATION','REISEZIEL'),items,{
      onChoose=function(item)
        game.stack:pop();S.sail(game,item.value)
      end,
    }))
    return true
  end
  local function research(game,ow,n,done)
    local s=S.state()
    if s.stage==0 then
      box(game,tr('MARA: The sea has been playing tricks on our ferries. Two of my buoys washed ashore, one at TREASURE BEACH and one along southern KINDLE ROAD. Could you take a look? You will need SURF.',
        'MARA: Das Meer spielt unseren Fähren Streiche. Zwei meiner Bojen sind angespült worden: eine am SCHATZGESTADE, eine am südlichen GLÜHWEG. Kannst du sie dir ansehen? Du brauchst SURFER.'),function()S.begin(game);if done then done()end end)
    elseif s.stage==1 then
      box(game,tr('MARA: Any luck with my buoys? The one at TREASURE BEACH and the one on southern KINDLE ROAD should tell us what the tide is hiding.',
        'MARA: Hast du meine Bojen gefunden? Die am SCHATZGESTADE und die am südlichen GLÜHWEG verraten uns vielleicht, was die Flut verbirgt.'),done)
    elseif s.stage==2 then
      box(game,tr('MARA: Both buoys felt the same pulse at exactly the same moment. They are miles apart! And look at this reading... that coastline is nowhere on our charts. The keeper at the archive on TWO ISLAND knows an old song about mirrored shores. I think we should hear it.',
        'MARA: Beide Bojen haben im selben Augenblick ausgeschlagen. Dabei liegen sie meilenweit auseinander! Und sieh dir das an... Diese Küste steht auf keiner unserer Karten. Der Archivar auf EILAND ZWEI kennt ein altes Lied über gespiegelte Ufer. Das sollten wir uns anhören.'),function()S.report();if done then done()end end)
    elseif S.chapters then
      box(game,S.chapters.journal(),done)
    else
      box(game,tr('MARA: Take your time out there. The captain can take you back to KANTO whenever you like.',
        'MARA: Lass dir draußen Zeit. Der Kapitän bringt dich jederzeit nach KANTO zurück.'),done)
    end
    return true
  end
  local talks={KA_SEVII_RESEARCH=research,KA_SEVII_FERRY=ferry,
    KA_SEVII_RETURN=function(game,ow,n,done)
      box(game,tr('CAPTAIN: Next stop: VERMILION CITY!', 'KAPITÄN: Nächster Halt: ORANIA CITY!'),function()
        if done then done()end;S.returnToKanto(game)
      end);return true
    end,
    KA_SEVII_HEAL=function(game,ow,n,done)
      for _,mon in ipairs(game.save.party or{})do require('src.pokemon.Pokemon').heal(mon)end
      -- Keep the native last-heal destination: blackouts remain recoverable
      -- even when this private expansion is removed.
      box(game,tr('Your Pokemon are fighting fit again! Take care out there.',
        'Deine Pokemon sind wieder putzmunter! Passt auf euch auf.'),done);return true
    end}
  for name,dialogue in pairs(centerVisitorTalks)do talks[name]=dialogue end
  for id in pairs(S.samples)do
    local sampleId=id
    talks['KA_SEVII_SAMPLE_'..id]=function(game,ow,n,done)
      local s=S.state();local text
      if s.seviiRiftSealed then
        text=tr('The buoy sways gently with the tide. Its strange pulse is gone.',
          'Die Boje schaukelt ruhig in der Flut. Der seltsame Puls ist verschwunden.')
      elseif s.stage==0 then
        text=tr('A stranded research buoy. The researcher in town may know more.',
          'Eine gestrandete Messboje. Die Forscherin im Ort weiß vielleicht mehr.')
      elseif s.samples[sampleId]then
        text=tr('The buoy blinks a familiar rhythm. You have its reading already.',
          'Die Boje blinkt in einem vertrauten Takt. Ihre Messung hast du schon.')
      else
        local ok=S.collect(game,sampleId)
        if not ok then return false end
        text=sampleId=='drift' and tr('The buoy bobs against the tide. Its needle points toward a changed migration route from Hoenn. You copy the reading.',
          'Die Boje treibt gegen die Flut. Ihre Nadel zeigt auf eine veränderte Wanderroute aus Hoenn. Du schreibst die Messung ab.')
          or tr('The buoy is warm to the touch. Deep below, something pulses in a rhythm no volcano should make. You copy the reading.',
          'Die Boje fühlt sich warm an. Tief unten pulsiert etwas in einem Takt, den kein Vulkan erzeugen sollte. Du schreibst die Messung ab.')
      end
      box(game,text,done);return true
    end
  end
  if opts.scaling then S.scaling=opts.scaling(S,opts)end
  S.habitats=assert(opts.encounters,'Sevii encounter owner missing')(mod,S,opts)
  S.assetsReady=S.habitats.assetsReady
  S.encounters=S.habitats.encounters
  if opts.legendPolicy then S.legendPolicy=opts.legendPolicy(mod,S,opts)end
  if S.legendPolicy and S.legendPolicy.history then
    -- Bind only after a usable island bundle exists. A missing optional
    -- import must not turn the original Kanto owners into archive errors.
    for _,key in ipairs{'hoennLegendPortals','hoennBirthIsland','hoennJirachiFinale',
        'hoennRoamers','hoennSanctums','hoennMoltres'}do
      local owner=opts[key]
      if owner then owner.bindLegendHistory(S.legendPolicy.history)end
    end
  end
  if opts.chapters then S.chapters=opts.chapters(S,{tr=tr,box=box,npc=npc,talks=talks,
    world=function()return mod.world end,forestRescue=opts.forestRescue,iceMemory=opts.iceMemory,
    stationMission=opts.stationMission,ruinsMission=opts.ruinsMission,finaleMission=opts.finaleMission,
    apparition=opts.apparition,assetRoot=mod.path,menu=opts.ui and opts.ui.ListMenu})end
  if opts.guide then
    S.guide=opts.guide(S,opts)
    talks.KA_SEVII_GUIDE=function(game,ow,n,done)
      if done then done()end
      S.guide.open(game);return true
    end
  end
  if opts.population then S.population=opts.population(S,{tr=tr,box=box,npc=npc,talks=talks,
    menu=opts.ui and opts.ui.ListMenu,
    daycare=opts.daycare,
    beyondActive=opts.beyondKanto and opts.beyondKanto.peekIsActive,
    epoch=function(game)
      local rules=opts.generationRules
      return rules and rules.peek and rules.peek(game).activeEpoch or 1
    end})end
  if opts.evolutionResearch then
    S.evolutionResearch=opts.evolutionResearch(S,{tr=tr,box=box,npc=npc,talks=talks},opts)
    if S.population then S.population.evolutionStock=S.evolutionResearch.stock end
  end
  S.doubleArenas=opts.doubleArenas
  if opts.trainers then S.trainers=opts.trainers(mod,S,{tr=tr,box=box,npc=npc,talks=talks,
    menu=opts.ui and opts.ui.ListMenu},opts)end
  if opts.tower and S.trainers then S.tower=opts.tower(S,{tr=tr,box=box,npc=npc,talks=talks})end
  if opts.mysteries then S.mysteries=opts.mysteries(S,{tr=tr,box=box,npc=npc,talks=talks,
    menu=opts.ui and opts.ui.ListMenu},opts)end
  if opts.specialEncounters then S.specialEncounters=opts.specialEncounters(S,opts)end
  if opts.lakeGuardians then S.lakeGuardians=opts.lakeGuardians(S,{tr=tr,box=box,npc=npc,talks=talks,
    menu=opts.ui and opts.ui.ListMenu})end
  if opts.dreams then S.dreams=opts.dreams(S,{tr=tr,box=box,npc=npc,talks=talks,
    menu=opts.ui and opts.ui.ListMenu})end
  if opts.sleepingGiant then S.sleepingGiant=opts.sleepingGiant(S,{tr=tr,box=box,npc=npc,talks=talks,
    sanctums=opts.hoennSanctums,menu=opts.ui and opts.ui.ListMenu})end
  if opts.weatherTrio then S.weatherTrio=opts.weatherTrio(S,{tr=tr,box=box,npc=npc,talks=talks,
    world=function()return mod.world end,menu=opts.ui and opts.ui.ListMenu},opts)end
  if opts.tidalReturn then S.tidalReturn=opts.tidalReturn(S,{tr=tr,box=box,npc=npc,talks=talks,
    world=function()return mod.world end,menu=opts.ui and opts.ui.ListMenu})end
  if opts.garden then S.garden=opts.garden(S,{tr=tr,box=box,npc=npc,talks=talks,
    world=function()return mod.world end,menu=opts.ui and opts.ui.ListMenu})end
  if opts.timeSpace then S.timeSpace=opts.timeSpace(S,{tr=tr,box=box,npc=npc,talks=talks,
    menu=opts.ui and opts.ui.ListMenu})end
  if opts.sevenTestimonies then S.sevenTestimonies=opts.sevenTestimonies(S,{tr=tr,box=box,npc=npc,talks=talks,
    menu=opts.ui and opts.ui.ListMenu})end
  if opts.eonRoaming then S.eonRoaming=opts.eonRoaming(mod,S,opts)end
  for id,m in pairs(S.maps)do
    mod.content.maps:register(id,m)
    mod.content.encounters:register(id,{grass={rate=0,slots={}}})
    mod.content.map_scripts:register(id,{priority=3400,onStep=S.onStep,talk=talks,
      onBoulderMoved=function(game,ow,npc)
        if S.chapters and S.chapters.onBoulderMoved then S.chapters.onBoulderMoved(game,ow,npc)end
      end})
    if opts.spawnSafety then
      local cells={}
      for _,n in ipairs(m.objects)do
        cells[#cells+1]={x=n.x,y=n.y,approaches=true}
      end
      for _,link in ipairs(S.links[id])do cells[#cells+1]={x=link.x,y=link.y,approaches=true}end
      if S.chapters and S.chapters.finale and id==S.chapters.finale.keyMap then
        for y=0,m.height*2-1 do for x=0,m.width*2-1 do
          if S.walkable(id,x,y)then cells[#cells+1]={x=x,y=y}end
        end end
      end
      for _,metadata in ipairs{'kaSeviiTraceBlocks','kaSeviiStationGate'}do
        for _,row in ipairs(m[metadata]or{})do
          for _,cell in ipairs(row.cells)do
            cells[#cells+1]={x=cell.x,y=cell.y,approaches=true}
          end
        end
      end
      opts.spawnSafety.reserveCells(id,cells,'Sevii expedition interactions')
    end
    if mod.content.map_songs then mod.content.map_songs:register(id,
      m.kaSeviiSource and m.kaSeviiSource:find('PokemonCenter_',1,true)
        and 'Music_Pokecenter' or m.outdoor and 'Music_Vermilion' or 'Music_PalletTown')end
  end
  -- A separate sailor beside the existing pier does not consume the SS Anne
  -- ticket/boarding event or alter any existing warp, NPC or story flag.
  local city=assert(mod.content.maps:get('VERMILION_CITY'))
  local objects=copy(city.objects or{})
  local index=0;for _,o in ipairs(objects)do index=math.max(index,o.index or 0)end
  objects[#objects+1]={index=index+1,name='KA_SEVII_FERRY',sprite='SPRITE_SAILOR',
    movement='STAY',range='LEFT',text='KA_SEVII_DEPART',x=28,y=26}
  mod.content.maps:patch('VERMILION_CITY',{objects=objects})
  mod.content.map_scripts:register('VERMILION_CITY',{priority=3400,talk={
    KA_SEVII_DEPART=function(game,ow,n,done)
      if not S.unlocked(game)then
        box(game,tr('The seas are rough. Come back after the POKEMON LEAGUE; then I can take you to the islands.',
          'Die See ist rau. Komm nach der POKEMON-LIGA wieder, dann bringe ich dich zu den Inseln.'),done)
      elseif not S.voxelReady(game)then
        box(game,tr('The Sevii expedition requires Voxel Ascendant. Enable it before boarding.',
          'Die Sevii-Expedition benötigt Voxel Ascendant. Aktiviere es vor der Überfahrt.'),done)
      else
        local briefing=S.state().stage==0 and tr(
          'CAPTAIN: ONE ISLAND, coming up! MARA in town is investigating strange tides. Speak to her to begin your expedition. I have marked all seven islands on your map. The return ferry runs whenever you need it.',
          'KAPITÄN: Nächster Halt: EILAND EINS! MARA im Ort untersucht ungewöhnliche Gezeiten. Sprich mit ihr, um deine Expedition zu beginnen. Alle sieben Inseln sind auf deiner Karte markiert. Die Rückfähre fährt, wann immer du sie brauchst.')
          or tr('CAPTAIN: ONE ISLAND, coming up! I have marked the whole archipelago on your map. The return ferry runs whenever you need it.',
          'KAPITÄN: Nächster Halt: EILAND EINS! Ich habe dir alle Inseln auf der Karte markiert. Die Rückfähre fährt, wann immer du sie brauchst.')
        box(game,briefing,function()
          if done then done()end;S.depart(game)
        end)
      end
      return true
    end}})
  local previousVoxelLevel,seviiVoxelLevel,wasOnSevii,viewSave,viewContext
  local function savedViewLevel(value)
    return type(value)=='number' and value>=0 and value<math.huge
      and value==math.floor(value) and value or nil
  end
  function S.syncVoxelView(game,pipelines)
    if viewSave~=game.save then
      previousVoxelLevel,seviiVoxelLevel,wasOnSevii=nil,nil,false
      viewSave=game.save
      viewContext=viewSave and viewSave.kaSeviiVoxelView67
      if type(viewContext)=='table' and viewContext.version==1 then
        previousVoxelLevel=savedViewLevel(viewContext.kantoLevel)
        seviiVoxelLevel=savedViewLevel(viewContext.seviiLevel)
        wasOnSevii=viewContext.active==true
      else viewContext=nil end
    end
    if not S.voxelReady(game)then return end
    local onSevii=game.overworld and game.overworld.map
      and S.maps[game.overworld.map.id]~=nil
    local level=pipelines.level('voxel')
    if onSevii then
      if not wasOnSevii then
        previousVoxelLevel=level
        if seviiVoxelLevel~=nil then
          pipelines.setLevel('voxel',seviiVoxelLevel)
          level=seviiVoxelLevel
        end
      end
      -- The dependency supplies Sevii scenery; it does not require its
      -- renderer to be enabled. OFF is a camera choice too, including at
      -- fragment/door transitions and on the next ferry trip.
      seviiVoxelLevel=level
      -- Optional presentation state; old saves need no migration. Keep the
      -- pre-ferry view across a save/load on an island without sharing it
      -- with another save. Ordinary Kanto entries never create this table.
      if not viewContext then
        viewContext={version=1};viewSave.kaSeviiVoxelView67=viewContext
      end
      viewContext.kantoLevel=previousVoxelLevel
      viewContext.seviiLevel=seviiVoxelLevel
      viewContext.active=true
    elseif wasOnSevii then
      seviiVoxelLevel=level
      pipelines.setLevel('voxel',previousVoxelLevel or 0)
      previousVoxelLevel=nil
      if viewContext then
        viewContext.kantoLevel=nil;viewContext.seviiLevel=seviiVoxelLevel
        viewContext.active=false
      end
    end
    wasOnSevii=onSevii and true or false
  end
  function S.install(game)
    if not(game and game.data)then return end
    if S.sourceElevation then S.sourceElevation.install()end
    if S.flight then
      S.flight.install()
      local island=S.flight.currentIsland(game)
      if island then S.flight.visit(game,island)end
      S.flight.sync(game)
    end
    if S.voxelReady(game)then
      S.syncVoxelView(game,require('src.render.Pipelines'))
    end
    -- Native Gen1 reads one grassTile per tileset. Imported GBA atlases
    -- retain several authentic grass pictures, so their collision feet
    -- have several tile IDs. Classify only our maps through that set.
    local Map=require('src.world.Map')
    if not Map.__kascSeviiPcCollisionWrapped then
      local originalWalkable=Map.isWalkableCell
      Map.isWalkableCell=function(map,x,y)
        local owner=Map.__kascSeviiGrassOwner
        if owner and owner.solidFurniture[map.id]
            and owner.solidFurniture[map.id][x..','..y]then return false end
        return originalWalkable(map,x,y)
      end
      Map.__kascSeviiPcCollisionWrapped=true
    end
    if not Map.__kascSeviiGrassWrapped then
      local original=Map.isGrassCell
      Map.isGrassCell=function(map,x,y)
        local owner=Map.__kascSeviiGrassOwner
        if owner and owner.maps[map.id]then
          local grass=owner.grassTiles[map.def.tileset]
          return map:inBounds(x,y)and grass and grass[map:cellTile(x,y)]==true or false
        end
        return original(map,x,y)
      end
      Map.__kascSeviiGrassWrapped=true
    end
    Map.__kascSeviiGrassOwner=S
    S.habitats.game=game
    if S.eonRoaming then S.eonRoaming.install(game)end
    if S.chapters and S.chapters.install then S.chapters.install(game)end
    if S.tidalReturn then S.tidalReturn.install(game)end
    if S.garden then S.garden.install(game)end
    if S.timeSpace then S.timeSpace.install(game)end
    if S.weatherTrio then S.weatherTrio.install(game)end
    for id in pairs(S.maps)do game.data.encounters[id]=S.encounters(game,id)end
    local s=S.state()
    if s.iceVisit and game.overworld and game.overworld.map.id~=s.iceVisit.map then
      s.iceVisit=nil;persist(s)
    end
    S.refreshIce(game)
  end
  for _,event in ipairs{'game.ready','save.loaded','map.entered'}do
    mod.events:on(event,function(ev)
      if ev and ev.game then S.game=ev.game end
      S.install(S.game)
    end)
  end
  -- PCs are drawn by the imported Center map itself. The facing-cell event
  -- opens storage directly, avoiding a second terminal sprite on the aisle
  -- or an NPC that the engine cannot place on a solid cabinet cell.
  mod.events:on('world.interacted',function(event)
    if event and event.kind=='none'and S.population then
      S.population.openPCAt(S.game or mod.world.game,event.mapId,event.x,event.y)
    end
  end)
  if opts.beyondKanto and opts.beyondKanto.onChanged then
    opts.beyondKanto.onChanged(function(_,game)S.install(game or S.game)end)
  end
  S.available=true
  if opts.battleAnimations then S.battleAnimations=opts.battleAnimations(mod,S)end
  return S
end
