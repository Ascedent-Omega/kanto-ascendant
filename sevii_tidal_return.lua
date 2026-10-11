-- A repaired survey boat follows three physically visited shore signals.
-- The rescued actor moves home persistently; both captures remain optional.
return function(S,ui)
  local T={KEY='tidalReturn',sites={}};local E=assert(S.specialEncounters)
  local tr,box=ui.tr,ui.box;local syncing=false
  local function state()
    local s=S.state();s.mysteries=s.mysteries or{};s.mysteries[T.KEY]=s.mysteries[T.KEY]or{}
    return s,s.mysteries[T.KEY]
  end
  function T.record()local _,q=state();return q end
  local function add(id,source,x,y,sprite,hidden)
    local m,lx,ly=S.location(source,x,y);assert(m and S.walkable(m,lx,ly),'blocked tidal site '..id)
    for _,n in ipairs(S.maps[m].objects)do assert(n.x~=lx or n.y~=ly,'occupied tidal site '..id)end
    for _,w in ipairs(S.links[m])do assert(math.abs(w.x-lx)+math.abs(w.y-ly)>1,'tidal site blocks door '..id)end
    local p={map=m,x=lx,y=ly,name='KA_SEVII_TIDE_'..id};T.sites[id]=p
    ui.npc(m,p.name,sprite,p.name,lx,ly);S.maps[m].objects[#S.maps[m].objects].hidden=hidden==true
    return p
  end
  add('TAMO','SixIsland_WaterPath_House1',3,3,'SPRITE_SCIENTIST')
  add('NERI','SixIsland_OutcastIsland',9,24,'SPRITE_COOLTRAINER_F')
  add('PLANK','SixIsland_GreenPath',12,7,'SPRITE_PAPER')
  add('NORTH','SixIsland_OutcastIsland',16,24,'SPRITE_POKEDEX')
  add('MIDDLE','SixIsland_GreenPath',15,6,'SPRITE_POKEDEX')
  add('SOUTH','SixIsland_WaterPath',18,21,'SPRITE_POKEDEX')
  add('HOME','SixIsland_WaterPath_House1',8,6,'SPRITE_COOLTRAINER_F',true)
  add('PHIONE','SixIsland_GreenPath',11,10,'SPRITE_BOULDER')
  add('MANAPHY','SixIsland_WaterPath',12,60,'SPRITE_BOULDER')
  T.order={'NORTH','MIDDLE','SOUTH'}
  local function gate(game,id)
    if not E.near(game,T.sites[id])then return false,'not-at-site'end
    return E.storyReady(game)
  end
  local function begun(game,id)
    local ok,why=gate(game,id);if not ok then return false,why end
    if not T.record().briefed then return false,'briefing-required'end
    return true
  end
  function T.install(game)
    if syncing or not(game and game.save)then return end
    local w=ui.world and ui.world();if not(w and w.toggleObject)then return end
    syncing=true;local q=T.record()
    for _,row in ipairs{{'NERI',not q.returned and(q.signals or 0)==0},{'HOME',q.returned==true}}do
      local p=T.sites[row[1]];local old=game.save.objectToggles and game.save.objectToggles[p.map]
      if not old or old[p.name]~=row[2]then w:toggleObject(p.map,p.name,row[2])end
    end
    syncing=false
  end
  function T.begin(game)
    local ok,why=gate(game,'TAMO');if not ok then return false,why end
    local s,q=state();if q.briefed then return false,'already-briefed'end
    q.briefed=true;S.persist(s);return true
  end
  function T.requestRepair(game)
    local ok,why=begun(game,'NERI');if not ok then return false,why end
    local s,q=state();if q.returned then return false,'already-home'end
    if q.requested then return false,'already-requested'end
    q.requested=true;S.persist(s);return true
  end
  function T.collect(game)
    local ok,why=begun(game,'PLANK');if not ok then return false,why end
    local s,q=state();if not q.requested then return false,'neri-required'end
    if q.plankTaken then return false,'already-collected'end
    -- Expedition cargo cannot be sold, duplicated or lost to a full Bag.
    q.plankTaken=true;q.plank=true;S.persist(s);return true
  end
  function T.repair(game)
    local ok,why=begun(game,'NERI');if not ok then return false,why end
    local s,q=state();if q.repaired then return false,'already-repaired'end
    if not(q.requested and q.plank)then return false,'plank-required'end
    q.plank=false;q.repaired=true;q.signals=0;S.persist(s);return true
  end
  function T.signal(game,id)
    local index;for i,site in ipairs(T.order)do if site==id then index=i end end
    if not index then return false,'unknown-signal'end
    local ok,why=begun(game,id);if not ok then return false,why end
    local s,q=state();if q.returned then return false,'already-home'end
    if not q.repaired then return false,'repair-required'end
    local nextIndex=(q.signals or 0)+1
    if index~=nextIndex then return false,index<nextIndex and'already-signalled'or'wrong-signal'end
    q.signals=index;q.returned=index==#T.order;S.persist(s);T.install(game);return true
  end
  function T.checkIn(game)
    local ok,why=begun(game,'HOME');if not ok then return false,why end
    local s,q=state();if not q.returned then return false,'return-required'end
    if q.checkedIn then return false,'already-checked-in'end
    q.checkedIn=true;S.persist(s);return true
  end
  function T.report(game)
    local ok,why=begun(game,'TAMO');if not ok then return false,why end
    local s,q=state();if q.complete then return false,'already-complete'end
    if not(q.returned and q.checkedIn)then return false,'check-in-required'end
    q.complete=true;q.title='SEVII_TIDAL_RETURN';S.persist(s);return true
  end
  for _,row in ipairs{{'PHIONE',489,55},{'MANAPHY',490,65}}do
    E.register(row[1],{dex=row[2],level=row[3],site=T.sites[row[1]],owner='sevii_tidal_return.lua',
      ready=function()return T.record().complete==true end})
  end
  function T.journal()
    local q=T.record()
    if not q.briefed then return tr('THE WAY HOME: Visit TAMO in the marine research house on SIX ISLAND\'s WATER PATH after the expedition. A survey boat has not returned.',
      'HEIMWEG DER STRÖMUNG: Besuche nach der Expedition TAMO im Meeresforschungshaus am WASSERPFAD auf EILAND SECHS. Ein Messboot ist noch nicht zurückgekehrt.')end
    if q.complete then return tr('THE WAY HOME COMPLETE: NERI is safe. PHIONE may be approached at the stone on the small western GREEN PATH islet; MANAPHY at the waterside stone on southern WATER PATH. Each encounter honours earlier ownership. The rescue does not require either capture.',
      'HEIMWEG DER STRÖMUNG ABGESCHLOSSEN: NERI ist sicher. PHIONE ist am Stein auf dem kleinen westlichen Eiland des GRÜNEN PFADS ansprechbar, MANAPHY am Uferstein im südlichen WASSERPFAD. Beide Begegnungen berücksichtigen früheren Besitz. Die Rettung verlangt keinen Fang.')end
    if not q.requested then return tr('TAMO: Sail north along WATER PATH, west along GREEN PATH, then north to OUTCAST ISLAND. NERI waits on the sandy landing below the cave island.',
      'TAMO: Surfe den WASSERPFAD nach Norden, den GRÜNEN PFAD nach Westen und dann nach Norden zur ENTFERNUNGSINSEL. NERI wartet am sandigen Anlegeplatz unterhalb der Höhleninsel.')end
    if not q.repaired then return q.plank and tr('Bring the marked repair plank back to NERI on OUTCAST ISLAND. It is secured as expedition cargo.',
      'Bring NERI auf der ENTFERNUNGSINSEL die markierte Reparaturplanke zurück. Sie liegt sicher beim Expeditionsgepäck.')or tr('NERI: The missing repair plank drifted south onto the small grassy islet in western GREEN PATH. Retrieve it and return to the boat.',
      'NERI: Die fehlende Reparaturplanke trieb nach Süden auf das kleine grasige Eiland im westlichen GRÜNEN PFAD. Hole sie und kehre zum Boot zurück.')end
    if q.returned then return q.checkedIn and tr('NERI has returned safely. Give TAMO the final report in the same WATER PATH research house.',
      'NERI ist sicher zurück. Gib TAMO im selben Forschungshaus am WASSERPFAD den Abschlussbericht.')or tr('The boat reached home. Speak to NERI inside the WATER PATH research house before reporting to TAMO.',
      'Das Boot hat sein Ziel erreicht. Sprich im Forschungshaus am WASSERPFAD mit NERI, bevor du TAMO berichtest.')end
    local instructions={
      {'Activate the NORTH shore signal on the narrow eastern landing of OUTCAST ISLAND, beside the stranded boat.',
        'Aktiviere das NORD-Signal am schmalen östlichen Anlegeplatz der ENTFERNUNGSINSEL neben dem gestrandeten Boot.'},
      {'Activate the MIDDLE signal on the small grassy islet in western GREEN PATH, where you found the plank.',
        'Aktiviere das MITTEL-Signal auf dem kleinen grasigen Eiland im westlichen GRÜNEN PFAD, wo du die Planke fandest.'},
      {'Activate the SOUTH signal on the eastern bank of northern WATER PATH, below its two houses.',
        'Aktiviere das SÜD-Signal am Ostufer des nördlichen WASSERPFADS unterhalb seiner beiden Häuser.'},
    }
    local line=instructions[(q.signals or 0)+1]or instructions[1]
    return tr(line[1],line[2])..tr('\n\nSignals remain lit when you save or take a break. The crew waits safely at the last confirmed passage.',
      '\n\nSignale bleiben beim Speichern und bei Pausen aktiv. Die Besatzung wartet sicher an der zuletzt bestätigten Passage.')
  end
  local function explain(why)
    local messages={
      ['legend_owned']={'Your records already attest to this Pokemon. Its call on the current does not create a second specimen. NERI\'s rescue remains complete.',
        'Deine Aufzeichnungen belegen dieses Pokemon bereits. Sein Ruf in der Strömung erzeugt kein zweites Exemplar. NERIS Rettung bleibt abgeschlossen.'},
      ['generation-profile']={'This encounter needs a generation profile including Sinnoh Pokemon. Your rescue progress is preserved.',
        'Diese Begegnung braucht ein Generationsprofil mit Sinnoh-Pokemon. Dein Rettungsfortschritt bleibt erhalten.'},
      ['legend_history_unavailable']={'Earlier ownership cannot be checked. Retry with a readable Legacy archive and bank.',
        'Früherer Besitz ist nicht pruefbar. Versuche es mit lesbarem Vermächtnisarchiv und erreichbarer Bank erneut.'},
      ['save-failed']={'Saving failed. The encounter has not started.','Speichern fehlgeschlagen. Die Begegnung hat nicht begonnen.'},
      ['missing-art']={'The Pokemon art package is incomplete. Your progress is preserved.','Das Grafikpaket dieses Pokemon ist unvollständig. Dein Fortschritt bleibt erhalten.'},
      ['no-healthy-party']={'Rest your team before approaching.','Erhole dein Team vor der Begegnung.'},
      ['finale-required']={'First complete MARA\'s expedition and seal the local crossing.','Beende zuerst MARAS Expedition und versiegle den örtlichen Übergang.'},
      ['league-required']={'Return after the Pokemon League.','Kehre nach der Pokemon-Liga zurück.'},
      ['beyond-kanto-sealed']={'This discovery requires BEYOND KANTO.','Diese Entdeckung setzt JENSEITS VON KANTO voraus.'},
      ['already-collected']={'The marked plank is already in your expedition cargo or fitted to the boat.',
        'Die markierte Planke liegt bereits im Expeditionsgepäck oder ist am Boot befestigt.'},
      ['wrong-signal']={'The boat cannot skip an unconfirmed passage. Its earlier signals remain lit.\n\n',
        'Das Boot kann keine unbestätigte Passage überspringen. Die bisherigen Signale bleiben aktiv.\n\n'},
      ['already-signalled']={'This passage is already confirmed.\n\n','Diese Passage ist bereits bestätigt.\n\n'},
    }
    local row=messages[why]
    if row then return tr(row[1],row[2])..((why=='wrong-signal'or why=='already-signalled')and T.journal()or'')end
    return T.journal()
  end
  ui.talks[T.sites.TAMO.name]=function(game,ow,n,done)
    local ok,why=gate(game,'TAMO');if not ok then box(game,explain(why),done);return true end
    local q=T.record()
    if not q.briefed then
      T.begin(game);box(game,tr('TAMO: Neri\'s survey boat is stranded near OUTCAST ISLAND. Her last radio call mentioned a little blue Pokemon swimming alongside the crew.\n\nThe old charts are wrong around those reefs. Head north along WATER PATH, then west by GREEN PATH. Find her on the sandy landing below the cave, will you? I will draw a new route as soon as she is safe.',
        'TAMO: Neris Messboot sitzt bei der ENTFERNUNGSINSEL fest. In ihrem letzten Funkspruch erzählte sie von einem kleinen blauen Pokemon, das neben der Besatzung schwimmt.\n\nDie alten Karten stimmen an den Riffen nicht mehr. Folge dem WASSERPFAD nach Norden, dann dem GRÜNEN PFAD nach Westen. Such sie am sandigen Anlegeplatz unter der Höhle, ja? Sobald sie sicher ist, zeichne ich einen neuen Weg.'),done)
    elseif q.checkedIn and not q.complete then
      T.report(game);box(game,tr('TAMO: Neri and her crew are home. And for once, our chart matches the coast outside my window.\n\nNeri drew the Pokemon that stayed near her boat. Phione has gone back to the little GREEN PATH islet; I heard Manaphy singing by southern WATER PATH. They found their way, too.',
        'TAMO: Neri und ihre Besatzung sind zu Hause. Und zur Abwechslung passt unsere Karte wieder zur Küste vor meinem Fenster.\n\nNeri hat die Pokemon gezeichnet, die bei ihrem Boot blieben. Phione ist zum kleinen Eiland am GRÜNEN PFAD zurückgekehrt; Manaphys Gesang hört man am südlichen WASSERPFAD. Auch sie haben ihren Weg gefunden.'),done)
    else box(game,T.journal(),done)end;return true
  end
  ui.talks[T.sites.NERI.name]=function(game,ow,n,done)
    local ok,why=begun(game,'NERI');if not ok then box(game,explain(why),done);return true end
    local q=T.record()
    if q.returned then box(game,T.journal(),done)
    elseif q.plank then
      T.repair(game);box(game,tr('NERI: That is our repair plank! The hull is sealed again. I will follow your shore signals: NORTH here, MIDDLE on the GREEN PATH islet, SOUTH below the WATER PATH houses.\n\nThe little Pokemon swims alongside us. We will wait at each confirmed passage until you light the next. There is no need to rush.',
        'NERI: Das ist unsere Reparaturplanke! Der Rumpf ist wieder dicht. Ich folge deinen Küstensignalen: NORDEN hier, MITTE auf dem Eiland des GRÜNEN PFADS, SÜDEN unter den Häusern am WASSERPFAD.\n\nDas kleine Pokemon schwimmt neben uns. Wir warten an jeder bestätigten Passage auf dein nächstes Signal. Du musst dich nicht beeilen.'),done)
    elseif q.repaired then box(game,T.journal(),done)
    else
      T.requestRepair(game);box(game,tr('NERI: We struck a reef that was not on the chart. Everyone is safe, but our repair plank washed away. It is marked with a blue stripe. The current carried it south towards the little grassy islet in western GREEN PATH.\n\nThat small blue Pokemon stayed beside the boat all night. Let us get everyone home before investigating its distant song.',
        'NERI: Wir liefen auf ein Riff, das nicht auf der Karte stand. Allen geht es gut, aber unsere Reparaturplanke wurde fortgespült. Sie trägt einen blauen Streifen. Die Strömung zog sie nach Süden zum kleinen grasigen Eiland im westlichen GRÜNEN PFAD.\n\nDas kleine blaue Pokemon blieb die ganze Nacht beim Boot. Bringen wir alle heim, bevor wir seinem fernen Gesang nachgehen.'),done)
    end;return true
  end
  ui.talks[T.sites.PLANK.name]=function(game,ow,n,done)
    local ok,why=T.collect(game)
    box(game,ok and tr('A sound plank with a blue stripe lies among the driftwood. You secure it with your expedition cargo. Bring it back to NERI.',
      'Eine unbeschädigte Planke mit blauem Streifen liegt im Treibholz. Du sicherst sie beim Expeditionsgepäck. Bring sie NERI zurück.')or explain(why),done);return true
  end
  for _,id in ipairs(T.order)do local site=id
    ui.talks[T.sites[site].name]=function(game,ow,n,done)
      local ok,why=T.signal(game,site)
      box(game,ok and(T.record().returned and tr('The last light answers. NERI radios from the WATER PATH landing: the crew has arrived safely. A deep blue song fades into the southern current. Meet her inside the research house.',
        'Das letzte Licht antwortet. NERI funkt vom Anleger am WASSERPFAD: Die Besatzung ist sicher angekommen. Ein tiefblauer Gesang verklingt in der südlichen Strömung. Triff sie im Forschungshaus.')or T.journal())or explain(why),done);return true
    end
  end
  ui.talks[T.sites.HOME.name]=function(game,ow,n,done)
    local ok,why=T.checkIn(game)
    box(game,(ok or why=='already-checked-in')and tr('NERI: Everyone is back, and we kept our survey notes. The small companion rested by the GREEN PATH islet. A second, brighter blue shape followed the southern current. TAMO should see these drawings.\n\nThank you for bringing the crew home. We will use your chart for the next voyage.',
      'NERI: Alle sind zurück, und wir haben unsere Messnotizen behalten. Der kleine Begleiter ruhte beim Eiland des GRÜNEN PFADS. Eine zweite, kräftiger blaue Gestalt folgte der südlichen Strömung. TAMO sollte diese Zeichnungen sehen.\n\nDanke, dass du die Besatzung heimgebracht hast. Für die nächste Fahrt nutzen wir deine Karte.')or explain(why),done);return true
  end
  for _,id in ipairs{'PHIONE','MANAPHY'}do local species=id
    ui.talks[T.sites[species].name]=function(game,ow,n,done)
      local ready,reason=begun(game,species)
      if not ready then box(game,explain(reason),done);return true end
      local ok,why=E.availability(game,species)
      if not ok then box(game,explain(why),done);return true end
      local panel=ui.menu.new(game,species,{
        {value='battle',label=tr('APPROACH','NÄHERN'),right='Lv '..E.level(game,species)},
        {value='leave',label=tr('LATER','SPÄTER')},
      },{onCancel=done,onChoose=function(choice,list)
        list:close();if done then done()end
        if choice.value=='battle'then local started,err=E.start(game,species);if not started then box(game,explain(err))end end
      end});panel.__vascHeaderLabel=tr('THE CURRENT','DIE STRÖMUNG');game.stack:push(panel);return true
    end
  end
  local prior=S.chapters.journal
  S.chapters.journal=function()
    local text=prior();if S.state().expeditionComplete then text=text..'\n\n'..T.journal()end;return text
  end
  return T
end
