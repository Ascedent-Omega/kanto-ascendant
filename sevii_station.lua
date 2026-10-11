-- Chapter five: a limited emergency supply, a physical airlock and a
-- three-member evacuation. The player's Pokemon follower stays untouched.
return function(S,ui)
  local P={SOURCE='FiveIsland_RocketWarehouse',sites={},costs={AIR=2,DOOR=1,RADIO=2}}
  local tr,box=ui.tr,ui.box
  local live={} -- actor handles are runtime-only, never save data
  local syncing=false
  local safeNpcList,safeCrewApplied
  local function state()
    local s=S.state();s.chapters=s.chapters or{};s.chapters.five=s.chapters.five or{}
    local q=s.chapters.five;q.circuits=q.circuits or{}
    return s,q
  end
  local function site(x,y)
    local map,lx,ly=S.location(P.SOURCE,x,y);assert(map,'missing station location')
    return {map=map,x=lx,y=ly}
  end
  P.map=site(24,24).map;P.gate=site(22,8)
  local function add(id,x,y,sprite,hidden)
    local p=site(x,y);P.sites[id]=p
    ui.npc(p.map,'KA_SEVII_STATION_'..id,sprite,'KA_SEVII_STATION_'..id,p.x,p.y)
    local objects=S.maps[p.map].objects;objects[#objects].hidden=hidden==true
  end
  add('NOAH',23,23,'SPRITE_SCIENTIST')
  add('CONSOLE',26,21,'SPRITE_POKEDEX')
  add('EMERGENCY',23,6,'SPRITE_PAPER')
  P.crew={
    {id='ADA',sprite='SPRITE_SILPH_WORKER_F',from={24,5},home={22,24}},
    {id='RORY',sprite='SPRITE_SAILOR',from={22,3},home={26,24}},
    {id='SEEL',sprite='SPRITE_SEEL',from={23,3},home={26,23}},
  }
  for _,c in ipairs(P.crew)do
    add(c.id,c.from[1],c.from[2],c.sprite)
    add(c.id..'_SAFE',c.home[1],c.home[2],c.sprite,true)
  end
  local function position(game)
    local ow=game and game.overworld;local p=ow and ow.player
    return ow and ow.map and p and {map=ow.map.id,x=p.cellX,y=p.cellY}
  end
  local function near(game,p)
    local here=position(game)
    return here and here.map==p.map and math.abs(here.x-p.x)+math.abs(here.y-p.y)==1
  end
  local function allowed(game,s)return S.unlocked(game)and s.chapterFourComplete==true end
  local function world()return ui.world and ui.world()end
  local function power(q)return q.isolated and q.circuits.AIR and q.circuits.DOOR end
  function P.load(q)
    if not q then local _;_,q=state()end
    local total=q.isolated and 0 or 3
    for key,cost in pairs(P.costs)do if q.circuits[key]then total=total+cost end end
    return total
  end
  function P.gateOpen()
    local _,q=state()
    return q.rescued==true or q.emergencyOpen==true or power(q)==true
  end
  local function removeCrew()
    local w=world()
    for _,id in pairs(live)do if w and w.removeNpc then w:removeNpc(id)end end
    live={}
  end
  local function visible(game,id,value)
    local old=game.save.objectToggles and game.save.objectToggles[P.map]
    local name='KA_SEVII_STATION_'..id
    if old and old[name]==value then return end
    local w=world();if w and w.toggleObject then w:toggleObject(P.map,name,value)end
  end
  local function actors(game,q)
    local w=world();if not(w and w.npc and w.spawnNpc)then return end
    for index,c in ipairs(P.crew)do
      local actor=live[index]and w:npc(P.map,live[index])
      local p=q.positions and q.positions[index]
      if not actor and p then
        live[index]=w:spawnNpc(P.map,{name='KA_SEVII_STATION_FOLLOW_'..c.id,
          sprite=c.sprite,movement='STAY',range='DOWN',text='KA_SEVII_STATION_FOLLOW',x=p.x,y=p.y})
        actor=live[index]and w:npc(P.map,live[index])
      end
      if actor then
        actor:setPassable(true)
        local x,y=actor:position()
        if p and math.abs(x-p.x)+math.abs(y-p.y)>1 then actor:placeAt(p.x,p.y)end
      end
    end
  end
  function P.install(game)
    if syncing or not(game and game.save)then return end
    syncing=true
    local s,q=state();local p=position(game)
    if q.escorting and p and (p.map~=P.map or not power(q))then
      q.escorting=false;q.positions=nil;q.trail=nil;q.lastPlayer=nil;q.separated=true
      S.persist(s);removeCrew()
    end
    for _,c in ipairs(P.crew)do
      visible(game,c.id,not q.escorting and not q.rescued)
      visible(game,c.id..'_SAFE',q.rescued==true)
    end
    -- The assembled actors are still the player's rescued companions.
    -- Keep their follower collision policy after the handoff: ADA's authored
    -- home cell is the sole exit from the western approach to assembly.
    -- Apply once per native NPC list, including already-rescued older saves;
    -- no per-frame SDK-handle allocations are added.
    if not q.rescued then safeNpcList=nil;safeCrewApplied=false
    elseif p and p.map==P.map and
        (not safeCrewApplied or safeNpcList~=game.overworld.npcs)then
      local w=world()
      if w and w.npc then
        for _,c in ipairs(P.crew)do
          local actor=w:npc(P.map,'KA_SEVII_STATION_'..c.id..'_SAFE')
          if actor then actor:setPassable(true)end
        end
        safeNpcList=game.overworld.npcs;safeCrewApplied=true
      end
    end
    local marked={}
    if P.gateOpen()then marked[P.gate.x..','..P.gate.y]=true end
    S.refreshCellPictures(game,'kaSeviiStationGate',marked)
    if q.escorting and p and p.map==P.map then actors(game,q)else removeCrew()end
    syncing=false
  end
  function P.begin(game)
    local s,q=state()
    if not allowed(game,s)then return false,'chapter-four-required'end
    if not near(game,P.sites.NOAH)then return false,'not-at-engineer'end
    if q.briefed then return false,'already-briefed'end
    q.briefed=true;S.persist(s);return true
  end
  function P.isolate(game)
    local s,q=state()
    if not allowed(game,s)or not q.briefed then return false,'briefing-required'end
    if not near(game,P.sites.CONSOLE)then return false,'not-at-console'end
    if q.isolated then return false,'already-isolated'end
    q.isolated=true;S.persist(s);P.install(game);return true
  end
  function P.toggle(game,key)
    local s,q=state()
    if not allowed(game,s)or not q.briefed or not q.isolated then return false,'isolate-probe'end
    if not near(game,P.sites.CONSOLE)then return false,'not-at-console'end
    if not P.costs[key]then return false,'unknown-circuit'end
    if q.escorting then return false,'evacuation-in-progress'end
    local enable=not q.circuits[key]
    if enable and P.load(q)+P.costs[key]>3 then return false,'overload'end
    q.circuits[key]=enable;S.persist(s);P.install(game);return true
  end
  function P.startRescue(game)
    local s,q=state();local p=position(game)
    if not allowed(game,s)or not q.briefed or not power(q)then return false,'air-and-door-required'end
    if not near(game,P.sites.ADA)then return false,'not-at-crew'end
    if q.escorting or q.rescued then return false,'already-evacuated-or-following'end
    q.escorting=true;q.separated=false;q.lastPlayer=p;q.positions={};q.trail={}
    for index=1,#P.crew do
      local origin=P.sites.ADA;q.positions[index]={map=origin.map,x=origin.x,y=origin.y}
      q.trail[index]={map=origin.map,x=origin.x,y=origin.y}
    end
    S.persist(s);P.install(game);return true
  end
  function P.arrive(game)
    local s,q=state();local p=position(game)
    if not allowed(game,s)or not q.escorting or not power(q)or not p or p.map~=P.map
        or p.x<22 or p.y<22 then return false,'not-at-assembly'end
    for _,a in ipairs(q.positions or{})do
      if a.map~=P.map or a.x<21 or a.y<21 then return false,'crew-still-in-corridor'end
    end
    if #(q.positions or{})~=#P.crew then return false,'crew-missing'end
    q.escorting=false;q.rescued=true;q.positions=nil;q.trail=nil;q.lastPlayer=nil
    S.persist(s);removeCrew();P.install(game);return true
  end
  function P.callMara(game)
    local s,q=state()
    if not allowed(game,s)or not q.rescued or not q.circuits.RADIO then return false,'rescue-and-radio-required'end
    if not near(game,P.sites.CONSOLE)then return false,'not-at-console'end
    if q.complete then return false,'already-reported'end
    q.complete=true;s.chapterFiveComplete=true;S.persist(s)
    if S.flight then S.flight.sync(game)end
    return true
  end
  function P.emergencyRelease(game)
    if not near(game,P.sites.EMERGENCY)then return false,'not-at-release'end
    -- A player whose older save was inside the room can always leave.
    -- This opens only the passage, never supplies air or completes rescue.
    local s,q=state();q.emergencyOpen=true;S.persist(s);P.install(game);return true
  end
  function P.onStep(game,ow,x,y)
    local s,q=state();if not q.escorting or ow.map.id~=P.map then return false end
    local previous=q.lastPlayer
    if not previous or previous.map~=P.map or math.abs(x-previous.x)+math.abs(y-previous.y)~=1 then
      q.escorting=false;q.positions=nil;q.trail=nil;q.lastPlayer=nil;q.separated=true
      S.persist(s);P.install(game);return false
    end
    table.insert(q.trail,1,previous);while #q.trail>#P.crew do table.remove(q.trail)end
    actors(game,q)
    local w=world()
    for index=1,#P.crew do
      local to=q.trail[index];local actor=w and live[index]and w:npc(P.map,live[index])
      if actor then
        local ax,ay=actor:position();local dx,dy=to.x-ax,to.y-ay
        if actor:isMoving()then actor:placeAt(ax,ay)end
        if math.abs(dx)+math.abs(dy)==1 then
          if actor.npc then actor.npc.stepFrames=ow.player.stepFramesCur or ow.player.stepFrames or 16 end
          actor:stepNow(dx==1 and'right'or dx==-1 and'left'or dy==1 and'down'or'up')
        elseif dx~=0 or dy~=0 then actor:placeAt(to.x,to.y)end
      end
      q.positions[index]={map=P.map,x=to.x,y=to.y}
    end
    q.lastPlayer={map=P.map,x=x,y=y};S.persist(s)
    if P.arrive(game)then
      box(game,tr('ADA, RORY and SEEL reach the assembly point. NOAH secures the airlock by hand.\n\nThe northern room is empty; its ventilation can be switched off. Redirect the emergency supply to RADIO and call MARA from the console.',
        'ADA, RORY und JUROB erreichen den Sammelplatz. NOAH sichert die Schleuse von Hand.\n\nDer Nordraum ist leer; seine Lüftung kann jetzt ausgeschaltet werden. Leite den Notstrom zum FUNK und rufe MARA an der Konsole.'))
      return true
    end
    return false
  end
  function P.journal()
    local _,q=state()
    if not q.briefed then return tr('EXPEDITION NOTES: Find engineer NOAH in GEZEITENLINIE station, the old warehouse east of FIVE ISLAND town.',
      'EXPEDITIONSNOTIZEN: Suche den Techniker NOAH in der Station GEZEITENLINIE, dem alten Lagerhaus östlich des Orts auf EILAND FÜNF.')end
    if not q.isolated then return tr('NOAH: The probe is drawing all three units and amplifying the rift. Disconnect it at the console beside the entrance. We did not create this crossing; we must stop feeding it.',
      'NOAH: Die Sonde zieht alle drei Einheiten und verstärkt den Riss. Klemme sie an der Konsole neben dem Eingang ab. Wir haben den Übergang nicht geschaffen; wir müssen aufhören, ihn zu speisen.')end
    if not q.rescued then return tr('STATION PLAN: Three power units. AIR needs two, DOOR needs one, RADIO needs two. First supply AIR and DOOR. Follow the eastern corridor north to the airlock, meet ADA and lead her group back to the entrance. If separated, meet them in the same room.',
      'STATIONSPLAN: Drei Stromeinheiten. LUFT braucht zwei, SCHLEUSE eine, FUNK zwei. Versorge zuerst LUFT und SCHLEUSE. Folge dem östlichen Gang nach Norden zur Schleuse, triff ADA und führe ihre Gruppe zum Eingang zurück. Bei Trennung warten sie wieder im gleichen Raum.')end
    if not q.complete then return tr('NOAH: Everyone is safe. Switch AIR off at the console, supply RADIO and choose CALL MARA. The door is secured mechanically.',
      'NOAH: Alle sind in Sicherheit. Schalte an der Konsole LUFT aus, versorge FUNK und wähle MARA RUFEN. Die Tür ist mechanisch gesichert.')end
    return tr('EXPEDITION NOTES: MARA recognised a crossing through the Distortion World. The paired marks on SIX ISLAND\'s ruins match the station readings. Bring the recovered record to RUIN VALLEY.',
      'EXPEDITIONSNOTIZEN: MARA erkannte einen Übergang durch die Zerrwelt. Die paarigen Zeichen in den Ruinen auf EILAND SECHS passen zu den Stationsmessungen. Bring das gesicherte Protokoll ins RUINENTAL.')
  end
  local function menu(game,done)
    local _,q=state();local Menu=ui.menu or require('src.ui.ListMenu')
    local names={AIR=tr('AIR','LUFT'),DOOR=tr('AIRLOCK','SCHLEUSE'),RADIO=tr('RADIO','FUNK')}
    local items={}
    if not q.isolated then items[#items+1]={label=tr('DISCONNECT PROBE','SONDE ABKLEMMEN'),value='ISOLATE'}end
    for _,key in ipairs{'AIR','DOOR','RADIO'}do
      items[#items+1]={label=names[key]..' '..P.costs[key]..' '..(q.circuits[key]and tr('ON','AN')or tr('OFF','AUS')),value=key}
    end
    if q.rescued and not q.complete then items[#items+1]={label=tr('CALL MARA','MARA RUFEN'),value='CALL'}end
    items[#items+1]={label=tr('CLOSE','SCHLIESSEN'),value='CLOSE'}
    local help={
      ISOLATE=tr('Uses all 3 units. Disconnect the probe before assigning power.',
        'Belegt alle 3 Einheiten. Vor dem Verteilen Sonde abklemmen.'),
      AIR=tr('2 units. Ventilate the north room until everyone is safe.',
        '2 Einheiten. Nordraum belüften, bis alle in Sicherheit sind.'),
      DOOR=tr('1 unit. Needs AIR to open the north room.',
        '1 Einheit. Braucht LUFT, um den Nordraum zu öffnen.'),
      RADIO=tr('2 units. Power the radio after evacuation to call MARA.',
        '2 Einheiten. Nach der Rettung einschalten und MARA rufen.'),
      CALL=tr('Call MARA with the rescue report. Needs RADIO.',
        'MARA den Rettungsbericht senden. Benötigt FUNK.'),
      CLOSE=tr('Leave the console. Your settings are saved.',
        'Konsole verlassen. Die Verteilung bleibt gespeichert.'),
    }
    local panel=Menu.new(game,tr('POWER ','LAST ')..P.load(q)..'/3',items,{
      kind='sevii-station-power',ascendantFocusHelp=function(item)return item and help[item.value]or''end,
      onCancel=done,onChoose=function(item)
      game.stack:pop()
      if item.value=='CLOSE'then if done then done()end;return end
      if item.value=='CALL'then
        if not q.circuits.RADIO then box(game,tr('The radio has no power.','Der Funk hat keinen Strom.'),function()menu(game,done)end);return end
        box(game,tr('MARA: I can hear them! You got everyone out. Rory says he stepped through a reflection in Sinnoh and fell into the station. He saw no horizon on the way.\n\nHagen\'s record describes a place like that. In Sinnoh they call it the Distortion World. Our probe did not open the crossing, but it gave the thing beyond it a stronger path.\n\nThe readings match old marks in RUIN VALLEY on SIX ISLAND. Take the record there. And with the radio working again, you can fly to islands you have visited.',
          'MARA: Ich kann sie hören! Du hast alle herausgeholt. Rory sagt, er trat in Sinnoh durch ein Spiegelbild und fiel in die Station. Dazwischen gab es keinen Horizont.\n\nHagens Protokoll beschreibt so einen Ort. In Sinnoh nennt man ihn die Zerrwelt. Unsere Sonde hat den Übergang nicht geöffnet, aber sie hat dem Wesen dahinter den Weg erleichtert.\n\nDie Messungen passen zu alten Zeichen im RUINENTAL auf EILAND SECHS. Bring das Protokoll dorthin. Und da der Funk wieder läuft, kannst du bereits besuchte Eilande anfliegen.'),
          function()P.callMara(game);if done then done()end end)
        return
      end
      local ok,why
      if item.value=='ISOLATE'then ok,why=P.isolate(game)else ok,why=P.toggle(game,item.value)end
      if ok then menu(game,done);return end
      local text=why=='overload'and tr('Overload: the generator supplies only three units. Switch another branch off first.',
        'Überlast: Der Generator liefert nur drei Einheiten. Schalte zuerst einen anderen Zweig aus.')or P.journal()
      box(game,text,function()menu(game,done)end)
    end})
    panel.__vascHeaderLabel='GEZEITENLINIE'
    game.stack:push(panel)
  end
  ui.talks.KA_SEVII_STATION_NOAH=function(game,ow,n,done)
    local s,q=state()
    if not allowed(game,s)then box(game,tr('NOAH: The station is in emergency mode. HAGEN on FOUR ISLAND is investigating the old seal. We need his record before changing the probe circuit.',
      'NOAH: Die Station läuft im Notbetrieb. HAGEN auf EILAND VIER untersucht das alte Siegel. Wir brauchen sein Protokoll, bevor wir den Sondenkreis verändern.'),done)
    elseif not q.briefed then box(game,tr('NOAH: That record explains the surge. Our probe is feeding the crossing! Ada, a traveller and his SEEL are trapped in the north-east room.\n\nWe have three units of emergency power. Cut the probe at the console beside me, then give two units to AIR and one to the AIRLOCK. Once they are safe, we can power the radio. I will stay here and keep the entrance clear.',
      'NOAH: Jetzt verstehe ich den Stromstoß. Unsere Sonde speist den Übergang! Ada, ein Reisender und sein JUROB sitzen im nordöstlichen Raum fest.\n\nWir haben drei Einheiten Notstrom. Klemme die Sonde an der Konsole neben mir ab, gib zwei Einheiten an LUFT und eine an die SCHLEUSE. Wenn alle draußen sind, können wir den Funk versorgen. Ich halte hier den Eingang frei.'),
      function()P.begin(game);if done then done()end end)
    else box(game,P.journal(),done)end
    return true
  end
  ui.talks.KA_SEVII_STATION_CONSOLE=function(game,ow,n,done)
    local s,q=state()
    if not allowed(game,s)or not q.briefed then box(game,P.journal(),done)else menu(game,done)end
    return true
  end
  ui.talks.KA_SEVII_STATION_ADA=function(game,ow,n,done)
    local s,q=state()
    if not allowed(game,s)or not power(q)or q.rescued then box(game,P.journal(),done)
    else box(game,tr('ADA: Fresh air! Rory and his SEEL came out of the reflection in our tank. One moment he was in Sinnoh, the next he was here.\n\nCan you get us to Noah by the entrance? We will follow. If we lose you, we will wait here.',
      'ADA: Frische Luft! Rory und sein JUROB kamen aus dem Spiegelbild in unserem Becken. Eben war er noch in Sinnoh, dann stand er hier.\n\nBringst du uns zu Noah am Eingang? Wir folgen dir. Falls wir dich verlieren, warten wir hier.'),
      function()P.startRescue(game);if done then done()end end)
    end
    return true
  end
  ui.talks.KA_SEVII_STATION_EMERGENCY=function(game,ow,n,done)
    box(game,tr('An emergency release on the inside of the airlock. It opens a way out without powering the ventilation.',
      'Ein Notriegel auf der Innenseite der Schleuse. Er öffnet einen Fluchtweg, ohne die Lüftung zu versorgen.'),
      function()P.emergencyRelease(game);if done then done()end end);return true
  end
  for _,id in ipairs{'RORY','RORY_SAFE'}do
    ui.talks['KA_SEVII_STATION_'..id]=function(game,ow,n,done)
      box(game,tr('RORY: I was beside a harbour in Sinnoh. SEEL dived at a reflection; I reached for him. For a moment the sea hung above us. Then we fell into this station. I want to go home, but not through that place again.',
        'RORY: Ich stand an einem Hafen in Sinnoh. JUROB tauchte nach einem Spiegelbild; ich griff nach ihm. Für einen Augenblick hing das Meer über uns. Dann fielen wir in diese Station. Ich will nach Hause, aber nie wieder durch diesen Ort.'),done);return true
    end
  end
  for _,id in ipairs{'SEEL','SEEL_SAFE'}do
    ui.talks['KA_SEVII_STATION_'..id]=function(game,ow,n,done)
      box(game,tr('SEEL presses close to RORY. Its fur still smells of salt water.',
        'JUROB bleibt dicht bei RORY. Sein Fell riecht noch nach Salzwasser.'),done);return true
    end
  end
  ui.talks.KA_SEVII_STATION_ADA_SAFE=function(game,ow,n,done)
    box(game,P.journal(),done);return true
  end
  ui.talks.KA_SEVII_STATION_FOLLOW=function(game,ow,n,done)
    box(game,tr('ADA: Keep going to the entrance. We are right behind you.',
      'ADA: Weiter zum Eingang. Wir sind direkt hinter dir.'),done);return true
  end
  return P
end
