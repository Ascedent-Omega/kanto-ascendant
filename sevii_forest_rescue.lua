-- Chapter three: a persistent rescue with a real overworld companion.
-- Only expedition-owned actors are spawned/toggled; the player's Pokemon
-- follower selection and ordinary encounters remain owned by their systems.
return function(S,ui)
  local R={SOURCE='ThreeIsland_BerryForest',sites={}}
  local tr,box=ui.tr,ui.box
  local liveId,liveMap,syncing
  local function state()
    local s=S.state();s.chapters=s.chapters or{};s.chapters.three=s.chapters.three or{}
    local q=s.chapters.three;q.landmarks=q.landmarks or{}
    return s,q
  end
  local function site(source,x,y)
    local map,lx,ly=S.location(source,x,y);assert(map,'missing rescue location')
    return {map=map,x=lx,y=ly}
  end
  R.sites.stranded=site(R.SOURCE,4,6)
  R.sites.home=site('ThreeIsland_House2',2,3)
  R.sites.exit=site(R.SOURCE,43,40)
  local function add(p,name,text,hidden)
    ui.npc(p.map,name,'SPRITE_GIRL',text,p.x,p.y)
    local objects=S.maps[p.map].objects
    objects[#objects].hidden=hidden or false
  end
  add(R.sites.stranded,'KA_SEVII_LINA_STRANDED','KA_SEVII_LINA_RESCUE')
  add(R.sites.home,'KA_SEVII_LINA_HOME','KA_SEVII_LINA_HOME',true)
  local function position(game)
    local ow=game and game.overworld;local p=ow and ow.player
    return ow and ow.map and p and {map=ow.map.id,x=p.cellX,y=p.cellY}or nil
  end
  local function inForest(p)
    return p and S.maps[p.map]and S.maps[p.map].kaSeviiSource==R.SOURCE
  end
  local function near(p,where)
    return p and p.map==where.map and math.abs(p.x-where.x)+math.abs(p.y-where.y)==1
  end
  local function world()return ui.world and ui.world()end
  local function removeCompanion()
    local w=world()
    if liveId and w and w.removeNpc then w:removeNpc(liveId)end
    liveId,liveMap=nil,nil
  end
  local function visible(game,p,name,value)
    local save=game and game.save;if not save then return end
    local old=save.objectToggles and save.objectToggles[p.map]
    if old and old[name]==value then return end
    local w=world()
    if w and w.toggleObject then w:toggleObject(p.map,name,value)end
  end
  local function safeNearby(game,p)
    local ow=game.overworld
    for _,d in ipairs{{0,1},{0,-1},{1,0},{-1,0}}do
      local x,y=p.x+d[1],p.y+d[2]
      if S.walkable(p.map,x,y)then
        local busy=false
        for _,n in ipairs(ow.npcs or{})do
          if n.cellX==x and n.cellY==y then busy=true;break end
        end
        for _,link in ipairs(S.links[p.map]or{})do
          if link.x==x and link.y==y then busy=true end
        end
        if not busy then return {map=p.map,x=x,y=y}end
      end
    end
    return nil
  end
  local function handle(game,q,p)
    local w=world();if not(w and w.npc and w.spawnNpc)then return end
    if liveId and liveMap==p.map then
      local found=w:npc(p.map,liveId)
      if found then
        found:setPassable(true)
        local x,y=found:position()
        if math.abs(x-p.x)+math.abs(y-p.y)>2 then
          local restore=q.companion
          if not(restore and restore.map==p.map and S.walkable(p.map,restore.x,restore.y)
              and math.abs(restore.x-p.x)+math.abs(restore.y-p.y)<=2)then restore=safeNearby(game,p)end
          if restore then found:placeAt(restore.x,restore.y)end
        end
        return found
      end
    end
    removeCompanion()
    local where=q.companion
    if not(where and where.map==p.map and S.walkable(p.map,where.x,where.y)
        and math.abs(where.x-p.x)+math.abs(where.y-p.y)<=2
        and (where.x~=p.x or where.y~=p.y))then where=safeNearby(game,p)end
    if not where then return end -- Try again after the next safe step.
    liveId=w:spawnNpc(p.map,{name='KA_SEVII_LINA_ESCORT',sprite='SPRITE_GIRL',
      movement='STAY',range='DOWN',text='KA_SEVII_LINA_ESCORT',x=where.x,y=where.y})
    liveMap=liveId and p.map or nil
    local actor=liveId and w:npc(p.map,liveId)
    if actor then actor:setPassable(true)end
    return actor
  end
  function R.install(game)
    if syncing or not(game and game.save)then return end
    syncing=true
    local s,q=state();local p=position(game)
    if q.escorting and p and not inForest(p)then
      -- Flying/escaping/blacking out must not strand the only quest actor.
      q.escorting=false;q.companion=nil;q.lastPlayer=nil;q.separated=true
      S.persist(s);removeCompanion()
    end
    visible(game,R.sites.stranded,'KA_SEVII_LINA_STRANDED',not q.escorting and not q.rescued)
    visible(game,R.sites.home,'KA_SEVII_LINA_HOME',q.rescued==true)
    if q.escorting and inForest(p)then
      handle(game,q,p)
    else removeCompanion()end
    syncing=false
  end
  function R.begin(game)
    local p=position(game);local s,q=state()
    if not S.unlocked(game)or not s.chapterTwoComplete then return false,'chapter-two-required'end
    if not near(p,R.sites.stranded)then return false,'not-at-surveyor'end
    if q.rescued or q.escorting then return false,'already-rescued-or-following'end
    q.escorting=true;q.found=true;q.separated=false;q.lastPlayer=p
    q.companion={map=R.sites.stranded.map,x=R.sites.stranded.x,y=R.sites.stranded.y}
    S.persist(s);R.install(game);return true
  end
  function R.arrive(game)
    local p=position(game);local s,q=state()
    if not S.unlocked(game)or not s.chapterTwoComplete or not q.escorting then return false,'not-escorting'end
    if not(p and p.map==R.sites.exit.map and p.y==R.sites.exit.y
        and math.abs(p.x-R.sites.exit.x)<=1)then return false,'not-at-exit'end
    q.escorting=false;q.rescued=true;q.companion=nil;q.lastPlayer=nil
    S.persist(s);removeCompanion();R.install(game);return true
  end
  function R.report(game)
    local s,q=state()
    if not S.unlocked(game)or not s.chapterTwoComplete or not q.rescued then return false,'rescue-required'end
    if not near(position(game),R.sites.home)then return false,'not-at-house'end
    if q.complete then return false,'already-reported'end
    q.complete=true;s.chapterThreeComplete=true;S.persist(s);return true
  end
  function R.journal()
    local s,q=state()
    if not q.found then
      return tr('EXPEDITION NOTES: Find surveyor LINA in the northwest clearing of BERRY FOREST on THREE ISLAND. From the forest entrance, follow the winding trail around the ponds. Her house is the western house beside the northern path in town.',
        'EXPEDITIONSNOTIZEN: Suche die Vermesserin LINA auf der Lichtung im Nordwesten des BEERENFORSTS auf EILAND DREI. Folge vom Waldeingang dem gewundenen Weg um die Teiche. Ihr Haus steht im Ort westlich am nördlichen Weg.')
    elseif q.escorting then
      return tr('EXPEDITION NOTES: Lead LINA to the southern forest exit. She follows your steps. If you become separated, meet her again in the northwest clearing.',
        'EXPEDITIONSNOTIZEN: Führe LINA zum südlichen Waldausgang. Sie folgt deinen Schritten. Falls ihr getrennt werdet, triff sie wieder auf der Lichtung im Nordwesten.')
    elseif not q.rescued then
      return tr('EXPEDITION NOTES: LINA has returned to the northwest clearing. Speak to her there to resume the rescue. Your observations are safe.',
        'EXPEDITIONSNOTIZEN: LINA wartet wieder auf der Lichtung im Nordwesten. Sprich sie dort an, um die Rettung fortzusetzen. Deine Beobachtungen bleiben erhalten.')
    elseif not q.complete then
      return tr('EXPEDITION NOTES: LINA is safe. Visit her at home on THREE ISLAND, in the western house beside the northern path. She is comparing her survey with the archive map.',
        'EXPEDITIONSNOTIZEN: LINA ist in Sicherheit. Besuche sie auf EILAND DREI im westlichen Haus am nördlichen Weg. Sie vergleicht ihre Messungen mit der Archivkarte.')
    end
    return tr('EXPEDITION NOTES: The forest moved around old anchor stones. LINA found a matching mark on a sketch of ICEFALL CAVE on FOUR ISLAND. An earlier expedition left its records frozen there.',
      'EXPEDITIONSNOTIZEN: Der Wald verschob sich um alte Ankersteine. LINA fand das gleiche Zeichen auf einer Skizze der EISKASKADENHÖHLE auf EILAND VIER. Eine frühere Expedition hinterließ dort eingefrorene Aufzeichnungen.')
  end
  function R.onStep(game,ow,x,y)
    local s,q=state();if not q.escorting then return false end
    local p={map=ow.map.id,x=x,y=y};if not inForest(p)then return false end
    local actor=handle(game,q,p);local previous=q.lastPlayer
    if actor and previous and previous.map==p.map and S.walkable(p.map,previous.x,previous.y)then
      local ax,ay=actor:position();local dx,dy=previous.x-ax,previous.y-ay
      if actor:isMoving()then actor:placeAt(ax,ay)end
      if math.abs(dx)+math.abs(dy)==1 then
        -- Match the native player's completed step, including running.
        -- NPC exposes stepFrames for follower movement in the engine.
        if actor.npc then actor.npc.stepFrames=ow.player.stepFramesCur or ow.player.stepFrames or 16 end
        actor:stepNow(dx==1 and'right'or dx==-1 and'left'or dy==1 and'down'or'up')
      elseif dx~=0 or dy~=0 then actor:placeAt(previous.x,previous.y)end
      q.companion={map=p.map,x=previous.x,y=previous.y}
    end
    q.lastPlayer=p
    local m=S.maps[p.map];local sx,sy=x+m.kaSeviiSourceOrigin[1],y+m.kaSeviiSourceOrigin[2]
    local message
    if sx<=10 and sy>=19 and sy<=30 and not q.landmarks.west then
      q.landmarks.west=true
      message=tr('LINA: That pond was on my left when I came here. My map has not changed, but the trail has! The roots still point toward the old path. I will follow you.',
        'LINA: Dieser Teich lag vorhin links von mir. Meine Karte ist unverändert, aber der Weg hat sich verschoben! Die Wurzeln zeigen noch zum alten Pfad. Ich folge dir.')
    elseif sx>=25 and sy<=12 and not q.landmarks.north then
      q.landmarks.north=true
      message=tr('LINA: Look at the shadow by the water. It moved against the light. Something on the other side is pulling at this place. Keep going; the southern gate is real.',
        'LINA: Der Schatten am Wasser! Er lief gegen das Licht. Etwas auf der anderen Seite zieht an diesem Ort. Weiter, das südliche Tor ist echt.')
    end
    S.persist(s)
    if R.arrive(game)then
      box(game,tr('LINA: The harbour bell! I thought I would never hear that again. I can get home from here. Come by later, will you? I want to show you what happened to my map.',
        'LINA: Die Hafenglocke! Ich dachte schon, ich höre sie nie wieder. Von hier finde ich allein nach Hause. Komm später vorbei, ja? Ich möchte dir meine Karte zeigen.'))
      return true
    elseif message then box(game,message);return true end
    return false
  end
  ui.talks.KA_SEVII_LINA_RESCUE=function(game,ow,n,done)
    local s,q=state()
    if not s.chapterTwoComplete then
      box(game,tr('LINA: This path was here yesterday. I would swear it. The keeper on TWO ISLAND has the old map; maybe it can settle an argument with my own eyes.',
        'LINA: Gestern war hier noch ein Weg. Ich könnte es beschwören. Der Archivar auf EILAND ZWEI hat die alte Karte. Vielleicht traue ich meinen Augen danach wieder.'),done)
    elseif q.rescued then box(game,R.journal(),done)
    else
      box(game,tr('LINA: You found me! I have walked past this clearing three times. Even the shadows point the wrong way. Will you lead me to the southern exit? I will stay right behind you. If we get separated, I will wait here.',
        'LINA: Du hast mich gefunden! Ich bin schon dreimal an dieser Lichtung vorbeigekommen. Sogar die Schatten zeigen in die falsche Richtung. Führst du mich zum südlichen Ausgang? Ich bleibe dicht hinter dir. Falls wir uns verlieren, warte ich hier.'),
        function()if done then done()end;R.begin(game)end)
    end
    return true
  end
  ui.talks.KA_SEVII_LINA_ESCORT=function(game,ow,n,done)box(game,R.journal(),done);return true end
  ui.talks.KA_SEVII_LINA_HOME=function(game,ow,n,done)
    local s,q=state()
    if q.rescued and not q.complete then
      box(game,tr('LINA: Look! The old stones are in the same places on both maps. It is the paths between them that moved. Those stones must have held the forest in place.\n\nThis mark turns up again in a sketch of ICEFALL CAVE on FOUR ISLAND. An expedition disappeared there in a sudden freeze. If they left anything behind, it could tell us how the stones worked.',
        'LINA: Sieh nur! Die alten Steine liegen auf beiden Karten am selben Ort. Nur die Wege dazwischen haben sich verschoben. Die Steine müssen den Wald an seinem Platz gehalten haben.\n\nDas Zeichen taucht auch auf einer Skizze der EISKASKADENHÖHLE auf EILAND VIER auf. Dort verschwand eine Expedition bei einem plötzlichen Frosteinbruch. Vielleicht haben sie etwas hinterlassen, das uns weiterhilft.'),function()R.report(game);if done then done()end end)
    else box(game,R.journal(),done)end
    return true
  end
  return R
end
