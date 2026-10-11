-- A common clock in Dotted Hole and a closed survey in Altering Cave.
-- Repairs local measurements without opening the sealed crossing again.
return function(S,ui)
  local T={KEY='timeSpace',sites={},CAVE='SixIsland_AlteringCave'}
  local E=assert(S.specialEncounters);local tr,box=ui.tr,ui.box
  local function state()
    local s=S.state();s.mysteries=s.mysteries or{};s.mysteries[T.KEY]=s.mysteries[T.KEY]or{}
    return s,s.mysteries[T.KEY]
  end
  function T.record()local _,q=state();return q end
  local function add(id,source,x,y,sprite)
    local m,lx,ly=S.location(source,x,y);assert(m and S.walkable(m,lx,ly),'blocked time-space site '..id)
    for _,n in ipairs(S.maps[m].objects)do assert(n.x~=lx or n.y~=ly,'occupied time-space site '..id)end
    for _,w in ipairs(S.links[m])do assert(math.abs(w.x-lx)+math.abs(w.y-ly)>1,'time-space site blocks door '..id)end
    local p={map=m,x=lx,y=ly,name='KA_SEVII_TS_'..id};T.sites[id]=p
    ui.npc(m,p.name,sprite,p.name,lx,ly);return p
  end
  add('LEVIN','SixIsland_House',8,6,'SPRITE_SCIENTIST')
  add('CLOCK','SixIsland_DottedHole_1F',8,6,'SPRITE_POKEDEX')
  for i=1,3 do add('PULSE_'..i,'SixIsland_DottedHole_B'..i..'F',8,6,'SPRITE_POKEDEX')end
  add('DIALGA','SixIsland_DottedHole_SapphireRoom',8,8,'SPRITE_BOULDER')
  add('CENTRE',T.CAVE,18,18,'SPRITE_POKEDEX')
  add('WEST',T.CAVE,5,13,'SPRITE_PAPER')
  add('NORTH',T.CAVE,6,5,'SPRITE_PAPER')
  add('EAST',T.CAVE,27,11,'SPRITE_PAPER')
  add('SOUTH',T.CAVE,19,20,'SPRITE_PAPER')
  add('PALKIA',T.CAVE,27,16,'SPRITE_BOULDER')
  T.order={'WEST','NORTH','EAST','SOUTH'};T.periods={3,4,6}
  local function gate(game,id)
    if not E.near(game,T.sites[id])then return false,'not-at-site'end
    return E.storyReady(game)
  end
  local function begun(game,id)
    local ok,why=gate(game,id);if not ok then return false,why end
    if not T.record().briefed then return false,'briefing-required'end
    return true
  end
  function T.begin(game)
    local ok,why=gate(game,'LEVIN');if not ok then return false,why end
    local s,q=state();if q.briefed then return false,'already-briefed'end
    q.briefed=true;q.pulses={};S.persist(s);return true
  end
  function T.read(game,index)
    if not T.periods[index]then return false,'unknown-pulse'end
    local ok,why=begun(game,'PULSE_'..index);if not ok then return false,why end
    local s,q=state();q.pulses=q.pulses or{}
    if q.pulses[tostring(index)]then return false,'already-read'end
    q.pulses[tostring(index)]=true;S.persist(s);return true
  end
  function T.align(game,beat)
    local ok,why=begun(game,'CLOCK');if not ok then return false,why end
    local s,q=state();if q.timeStable then return false,'already-aligned'end
    for i=1,3 do if not(q.pulses and q.pulses[tostring(i)])then return false,'readings-required'end end
    if beat~=12 then return false,'wrong-beat'end
    q.timeStable=true;S.persist(s);return true
  end
  function T.startSurvey(game)
    local ok,why=begun(game,'CENTRE');if not ok then return false,why end
    local s,q=state();if q.spaceStable then return false,'already-surveyed'end
    if q.surveying then return false,'already-started'end
    q.surveying=true;q.point=0;q.interrupted=nil;S.persist(s);return true
  end
  function T.mark(game,id)
    local index;for i,site in ipairs(T.order)do if site==id then index=i end end
    if not index then return false,'unknown-marker'end
    local ok,why=begun(game,id);if not ok then return false,why end
    local s,q=state();if q.spaceStable then return false,'already-surveyed'end
    if not q.surveying then return false,'survey-required'end
    if index~=(q.point or 0)+1 then q.point=0;S.persist(s);return false,'wrong-marker'end
    q.point=index;S.persist(s);return true
  end
  function T.closeSurvey(game)
    local ok,why=begun(game,'CENTRE');if not ok then return false,why end
    local s,q=state();if q.spaceStable then return false,'already-surveyed'end
    if not(q.surveying and q.point==4)then return false,'loop-required'end
    q.spaceStable=true;q.surveying=false;S.persist(s);return true
  end
  function T.install(game)
    local s,q=state();if not q.surveying or q.spaceStable then return end
    local map=game and game.overworld and game.overworld.map
    if not map then return end
    local m=S.maps[map.id]
    -- The imported cave has several runtime fragments; crossing their
    -- seams is not leaving the physical cave. Loading inside is safe too.
    if not m or m.kaSeviiSource~=T.CAVE then
      q.surveying=false;q.point=0;q.interrupted=true;S.persist(s)
    end
  end
  function T.report(game)
    local ok,why=begun(game,'LEVIN');if not ok then return false,why end
    local s,q=state();if q.complete then return false,'already-complete'end
    if not(q.timeStable and q.spaceStable)then return false,'both-required'end
    q.complete=true;q.title='SEVII_TIME_SPACE';S.persist(s);return true
  end
  for _,row in ipairs{{'DIALGA',483},{'PALKIA',484}}do
    E.register(row[1],{dex=row[2],level=75,site=T.sites[row[1]],owner='sevii_time_space.lua',
      ready=function()return T.record().complete==true end})
  end
  function T.journal()
    local q=T.record()
    if not q.briefed then return tr('RHYTHM AND BOUNDARY: After the expedition, meet LEVIN in SIX ISLAND\'s village house. Some instruments still disagree about time and distance.',
      'TAKT UND GRENZE: Triff nach der Expedition LEVIN im Wohnhaus von EILAND SECHS. Manche Instrumente widersprechen sich noch bei Zeit und Entfernung.')end
    if q.complete then return tr('RHYTHM AND BOUNDARY COMPLETE: The island instruments share a reliable reference again. DIALGA may be approached at the stone in DOTTED HOLE\'s deepest room; PALKIA at the eastern stone inside ALTERING CAVE. Neither capture is needed, and earlier ownership prevents another specimen. The crossing stays sealed; GIRATINA remains beyond it.',
      'TAKT UND GRENZE ABGESCHLOSSEN: Die Inselinstrumente haben wieder einen verlässlichen Bezug. DIALGA ist am Stein im tiefsten Raum des PUNKTLOCHS ansprechbar, PALKIA am östlichen Stein in der WANDELHÖHLE. Kein Fang ist nötig; früherer Besitz verhindert weitere Exemplare. Der Übergang bleibt versiegelt; GIRATINA bleibt dahinter.')end
    local lines={}
    if q.timeStable then lines[#lines+1]=tr('TIME: Common rhythm restored.','ZEIT: Gemeinsamer Takt wiederhergestellt.')
    else
      lines[#lines+1]=tr('TIME: Read the recorders on the first three underground floors of DOTTED HOLE in RUIN VALLEY. Then set the clock in the entrance room to the FIRST positive beat when all three signals repeat together, starting from zero. No real-time waiting is needed.',
        'ZEIT: Lies die Messgeräte auf den ersten drei Unterebenen des PUNKTLOCHS im RUINENTAL. Stelle dann die Uhr im Eingang auf den ERSTEN positiven Schlag, an dem alle drei Signale ab null wieder zusammentreffen. Du musst keine Echtzeit abwarten.')
      for i,period in ipairs(T.periods)do if q.pulses and q.pulses[tostring(i)]then
        lines[#lines+1]=tr('RECORDER ','MESSGERÄT ')..i..tr(': every ',': alle ')..period..tr(' beats.',' Schläge.')
      end end
    end
    if q.spaceStable then lines[#lines+1]=tr('SPACE: Closed survey confirmed.','RAUM: Geschlossener Messweg bestätigt.')
    elseif q.surveying then
      lines[#lines+1]=q.point==4 and tr('SPACE: Return to the centre instrument to close the loop. Stay inside ALTERING CAVE until it confirms your survey.',
        'RAUM: Kehre zum mittleren Instrument zurück, um den Kreis zu schließen. Bleibe in der WANDELHÖHLE, bis es deinen Messweg bestätigt.')or
        tr('SPACE: Next marker: ','RAUM: Nächste Markierung: ')..tr(T.order[(q.point or 0)+1],({WEST='WESTEN',NORTH='NORDEN',EAST='OSTEN',SOUTH='SÜDEN'})[T.order[(q.point or 0)+1]])..tr('. Stay inside the cave. Saving preserves your progress.',
          '. Bleibe in der Höhle. Speichern behält deinen Fortschritt.')
    else lines[#lines+1]=tr('SPACE: Reach ALTERING CAVE on OUTCAST ISLAND, north of WATER PATH and GREEN PATH. Start at its centre instrument. Confirm WEST, NORTH, EAST, SOUTH, then return to the centre. Leaving the cave cancels only the unfinished survey; you can start again.',
      'RAUM: Erreiche die WANDELHÖHLE auf der ENTFERNUNGSINSEL, nördlich von WASSERPFAD und GRÜNEM PFAD. Beginne am mittleren Instrument. Bestätige WESTEN, NORDEN, OSTEN, SÜDEN und kehre zur Mitte zurück. Verlässt du die Höhle, endet nur der unfertige Messweg; du kannst neu beginnen.')end
    if q.timeStable and q.spaceStable then lines[#lines+1]=tr('Report both results to LEVIN in SIX ISLAND\'s village house.',
      'Berichte LEVIN im Wohnhaus von EILAND SECHS von beiden Ergebnissen.')end
    return table.concat(lines,'\n\n')
  end
  local function explain(why)
    local rows={
      ['wrong-beat']={'Use the FIRST common positive beat of periods 3, 4 and 6. A later shared beat is not the first. Your copied readings remain.',
        'Gesucht ist der ERSTE gemeinsame positive Schlag der Abstände 3, 4 und 6. Ein späterer gemeinsamer Schlag ist nicht der erste. Deine Messwerte bleiben erhalten.'},
      ['wrong-marker']={'That breaks the ordered loop. Begin again at WEST; the survey remains active. The completed clock work is safe.',
        'Das unterbricht den geordneten Kreis. Beginne wieder im WESTEN; die Messung bleibt aktiv. Die abgeschlossene Uhrenarbeit bleibt erhalten.'},
      ['legend_owned']={'Your records already attest to this Pokemon. The instrument does not create another specimen; the island research remains complete.',
        'Deine Aufzeichnungen belegen dieses Pokemon bereits. Das Instrument erzeugt kein weiteres Exemplar; die Inselforschung bleibt abgeschlossen.'},
      ['generation-profile']={'This encounter needs a generation profile including Sinnoh Pokemon. Your research is preserved.',
        'Diese Begegnung braucht ein Generationsprofil mit Sinnoh-Pokemon. Deine Forschung bleibt erhalten.'},
      ['legend_history_unavailable']={'Earlier ownership cannot be checked. Retry with a readable Legacy archive and bank.',
        'Früherer Besitz ist nicht pruefbar. Versuche es mit lesbarem Vermächtnisarchiv und erreichbarer Bank erneut.'},
      ['save-failed']={'Saving failed. The encounter has not started.','Speichern fehlgeschlagen. Die Begegnung hat nicht begonnen.'},
      ['missing-art']={'The Pokemon art package is incomplete. Your progress is preserved.','Das Grafikpaket dieses Pokemon ist unvollständig. Dein Fortschritt bleibt erhalten.'},
      ['no-healthy-party']={'Rest your team before approaching.','Erhole dein Team vor der Begegnung.'},
      ['league-required']={'Return after the Pokemon League.','Kehre nach der Pokemon-Liga zurück.'},
      ['finale-required']={'First complete MARA\'s expedition and seal the local crossing.','Beende zuerst MARAS Expedition und versiegle den örtlichen Übergang.'},
      ['beyond-kanto-sealed']={'This discovery requires BEYOND KANTO.','Diese Entdeckung setzt JENSEITS VON KANTO voraus.'},
    }
    local r=rows[why];return r and tr(r[1],r[2])or T.journal()
  end
  ui.talks[T.sites.LEVIN.name]=function(game,ow,n,done)
    local ok,why=gate(game,'LEVIN');if not ok then box(game,explain(why),done);return true end
    local q=T.record()
    if not q.briefed then
      T.begin(game);box(game,tr('LEVIN: Since the crossing closed, my clocks in DOTTED HOLE cannot agree on the hour. In ALTERING CAVE, a surveyor walks in a circle and ends up somewhere else.\n\nHelp me set the clocks and mark a safe loop through the cave. Either place can come first. I would like our maps to tell the truth again.',
        'LEVIN: Seit der Übergang geschlossen ist, zeigen meine Uhren im PUNKTLOCH verschiedene Stunden an. In der WANDELHÖHLE läuft ein Vermesser im Kreis und kommt woanders heraus.\n\nHilf mir, die Uhren zu stellen und einen sicheren Rundweg durch die Höhle zu markieren. Wo du anfängst, ist egal. Ich möchte unseren Karten wieder trauen können.'),done)
    elseif q.timeStable and q.spaceStable and not q.complete then
      T.report(game);box(game,tr('LEVIN: The clocks agree again. I never thought I would be glad to hear them tick.\n\nTwo Pokemon answered the stones while we worked: Dialga beneath DOTTED HOLE and Palkia in ALTERING CAVE. Perhaps the scars in time and space drew them here. The crossing is still shut. We can leave them in peace.',
        'LEVIN: Die Uhren gehen wieder gleich. Ich hätte nie gedacht, dass mich ihr Ticken so freuen würde.\n\nWährend unserer Arbeit antworteten zwei Pokemon auf die Steine: Dialga unter dem PUNKTLOCH und Palkia in der WANDELHÖHLE. Vielleicht haben die Narben in Zeit und Raum sie angelockt. Der Übergang bleibt geschlossen. Wir können sie in Frieden lassen.'),done)
    else box(game,T.journal(),done)end;return true
  end
  for i=1,3 do local index=i
    ui.talks[T.sites['PULSE_'..i].name]=function(game,ow,n,done)
      local ok,why=T.read(game,index);box(game,ok and T.journal()or explain(why),done);return true
    end
  end
  ui.talks[T.sites.CLOCK.name]=function(game,ow,n,done)
    local ok,why=begun(game,'CLOCK');if not ok or T.record().timeStable then box(game,ok and T.journal()or explain(why),done);return true end
    local rows={};for _,beat in ipairs{6,12,18,24}do rows[#rows+1]={value=beat,label=tostring(beat)..tr(' BEATS',' SCHLÄGE')}end
    local panel=ui.menu.new(game,tr('FIRST COMMON BEAT','GEMEINSAMER TAKT'),rows,{onCancel=done,onChoose=function(choice,list)
      list:close();local success,err=T.align(game,choice.value);box(game,success and T.journal()or explain(err),done)
    end});panel.__vascHeaderLabel=tr('TIME','ZEIT');game.stack:push(panel);return true
  end
  ui.talks[T.sites.CENTRE.name]=function(game,ow,n,done)
    local ok,why
    if T.record().surveying then ok,why=T.closeSurvey(game)else ok,why=T.startSurvey(game)end
    box(game,ok and T.journal()or explain(why),done);return true
  end
  for _,id in ipairs(T.order)do local marker=id
    ui.talks[T.sites[marker].name]=function(game,ow,n,done)
      local ok,why=T.mark(game,marker);box(game,ok and T.journal()or explain(why),done);return true
    end
  end
  for _,id in ipairs{'DIALGA','PALKIA'}do local species=id
    ui.talks[T.sites[species].name]=function(game,ow,n,done)
      local ok,why=begun(game,species);if ok then ok,why=E.availability(game,species)end
      if not ok then box(game,explain(why),done);return true end
      local panel=ui.menu.new(game,species,{{value='battle',label=tr('APPROACH','NÄHERN'),right='Lv '..E.level(game,species)},
        {value='leave',label=tr('LATER','SPÄTER')}},{onCancel=done,onChoose=function(choice,list)
        list:close();if done then done()end
        if choice.value=='battle'then local started,err=E.start(game,species);if not started then box(game,explain(err))end end
      end});panel.__vascHeaderLabel=tr('RHYTHM AND BOUNDARY','TAKT UND GRENZE');game.stack:push(panel);return true
    end
  end
  local prior=S.chapters.journal
  S.chapters.journal=function()local text=prior();if S.state().expeditionComplete then text=text..'\n\n'..T.journal()end;return text end
  return T
end
