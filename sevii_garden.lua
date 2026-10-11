-- Restore a damaged Berry Forest nursery; gratitude is a choice, not a quiz.
return function(S,ui)
  local G={KEY='forestGarden',sites={}};local E=assert(S.specialEncounters)
  local tr,box=ui.tr,ui.box;local syncing=false
  local function state()
    local s=S.state();s.mysteries=s.mysteries or{};s.mysteries[G.KEY]=s.mysteries[G.KEY]or{}
    return s,s.mysteries[G.KEY]
  end
  function G.record()local _,q=state();return q end
  local function add(id,source,x,y,sprite)
    local m,lx,ly=S.location(source,x,y);assert(m and S.walkable(m,lx,ly),'blocked garden site '..id)
    for _,n in ipairs(S.maps[m].objects)do assert(n.x~=lx or n.y~=ly,'occupied garden site '..id)end
    for _,w in ipairs(S.links[m])do assert(math.abs(w.x-lx)+math.abs(w.y-ly)>1,'garden site blocks door '..id)end
    local p={map=m,x=lx,y=ly,name='KA_SEVII_GARDEN_'..id};G.sites[id]=p
    ui.npc(m,p.name,sprite,p.name,lx,ly);return p
  end
  add('ODA','ThreeIsland_House3',8,6,'SPRITE_MIDDLE_AGED_WOMAN')
  add('BED','ThreeIsland_BerryForest',4,9,'SPRITE_PAPER')
  add('SILT','ThreeIsland_BerryForest',29,11,'SPRITE_BOULDER')
  add('GATE','ThreeIsland_BerryForest',30,15,'SPRITE_POKEDEX')
  add('RIKA','ThreeIsland_BerryForest',7,9,'SPRITE_GIRL')
  add('SHAYMIN','ThreeIsland_BerryForest',7,6,'SPRITE_BOULDER')
  local function gate(game,id)
    if not E.near(game,G.sites[id])then return false,'not-at-site'end
    return E.storyReady(game)
  end
  local function begun(game,id)
    local ok,why=gate(game,id);if not ok then return false,why end
    if not G.record().briefed then return false,'briefing-required'end
    return true
  end
  function G.install(game)
    if syncing or not(game and game.save)then return end
    local w=ui.world and ui.world();if not(w and w.toggleObject)then return end
    syncing=true;local p=G.sites.SILT;local show=not G.record().cleared
    local old=game.save.objectToggles and game.save.objectToggles[p.map]
    if not old or old[p.name]~=show then w:toggleObject(p.map,p.name,show)end
    syncing=false
  end
  function G.begin(game)
    local ok,why=gate(game,'ODA');if not ok then return false,why end
    local s,q=state();if q.briefed then return false,'already-briefed'end
    q.briefed=true;q.seeds=true;S.persist(s);return true
  end
  function G.inspect(game)
    local ok,why=begun(game,'BED');if not ok then return false,why end
    local s,q=state();if q.inspected then return false,'already-inspected'end
    q.inspected=true;S.persist(s);return true
  end
  function G.clear(game)
    local ok,why=begun(game,'SILT');if not ok then return false,why end
    local s,q=state();if not q.inspected then return false,'inspection-required'end
    if q.cleared then return false,'already-cleared'end
    q.cleared=true;S.persist(s);G.install(game);return true
  end
  function G.release(game,choice)
    local ok,why=begun(game,'GATE');if not ok then return false,why end
    local s,q=state();if not q.cleared then return false,'clearance-required'end
    if q.watered then return false,'already-watered'end
    if choice~='slow'then return false,'too-fast'end
    q.watered=true;S.persist(s);return true
  end
  function G.sow(game)
    local ok,why=begun(game,'BED');if not ok then return false,why end
    local s,q=state();if q.sown then return false,'already-sown'end
    if not(q.inspected and q.watered and q.seeds)then return false,'water-required'end
    q.seeds=false;q.sown=true;S.persist(s);return true
  end
  function G.thank(game,choice)
    local ok,why=begun(game,'RIKA');if not ok then return false,why end
    local s,q=state();if not q.sown then return false,'planting-required'end
    if q.thanks then return false,'already-thanked'end
    if choice~='neighbors'and choice~='pokemon'and choice~='everyone'then return false,'unknown-choice'end
    q.thanks=choice;S.persist(s);return true
  end
  function G.report(game)
    local ok,why=begun(game,'ODA');if not ok then return false,why end
    local s,q=state();if q.complete then return false,'already-complete'end
    if not(q.sown and q.thanks)then return false,'gratitude-required'end
    q.complete=true;q.title='SEVII_FOREST_GARDEN';S.persist(s);return true
  end
  E.register('SHAYMIN',{dex=492,level=65,site=G.sites.SHAYMIN,owner='sevii_garden.lua',
    ready=function()return G.record().complete==true end})
  function G.sign()
    local rows={
      neighbors={'RIKA\'s sign: For the neighbors who saved the seeds and will tend this garden.',
        'RIKAS Schild: Für die Nachbarn, die Samen retteten und diesen Garten pflegen werden.'},
      pokemon={'RIKA\'s sign: For the Pokemon who share this forest with us.',
        'RIKAS Schild: Für die Pokemon, die diesen Wald mit uns teilen.'},
      everyone={'RIKA\'s sign: For everyone who helps life grow here again.',
        'RIKAS Schild: Für alle, die dem Leben hier wieder beim Wachsen helfen.'},
    }
    local row=rows[G.record().thanks];return row and tr(row[1],row[2])or''
  end
  function G.journal()
    local q=G.record();local lines
    if not q.briefed then lines={'WHAT GROWS AGAIN: After the expedition, visit ODA in THREE ISLAND\'s berry shop. The forest nursery needs help.',
      'WAS WIEDER WÄCHST: Besuche nach der Expedition ODA im Beerenladen auf EILAND DREI. Die Waldgärtnerei braucht Hilfe.'}
    elseif q.complete then lines={'WHAT GROWS AGAIN COMPLETE: ODA and RIKA will tend the restored nursery. Approach the marked stone in the northwest BERRY FOREST clearing to meet SHAYMIN. Earlier ownership is respected; the garden is complete without a capture.',
      'WAS WIEDER WÄCHST ABGESCHLOSSEN: ODA und RIKA pflegen die erneuerte Gärtnerei. Am markierten Stein auf der nordwestlichen Lichtung des BEERENFORSTS kannst du SHAYMIN begegnen. Früherer Besitz wird berücksichtigt; der Garten ist auch ohne Fang fertig.'}
    elseif not q.inspected then lines={'Inspect the nursery marker in BERRY FOREST\'s northwest clearing, beside RIKA. Follow the winding trail around the ponds; you can reach it without cutting trees.',
      'Untersuche die Beetmarkierung neben RIKA auf der nordwestlichen Lichtung des BEERENFORSTS. Folge dem gewundenen Weg um die Teiche; du brauchst keine Bäume zu fällen.'}
    elseif not q.cleared then lines={'The seedlings dried out. Clear the loose debris on the north bank of BERRY FOREST\'s upper pond. RIKA marked it with a stone. Leave the living trees standing.',
      'Die Setzlinge sind vertrocknet. Entferne das lose Geroll am Nordufer des oberen Teichs im BEERENFORST. RIKA hat es mit einem Stein markiert. Lass die lebenden Bäume stehen.'}
    elseif not q.watered then lines={'Debris is cleared. Use the sluice marker on the south bank of the same upper pond. Release the water slowly so it does not wash the nursery soil away.',
      'Das Geroll ist entfernt. Bediene die Schleusenmarkierung am Südufer desselben oberen Teichs. Lass das Wasser langsam ab, damit es die Beeterde nicht fortspült.'}
    elseif not q.sown then lines={'Water reaches the nursery again. Return to its marker in the northwest clearing and plant ODA\'s saved seeds. They are secured with the expedition cargo.',
      'Das Wasser erreicht wieder die Gärtnerei. Kehre zur Beetmarkierung auf der nordwestlichen Lichtung zurück und pflanze ODAS gerettete Samen. Sie liegen sicher beim Expeditionsgepäck.'}
    elseif not q.thanks then lines={'The nursery is planted. Speak to RIKA beside the bed. She is making a small thank-you sign for everyone who helped.',
      'Die Gärtnerei ist bepflanzt. Sprich mit RIKA neben dem Beet. Sie gestaltet ein kleines Dankesschild für die Helfer.'}
    else lines={'RIKA will tend the new seedlings. Report to ODA in THREE ISLAND\'s berry shop. Your work is finished; no Pokemon has to be caught.',
      'RIKA wird die neuen Setzlinge pflegen. Berichte ODA im Beerenladen auf EILAND DREI. Deine Arbeit ist fertig; kein Pokemon muss gefangen werden.'}end
    return tr(lines[1],lines[2])..(q.thanks and'\n\n'..G.sign()or'')
  end
  local function explain(why)
    local rows={
      ['too-fast']={'RIKA\'s note: A sudden flood would wash away the soil. Open the sluice slowly. Nothing has been lost.',
        'RIKAS Notiz: Ein Wasserschwall würde die Erde fortspülen. Öffne die Schleuse langsam. Es ist nichts verloren gegangen.'},
      ['legend_owned']={'Your records already attest to SHAYMIN. The garden does not create a second specimen. Your work and the villagers\' gratitude remain.',
        'Deine Aufzeichnungen belegen SHAYMIN bereits. Der Garten erzeugt kein zweites Exemplar. Deine Arbeit und der Dank der Bewohner bleiben.'},
      ['generation-profile']={'This encounter needs a generation profile including Sinnoh Pokemon. The garden remains restored.',
        'Diese Begegnung braucht ein Generationsprofil mit Sinnoh-Pokemon. Der Garten bleibt wiederhergestellt.'},
      ['legend_history_unavailable']={'Earlier ownership cannot be checked. Retry with a readable Legacy archive and bank.',
        'Früherer Besitz ist nicht pruefbar. Versuche es mit lesbarem Vermächtnisarchiv und erreichbarer Bank erneut.'},
      ['save-failed']={'Saving failed. The encounter has not started.','Speichern fehlgeschlagen. Die Begegnung hat nicht begonnen.'},
      ['missing-art']={'The Pokemon art package is incomplete. Your progress is preserved.','Das Grafikpaket dieses Pokemon ist unvollständig. Dein Fortschritt bleibt erhalten.'},
      ['no-healthy-party']={'Rest your team before approaching.','Erhole dein Team vor der Begegnung.'},
      ['league-required']={'Return after the Pokemon League.','Kehre nach der Pokemon-Liga zurück.'},
      ['finale-required']={'First complete MARA\'s expedition and seal the local crossing.','Beende zuerst MARAS Expedition und versiegle den örtlichen Übergang.'},
      ['beyond-kanto-sealed']={'This discovery requires BEYOND KANTO.','Diese Entdeckung setzt JENSEITS VON KANTO voraus.'},
    }
    local row=rows[why];return row and tr(row[1],row[2])or G.journal()
  end
  local function choose(game,title,rows,done,action)
    local panel=ui.menu.new(game,title,rows,{onCancel=done,onChoose=function(choice,list)
      list:close();local ok,why=action(choice.value)
      box(game,ok and G.journal()or explain(why),done)
    end});panel.__vascHeaderLabel=tr('THE GARDEN','DER GARTEN');game.stack:push(panel)
  end
  ui.talks[G.sites.ODA.name]=function(game,ow,n,done)
    local ok,why=gate(game,'ODA');if not ok then box(game,explain(why),done);return true end
    local q=G.record()
    if not q.briefed then
      G.begin(game);box(game,tr('ODA: The crossing is shut, but our forest nursery is still dry. Rika saved these seeds before the beds withered.\n\nShe is on the northwest clearing of BERRY FOREST. Would you take them to her? We can bring the water back and make room for the new Pokemon, too.',
        'ODA: Der Übergang ist zu, aber unsere Waldgärtnerei liegt noch trocken. Rika hat die Samen gerettet, bevor die Beete verdorrten.\n\nSie ist auf der nordwestlichen Lichtung im BEERENFORST. Bringst du sie ihr? Wir können das Wasser zurückholen und den neuen Pokemon trotzdem Platz lassen.'),done)
    elseif q.thanks and not q.complete then
      G.report(game);box(game,tr('ODA: The water is back, and Rika has already planted the seeds. I can almost smell the flowers.\n\nShe saw a little green Pokemon resting by the clearing\'s stone. Shaymin, she called it. Go say hello if you like. It seems the forest has welcomed someone else home.',
        'ODA: Das Wasser fließt wieder, und Rika hat die Samen schon gepflanzt. Ich kann die Blumen beinahe riechen.\n\nAm Stein auf der Lichtung hat sie ein kleines grünes Pokemon gesehen. Shaymin, sagte sie. Besuch es doch, wenn du magst. Der Wald hat wohl noch jemanden willkommen geheißen.'),done)
    else box(game,G.journal(),done)end;return true
  end
  ui.talks[G.sites.BED.name]=function(game,ow,n,done)
    local ok,why
    if not G.record().inspected then ok,why=G.inspect(game)else ok,why=G.sow(game)end
    box(game,ok and G.journal()or explain(why),done);return true
  end
  ui.talks[G.sites.SILT.name]=function(game,ow,n,done)
    local ok,why=G.clear(game);box(game,ok and G.journal()or explain(why),done);return true
  end
  ui.talks[G.sites.GATE.name]=function(game,ow,n,done)
    local ok,why=begun(game,'GATE');local q=G.record()
    if not ok or not q.cleared or q.watered then box(game,ok and G.journal()or explain(why),done);return true end
    choose(game,tr('RELEASE WATER','WASSER ABLASSEN'),{
      {value='fast',label=tr('OPEN FULLY','GANZ ÖFFNEN')},
      {value='slow',label=tr('OPEN SLOWLY','LANGSAM ÖFFNEN')},
    },done,function(c)return G.release(game,c)end);return true
  end
  ui.talks[G.sites.RIKA.name]=function(game,ow,n,done)
    local ok,why=begun(game,'RIKA');local q=G.record()
    if not ok or not q.sown or q.thanks then box(game,ok and G.journal()or explain(why),done);return true end
    choose(game,tr('WHO DO WE THANK?','WEM DANKEN WIR?'),{
      {value='neighbors',label=tr('OUR NEIGHBORS','DEN NACHBARN')},
      {value='pokemon',label=tr('THE POKEMON','DEN POKEMON')},
      {value='everyone',label=tr('EVERYONE HERE','ALLEN HIER')},
    },done,function(c)return G.thank(game,c)end);return true
  end
  ui.talks[G.sites.SHAYMIN.name]=function(game,ow,n,done)
    local ok,why=begun(game,'SHAYMIN');if ok then ok,why=E.availability(game,'SHAYMIN')end
    if not ok then box(game,explain(why),done);return true end
    local panel=ui.menu.new(game,'SHAYMIN',{
      {value='battle',label=tr('APPROACH','NÄHERN'),right='Lv '..E.level(game,'SHAYMIN')},
      {value='leave',label=tr('LATER','SPÄTER')},
    },{onCancel=done,onChoose=function(choice,list)
      list:close();if done then done()end
      if choice.value=='battle'then local started,err=E.start(game,'SHAYMIN');if not started then box(game,explain(err))end end
    end});panel.__vascHeaderLabel=tr('GRATITUDE','DANKBARKEIT');game.stack:push(panel);return true
  end
  local prior=S.chapters.journal
  S.chapters.journal=function()
    local text=prior();if S.state().expeditionComplete then text=text..'\n\n'..G.journal()end;return text
  end
  return G
end
