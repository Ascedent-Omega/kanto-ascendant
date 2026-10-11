-- The expedition's local ending: native Strength puzzle, three relays,
-- a nonbattle sealing scene and a persistent, explorable aftermath.
return function(S,ui)
  local P={sites={},stones={},sockets={{5,4},{7,4},{9,4}}}
  local tr,box=ui.tr,ui.box
  local syncing=false
  local function state()
    local s=S.state();s.chapters=s.chapters or{};s.chapters.seven=s.chapters.seven or{}
    return s,s.chapters.seven
  end
  local function add(id,source,x,y,sprite,hidden)
    local map,lx,ly=S.location(source,x,y);assert(map,'missing finale site '..id)
    local p={map=map,x=lx,y=ly,name='KA_SEVII_FINALE_'..id};P.sites[id]=p
    ui.npc(map,p.name,sprite,p.name,lx,ly)
    local objs=S.maps[map].objects;objs[#objs].hidden=hidden==true;objs[#objs].pushable=false
    return p
  end
  add('CAMP','SevenIsland_SevaultCanyon_House',2,3,'SPRITE_SCIENTIST')
  add('RADIO','SevenIsland_SevaultCanyon_TanobyKey',7,2,'SPRITE_POKEDEX')
  for i,xy in ipairs{{6,8},{7,9},{8,8}}do
    P.stones[i]=add('STONE_'..i,'SevenIsland_SevaultCanyon_TanobyKey',xy[1],xy[2],'SPRITE_BOULDER')
  end
  P.keyMap=P.sites.RADIO.map
  P.relays={
    {id='WEST',source='SevenIsland_TanobyRuins_MoneanChamber',en='TESS / WEST',de='TESS / WESTEN'},
    {id='MIDDLE',source='SevenIsland_TanobyRuins_DilfordChamber',en='SILAS / CENTRE',de='SILAS / MITTE'},
    {id='EAST',source='SevenIsland_TanobyRuins_ViapoisChamber',en='ENNO / EAST',de='ENNO / OSTEN'},
  }
  for _,r in ipairs(P.relays)do add(r.id,r.source,11,6,'SPRITE_SCIENTIST',true)end
  -- The control lectern is on the side, leaving the central passage clear.
  add('SEAL','SevenIsland_TanobyRuins_DilfordChamber',8,9,'SPRITE_POKEDEX')
  local function near(game,p)
    local ow=game and game.overworld;local a=ow and ow.player
    return ow and a and ow.map.id==p.map and math.abs(a.cellX-p.x)+math.abs(a.cellY-p.y)==1
  end
  local function allowed(game,s)return S.unlocked(game)and s.chapterSixComplete==true end
  local function world()return ui.world and ui.world()end
  local function actor(p)local w=world();return w and w.npc and w:npc(p.map,p.name)end
  local function nearStone(game)
    for _,p in ipairs(P.stones)do
      local a=actor(p)
      if a then local x,y=a:position();if near(game,{map=p.map,x=x,y=y})then return true end end
    end
    return false
  end
  local function positions(q)
    local out={}
    for i,p in ipairs(P.stones)do out[i]=q.positions and q.positions[i]or{x=p.x,y=p.y}end
    return out
  end
  function P.install(game)
    if syncing or not(game and game.save)then return end
    syncing=true
    local s,q=state();local w=world()
    for _,r in ipairs(P.relays)do
      local p=P.sites[r.id];local old=game.save.objectToggles and game.save.objectToggles[p.map]
      local show=q.calibrated==true
      if w and w.toggleObject and(not old or old[p.name]~=show)then w:toggleObject(p.map,p.name,show)end
    end
    if game.overworld and game.overworld.map and game.overworld.map.id==P.keyMap then
      for i,p in ipairs(P.stones)do
        local a=actor(p);local pos=positions(q)[i]
        if a then
          a:placeAt(pos.x,pos.y)
          a.npc.def.pushable=allowed(game,s)and q.briefed==true and not q.calibrated
        end
      end
    end
    syncing=false
  end
  function P.begin(game)
    local s,q=state()
    if not allowed(game,s)or not near(game,P.sites.CAMP)or q.briefed then return false end
    q.briefed=true;S.persist(s);P.install(game);return true
  end
  function P.support(game)
    local s,q=state()
    if not allowed(game,s)or not q.briefed or q.calibrated then return false end
    if not near(game,P.sites.RADIO)and not nearStone(game)then return false end
    -- Expedition equipment provides assistance even with no Strength user.
    -- Actual pushes still go through the engine's collision and animation.
    game.overworld.strengthActive=true;return true
  end
  function P.reset(game)
    local s,q=state()
    if not allowed(game,s)or not q.briefed or q.calibrated then return false end
    if not near(game,P.sites.RADIO)and not nearStone(game)then return false end
    q.positions=nil;S.persist(s)
    return world():warpTo(P.keyMap,7,12,'up')==true
  end
  function P.onBoulderMoved(game,ow,npc)
    if ow.map.id~=P.keyMap then return end
    local s,q=state();if not allowed(game,s)or not q.briefed or q.calibrated then return end
    local ours=false;for _,p in ipairs(P.stones)do if npc.def.name==p.name then ours=true end end
    if not ours then return end
    q.positions={};local occupied={}
    for i,p in ipairs(P.stones)do
      local a=assert(actor(p),'missing calibration stone');local x,y=a:position()
      q.positions[i]={x=x,y=y};occupied[x..','..y]=true
    end
    local ready=not occupied['7,6']
    for _,p in ipairs(P.sockets)do ready=ready and occupied[p[1]..','..p[2]]==true end
    if ready then q.calibrated=true;q.relays=q.relays or{}end
    S.persist(s)
    if ready then
      P.install(game)
      box(game,tr('Three sockets answer in one steady tone. The middle stays clear. Your portable anchor cores take up the rhythm; the heavy calibration stones lock in place.\n\nThe team is waiting in the western, middle and eastern TANOBY chambers. Bring a core to each member.',
        'Drei Mulden antworten in einem ruhigen Ton. Die Mitte bleibt frei. Deine tragbaren Ankerkerne nehmen den Takt auf; die schweren Kalibriersteine rasten ein.\n\nDas Team wartet in der westlichen, mittleren und östlichen TANOBY-Kammer. Bring jedem Mitglied einen Kern.'))
    end
  end
  function P.placeRelay(game,id)
    local s,q=state();local valid=false
    for _,r in ipairs(P.relays)do if r.id==id then valid=true end end
    if not valid or not allowed(game,s)or not q.calibrated or not near(game,P.sites[id])then return false end
    q.relays=q.relays or{};if q.relays[id]then return false end
    q.relays[id]=true;S.persist(s);return true
  end
  function P.ready()
    local _,q=state();for _,r in ipairs(P.relays)do if not(q.relays and q.relays[r.id])then return false end end
    return q.calibrated==true
  end
  function P.seal(game,done)
    local s,q=state()
    if not allowed(game,s)or not near(game,P.sites.SEAL)then return false,'not-at-seal'end
    if s.seviiRiftSealed then return false,'already-sealed'end
    if not P.ready()then return false,'relays-required'end
    return ui.apparition.open(game,ui.assetRoot,tr,function()
      local current,r=state();current.seviiRiftSealed=true
      r.sealed=true;r.outcome='LOCAL_RIFT_SEALED';r.antagonistRemains=true
      S.persist(current)
      box(game,tr('TESS: The western current is steady!\nENNO: The eastern sky is clear!\nSILAS: The gap has closed.\n\nMARA, over the radio: The buoys agree again. You did it. Sevii is safe. Giratina remains beyond the boundary, but this crossing no longer reaches our islands. Return to the canyon field camp; everyone is waiting.',
        'TESS: Die westliche Strömung ist ruhig!\nENNO: Der östliche Himmel ist klar!\nSILAS: Der Spalt ist geschlossen.\n\nMARA, über Funk: Die Bojen stimmen wieder überein. Du hast es geschafft. Sevii ist sicher. Giratina bleibt jenseits der Grenze, aber dieser Übergang erreicht unsere Inseln nicht mehr. Komm zum Feldlager im Canyon; alle warten.'),done)
    end,{finale=true})
  end
  function P.report(game)
    local s,q=state()
    if not allowed(game,s)or not near(game,P.sites.CAMP)or not s.seviiRiftSealed or q.complete then return false end
    q.complete=true;q.recognition='SEVII_EXPEDITION';s.chapterSevenComplete=true
    s.expeditionComplete=true;s.futureRiftLead='DISTANT_UNCHARTED_SIGNAL'
    S.persist(s)
    local received,why=P.claimGsBall(game)
    return true,received and'gs-ball' or why
  end
  function P.claimGsBall(game)
    local s,q=state()
    if not q.complete or q.gsBallDelivered then return false,'unavailable'end
    if q.gsBallGranted then return false,'already-granted'end
    if not near(game,P.sites.CAMP)then return false,'not-at-camp'end
    local save=game and game.save
    if not(save and game.data and game.data.items and game.data.items.GS_BALL)then
      return false,'item-unavailable'
    end
    if (save.inventory or{}).GS_BALL then
      q.gsBallGranted=true;S.persist(s);return true,'already-carried'
    end
    if not require('src.inventory.Bag').add(save,'GS_BALL',1,game.data)then
      return false,'bag-full'
    end
    q.gsBallGranted=true;S.persist(s);return true,'received'
  end
  function P.consultOakAboutGsBall(game)
    local s,q=state();local save=game and game.save
    if not(q.complete and q.gsBallGranted)or q.gsBallOakConsulted
        or not(save and game.overworld and game.overworld.map
          and game.overworld.map.id=='OAKS_LAB')then return false end
    if not((save.inventory or{}).GS_BALL and (save.inventory or{}).GS_BALL>0)then
      return false
    end
    q.gsBallOakConsulted=true
    s.orangeIslandsLead='IVY_GS_BALL'
    S.persist(s);return true
  end
  function P.journal()
    local s,q=state()
    if q.complete then
      if q.gsBallOakConsulted then return tr('SEVII COMPLETE: Professor Oak asked you to keep the GS Ball and return later. He is asking his friend Professor Ivy for advice. The islands remain open; the distant signal is still unexplained.',
        'SEVII ABGESCHLOSSEN: Professor Eich bat dich, den GS-Ball zu behalten und später wiederzukommen. Er fragt seine Freundin Professorin Ivy um Rat. Die Inseln bleiben offen; das ferne Signal ist noch ungeklärt.')end
      if q.gsBallGranted then return tr('SEVII COMPLETE: Selma entrusted you with the GS Ball. Bring it to Professor Oak in Pallet Town. The islands remain open, and the distant signal remains unexplained.',
        'SEVII ABGESCHLOSSEN: Selma hat dir den GS-Ball anvertraut. Bring ihn zu Professor Eich in Alabastia. Die Inseln bleiben offen, das ferne Signal ist noch ungeklärt.')end
      return tr('SEVII COMPLETE: Selma is keeping the GS Ball safe at the canyon camp. Make room in your Key Items and speak to her again, then bring it to Professor Oak.',
        'SEVII ABGESCHLOSSEN: Selma bewahrt den GS-Ball im Canyon-Feldlager auf. Schaffe Platz bei den Basis-Items und sprich sie erneut an. Bring ihn danach zu Professor Eich.')
    end
    if s.seviiRiftSealed then return tr('MARA: Return to the field camp in the house in southern SEVAULT CANYON. The islands are safe; the expedition can finally come home.',
      'MARA: Kehre zum Feldlager im Haus im südlichen SEVAE-CANYON zurück. Die Inseln sind sicher; die Expedition kann endlich heimkehren.')end
    if not q.briefed then return tr('MARA: Meet SELMA in the field camp: the house in southern SEVAULT CANYON on SEVEN ISLAND, above TANOBY RUINS.',
      'MARA: Triff SELMA im Feldlager: im Haus im südlichen SEVAE-CANYON auf EILAND SIEBEN, oberhalb der TANOBY-RUINEN.')end
    if not q.calibrated then return tr('SELMA: In TANOBY KEY, the cave in northern SEVAULT CANYON, push the three stones onto the three marked sockets in the upper row. The centre below stays empty. Talk to a stone for lifting assistance or to reset the puzzle. Completed pushes are saved.',
      'SELMA: Schiebe im TANOBY-SCHLÜSSEL, der Höhle im nördlichen SEVAE-CANYON, drei Steine auf die drei markierten Mulden der oberen Reihe. Die Mitte darunter bleibt frei. Sprich einen Stein an, um Hebehilfe zu erhalten oder das Rätsel zurückzusetzen. Ausgeführte Schübe werden gespeichert.')end
    if not P.ready()then
      local missing={};for _,r in ipairs(P.relays)do if not(q.relays and q.relays[r.id])then missing[#missing+1]=tr(r.en,r.de)end end
      return tr('Charged cores ready. Deliver them to the three outer anchor teams: ','Geladene Kerne bereit. Bringe sie zu den drei Ankerteams: ')..table.concat(missing,', ')..tr('. Visit the far western, middle and far eastern chambers along TANOBY RUINS. You will need SURF.',
        '. Besuche die ganz westliche, mittlere und ganz östliche Kammer der TANOBY-RUINEN. Du brauchst SURFER.')
    end
    return tr('All three anchors answer. Use the control lectern in the middle TANOBY chamber, beside the open central passage. Keep the centre free; close the crossing from this side.',
      'Alle drei Anker antworten. Benutze das Steuerpult in der mittleren TANOBY-Kammer neben dem freien Mittelgang. Halte die Mitte frei; schließe den Übergang von dieser Seite.')
  end
  local function stoneMenu(game,done)
    local s,q=state()
    if not allowed(game,s)or not q.briefed or q.calibrated then box(game,P.journal(),done);return end
    local Menu=ui.menu or require('src.ui.ListMenu')
    local panel=Menu.new(game,tr('ANCHOR STONES','ANKERSTEINE'),{
      {label=tr('Lifting assistance','Hebehilfe'),value='SUPPORT'},
      {label=tr('Reset stones','Steine zurücksetzen'),value='RESET'},
      {label=tr('Read instructions','Anleitung lesen'),value='HELP'},
      {label=tr('Back','Zurück'),value='BACK'},
    },{kind='sevii-anchor-stones',onCancel=done,onChoose=function(item)
      game.stack:pop()
      if item.value=='SUPPORT'then
        if P.support(game)then box(game,tr('The expedition lifting braces are ready. Walk against a stone to push it one cell. Three sockets above; leave the middle empty.',
          'Die Hebehilfe der Expedition ist bereit. Gehe gegen einen Stein, um ihn ein Feld zu schieben. Drei Mulden oben; die Mitte bleibt leer.'),done)
        elseif done then done()end
      elseif item.value=='RESET'then if done then done()end;P.reset(game)
      elseif item.value=='HELP'then box(game,P.journal(),done)
      elseif done then done()end
    end})
    panel.__vascHeaderLabel=tr('ANCHOR STONES','ANKERSTEINE');game.stack:push(panel)
  end
  ui.talks.KA_SEVII_FINALE_RADIO=function(game,ow,n,done)stoneMenu(game,done);return true end
  for i=1,3 do ui.talks['KA_SEVII_FINALE_STONE_'..i]=ui.talks.KA_SEVII_FINALE_RADIO end
  ui.talks.KA_SEVII_FINALE_CAMP=function(game,ow,n,done)
    local s,q=state()
    if not allowed(game,s)then box(game,tr('SELMA: We need the boundary plan from DOTTED HOLE before risking a crossing. Iona is examining those ruins on SIX ISLAND.',
      'SELMA: Wir brauchen den Grenzplan aus dem PUNKTLOCH, bevor wir einen Übergang riskieren. Iona untersucht die Ruinen auf EILAND SECHS.'),done)
    elseif not q.briefed then box(game,tr('SELMA: Iona\'s plan calls for three anchors and a clear centre. There is an old stone chamber in TANOBY KEY, north in SEVAULT CANYON. I think it was built for this.\n\nOur lifting braces will help with the stones. Charge the three cores there, and Tess, Silas and Enno will carry them to the TANOBY chambers. We shut the crossing from this side. Nobody follows Giratina through.',
      'SELMA: Ionas Plan zeigt drei Anker und eine freie Mitte. Im TANOBY-SCHLÜSSEL, nördlich im SEVAE-CANYON, liegt eine alte Steinkammer. Ich glaube, dafür wurde sie gebaut.\n\nUnsere Hebehilfe erleichtert dir die Arbeit mit den Steinen. Lade dort die drei Kerne auf, dann bringen Tess, Silas und Enno sie in die TANOBY-Kammern. Wir schließen den Übergang von hier aus. Niemand folgt Giratina hindurch.'),function()P.begin(game);if done then done()end end)
    elseif s.seviiRiftSealed and not q.complete then box(game,tr('SELMA: Listen to that. The ferries are back on course. Lina and the station crew are home. And those Pokemon that found their way here? They are part of the islands now.\n\nMara wants you to have this expedition commendation. You brought everyone through. There is one more radio reading: the same pulse, far beyond our charts. Giratina has not stopped moving.',
      'SELMA: Hör nur. Die Fähren halten wieder Kurs. Lina und die Stationsleute sind zu Hause. Und die Pokemon, die hierhergefunden haben? Sie gehören jetzt zu den Inseln.\n\nMara möchte dir diese Expeditionsauszeichnung geben. Du hast uns alle da durchgebracht. Es gibt noch eine Funkmeldung: derselbe Puls, weit jenseits unserer Karten. Giratina zieht weiter.'),function()
        local ok,why=P.report(game)
        if not ok then if done then done()end;return end
        local message=why=='gs-ball'and tr('SELMA: We found this unusual GS Ball among the old anchor cases. Take it to Professor Oak in Pallet Town. Perhaps he can tell us why it answered the signal.',
          'SELMA: Zwischen den alten Ankerkisten lag dieser seltsame GS-Ball. Bring ihn zu Professor Eich in Alabastia. Vielleicht erkennt er, warum er auf das Signal reagiert hat.')
          or tr('SELMA: Your Key Items are full. I will keep the GS Ball safe here. Come back when you have room; Professor Oak should examine it.',
            'SELMA: Bei deinen Basis-Items ist kein Platz. Ich bewahre den GS-Ball hier auf. Komm wieder, sobald Platz ist; Professor Eich sollte ihn untersuchen.')
        box(game,message,done)
      end)
    elseif q.complete and not q.gsBallGranted then
      local got=P.claimGsBall(game)
      box(game,got and tr('SELMA: Here is the GS Ball. Professor Oak in Pallet Town will want to see it.',
        'SELMA: Hier ist der GS-Ball. Professor Eich in Alabastia sollte ihn sehen.')
        or P.journal(),done)
    else box(game,P.journal(),done)end
    return true
  end
  for _,r in ipairs(P.relays)do local id=r.id
    ui.talks['KA_SEVII_FINALE_'..id]=function(game,ow,n,done)
      local s,q=state()
      if s.seviiRiftSealed then box(game,tr('The anchor is steady. We will maintain this boundary; take your time exploring the islands.',
        'Der Anker ist ruhig. Wir halten diese Grenze instand; erkunde die Inseln in Ruhe.'),done)
      elseif not q.calibrated or(q.relays and q.relays[id])then box(game,P.journal(),done)
      else box(game,tr('The core settles into its cradle. The team checks the line back to the middle chamber. This anchor is ready; the central passage must remain empty.',
        'Der Kern rastet in seine Halterung ein. Das Team prüft die Verbindung zur mittleren Kammer. Dieser Anker ist bereit; der Mittelgang muss frei bleiben.'),function()P.placeRelay(game,id);if done then done()end end)end
      return true
    end
  end
  ui.talks.KA_SEVII_FINALE_SEAL=function(game,ow,n,done)
    local ok,why=P.seal(game,done)
    if not ok then
      if why=='missing-art'or why=='unreadable-art'then box(game,tr('The sealing scene artwork is missing. Restore the Sevii art package and return; your prepared anchors are saved.',
        'Die Grafik der Siegelszene fehlt. Stelle das Sevii-Grafikpaket wieder her und kehre zurück; deine vorbereiteten Anker bleiben gespeichert.'),done)
      else box(game,P.journal(),done)end
    end
    return true
  end
  return P
end
