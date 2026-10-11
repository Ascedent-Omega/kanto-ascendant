-- Three aftermath tasks share a story, not three copies of one switch puzzle.
-- The research conclusion never requires capturing or owning a guardian.
return function(S,ui)
  local G={sites={},KEY='lakeGuardians'};local E=assert(S.specialEncounters)
  local tr,box=ui.tr,ui.box
  local function state()
    local s=S.state();s.mysteries=s.mysteries or{};s.mysteries[G.KEY]=s.mysteries[G.KEY]or{}
    return s,s.mysteries[G.KEY]
  end
  function G.record()local _,q=state();return q end
  local function add(id,source,x,y,sprite)
    local map,lx,ly=S.location(source,x,y);assert(map and S.walkable(map,lx,ly),'blocked guardian site '..id)
    for _,n in ipairs(S.maps[map].objects)do assert(n.x~=lx or n.y~=ly,'occupied guardian site '..id)end
    for _,w in ipairs(S.links[map])do assert(math.abs(w.x-lx)+math.abs(w.y-ly)>1,'guardian obstructs door '..id)end
    local p={map=map,x=lx,y=ly,name='KA_SEVII_GUARDIAN_'..id};G.sites[id]=p
    ui.npc(map,p.name,sprite,p.name,lx,ly);return p
  end
  add('ARCHIVIST','FourIsland_LoreleisHouse',8,3,'SPRITE_SCIENTIST')
  add('UXIE','TwoIsland_CapeBrink',8,14,'SPRITE_BOULDER')
  add('MILA','FiveIsland_MemorialPillar',5,42,'SPRITE_MIDDLE_AGED_WOMAN')
  add('KEEPSAKE','FiveIsland_ResortGorgeous',36,11,'SPRITE_PAPER')
  add('MESPRIT','FiveIsland_MemorialPillar',10,45,'SPRITE_BOULDER')
  add('AZELF','TrainerTower_Roof',11,8,'SPRITE_BOULDER')
  for _,r in ipairs{{'UXIE',480,'knowledge'},{'MESPRIT',481,'compassion'},{'AZELF',482,'resolve'}}do
    local id,dex,flag=r[1],r[2],r[3]
    E.register(id,{dex=dex,site=G.sites[id],level=65,owner='sevii_lake_guardians.lua',
      ready=function()return G.record()[flag]==true end})
  end
  local function gate(game,site)
    if not E.near(game,G.sites[site])then return false,'not-at-site'end
    local ok,why=E.storyReady(game);if not ok then return false,why end
    return true
  end
  local function trialGate(game,site)
    local ok,why=gate(game,site);if not ok then return false,why end
    if not G.record().briefed then return false,'briefing-required'end
    return true
  end
  function G.begin(game)
    local ok,why=gate(game,'ARCHIVIST');if not ok then return false,why end
    local s,q=state();if q.briefed then return false,'already-briefed'end
    q.briefed=true;S.persist(s);return true
  end
  local questions={
    {en='What first showed that the disturbance was more than an ordinary tide?',de='Was zeigte zuerst, dass die Störung mehr als eine normale Gezeit war?',answer='CURRENT',choices={
      {'CURRENT','Opposing current','Gegenströmung'},
      {'WEATHER','Rain on one island','Regen auf einer Insel'},
      {'BIRD','Volcanic tremors','Vulkanbeben'}}},
    {en='Who opened the crossings from beyond the boundary?',de='Wer öffnete die Übergänge jenseits der Grenze?',answer='GIRATINA',choices={
      {'MARA','Mara\'s project','Maras Projekt'},
      {'GIRATINA','Giratina','Giratina'},
      {'MACHINE','The probe','Die Sonde'}}},
    {en='What did the expedition actually achieve?',de='Was hat die Expedition tatsächlich erreicht?',answer='CROSSING',choices={
      {'CAPTURE','Giratina caught','Giratina gefangen'},
      {'FOREVER','All rifts erased','Alle Risse weg'},
      {'CROSSING','Local rift sealed','Sevii-Riss zu'}}},
  }
  G.questions=questions
  function G.answer(game,value)
    local ok,why=trialGate(game,'UXIE');if not ok then return false,why end
    local s,q=state();if q.knowledge then return false,'already-complete'end
    local stage=math.max(0,math.min(2,tonumber(q.answers)or 0));local question=questions[stage+1]
    if value~=question.answer then q.answers=0;S.persist(s);return false,'wrong-answer'end
    q.answers=stage+1;q.knowledge=q.answers==#questions;S.persist(s);return true
  end
  function G.request(game)
    local ok,why=trialGate(game,'MILA');if not ok then return false,why end
    local s,q=state();if q.requested then return false,'already-requested'end
    q.requested=true;S.persist(s);return true
  end
  function G.collect(game)
    local ok,why=trialGate(game,'KEEPSAKE');if not ok then return false,why end
    local s,q=state();if not q.requested then return false,'mila-required'end
    if q.keepsake or q.compassion then return false,'already-collected'end
    -- A quest note holds the unique ribbon; it cannot be sold or lost to bag capacity.
    q.keepsake=true;S.persist(s);return true
  end
  function G.returnKeepsake(game)
    local ok,why=trialGate(game,'MILA');if not ok then return false,why end
    local s,q=state();if q.compassion then return false,'already-complete'end
    if not(q.requested and q.keepsake)then return false,'keepsake-required'end
    q.keepsake=false;q.compassion=true;S.persist(s);return true
  end
  function G.proveResolve(game)
    local ok,why=trialGate(game,'AZELF');if not ok then return false,why end
    local s,q=state();if q.resolve then return false,'already-complete'end
    if not s.towerComplete or not S.tower or S.tower.progress()<8 then return false,'tower-required'end
    q.resolve=true;S.persist(s);return true
  end
  function G.report(game)
    local ok,why=trialGate(game,'ARCHIVIST');if not ok then return false,why end
    local s,q=state();if q.complete then return false,'already-complete'end
    if not(q.knowledge and q.compassion and q.resolve)then return false,'trials-required'end
    q.complete=true;q.title='SEVII_THREE_VOICES';S.persist(s);return true
  end
  function G.journal()
    local q=G.record()
    if not q.briefed then return tr('THREE VOICES: Visit archivist NELE in Lorelei\'s house on FOUR ISLAND after the expedition. Three quiet echoes remain.',
      'DREI STIMMEN: Besuche nach der Expedition Archivarin NELE in Loreleis Haus auf EILAND VIER. Drei ruhige Echos bleiben zurück.')end
    if q.complete then return tr('THREE VOICES COMPLETE: Knowledge, compassion and resolve are recorded. The guardians may be approached at Cape Brink, Memorial Pillar and the tower roof. A previously obtained guardian is never issued again.',
      'DREI STIMMEN ABGESCHLOSSEN: Wissen, Mitgefühl und Willenskraft sind vermerkt. Du kannst die Hüter am Kap Kante, an der Gedenksäule und auf dem Turmdach aufsuchen. Ein bereits erhaltener Hüter wird nie erneut ausgegeben.')end
    local lines={tr('NELE\'S NOTES:','NELES NOTIZEN:')}
    if not q.knowledge then lines[#lines+1]=tr('UXIE: The stone on the western upper bank at Cape Brink asks what you learned during the expedition.',
      'SELFE: Der Stein am westlichen oberen Ufer von Kap Kante fragt nach deinen Erkenntnissen aus der Expedition.')end
    if not q.compassion then lines[#lines+1]=q.keepsake and tr('MESPRIT: Return the ribbon to MILA beside Memorial Pillar on FIVE ISLAND.',
      'VESPRIT: Bring MILA bei der Gedenksäule auf EILAND FÜNF die Schleife zurück.')or tr('MESPRIT: Listen to MILA beside Memorial Pillar. Her letter ribbon may have washed onto the southern shore of Resort Gorgeous.',
      'VESPRIT: Höre MILA bei der Gedenksäule zu. Ihre Briefschleife könnte am Südstrand des Ferienparadieses angeschwemmt worden sein.')end
    if not q.resolve then lines[#lines+1]=tr('AZELF: Earn the eight-floor tower title, then approach the stone east of the recorder on its roof.',
      'TOBUTZ: Erwirb den Titel für acht Turmetagen. Suche dann den Stein östlich der Protokollantin auf dem Dach auf.')end
    if q.knowledge and q.compassion and q.resolve then lines[#lines+1]=tr('Return to NELE on FOUR ISLAND. No capture is required to conclude the research.',
      'Kehre zu NELE auf EILAND VIER zurück. Kein Fang ist für den Forschungsabschluss erforderlich.')end
    return table.concat(lines,'\n\n')
  end
  local function whyText(why)
    local messages={
      ['league-required']={'Return after the Pokemon League.','Kehre nach der Pokemon-Liga zurück.'},
      ['finale-required']={'First complete MARA\'s expedition and seal the local crossing.','Beende zuerst MARAS Expedition und versiegle den örtlichen Übergang.'},
      ['beyond-kanto-sealed']={'The guardians require BEYOND KANTO to be open.','Für die Hüter muss JENSEITS VON KANTO geöffnet sein.'},
      ['legend_owned']={'Your records already attest to this guardian. Its presence is acknowledged; there is no second specimen. The research can still be completed.',
        'Deine Aufzeichnungen belegen diesen Hüter bereits. Seine Gegenwart ist anerkannt; es gibt kein zweites Exemplar. Die Forschung kannst du trotzdem abschliessen.'},
      ['generation-profile']={'The encounter needs a generation profile including Sinnoh Pokemon. Your completed task remains recorded.',
        'Die Begegnung braucht ein Generationsprofil mit Sinnoh-Pokemon. Deine gelöste Aufgabe bleibt vermerkt.'},
      ['missing-art']={'This Pokemon\'s art package is incomplete. Your completed task remains recorded.',
        'Das Grafikpaket dieses Pokemon ist unvollständig. Deine gelöste Aufgabe bleibt vermerkt.'},
      ['legend_history_unavailable']={'Earlier ownership cannot be checked. Retry when your Legacy archive and bank are readable.',
        'Früherer Besitz ist nicht pruefbar. Versuche es mit lesbarem Vermächtnisarchiv und erreichbarer Bank erneut.'},
      ['save-failed']={'Saving failed. The encounter has not begun.','Speichern fehlgeschlagen. Die Begegnung hat nicht begonnen.'},
      ['no-healthy-party']={'Rest your team before approaching.','Erhole dein Team, bevor du dich näherst.'},
      ['tower-required']={'The eight tower floors and the roof ceremony must be completed. Leaving or losing never erases a tower victory.',
        'Bestehe acht Turmetagen und die Zeremonie auf dem Dach. Pausen oder Niederlagen löschen keinen Turmsieg.'},
    }
    local row=messages[why];return row and tr(row[1],row[2])or G.journal()
  end
  local function encounter(game,id,done)
    local ok,why=E.availability(game,id)
    if not ok then box(game,whyText(why),done);return end
    local names={UXIE=tr('UXIE','SELFE'),MESPRIT=tr('MESPRIT','VESPRIT'),AZELF=tr('AZELF','TOBUTZ')}
    local panel=ui.menu.new(game,names[id],{
      {label=tr('APPROACH','NÄHERN'),value='battle',right='Lv '..E.level(game,id)},
      {label=tr('LATER','SPÄTER'),value='leave'},
    },{onCancel=done,onChoose=function(choice,list)
      list:close();if done then done()end
      if choice.value=='battle'then local started,reason=E.start(game,id);if not started then box(game,whyText(reason))end end
    end})
    panel.__vascHeaderLabel=tr('THREE VOICES','DREI STIMMEN');game.stack:push(panel)
  end
  local quiz
  quiz=function(game,done)
    local q=G.record()
    if q.knowledge then encounter(game,'UXIE',done);return end
    local question=questions[math.max(0,math.min(2,tonumber(q.answers)or 0))+1]
    box(game,tr(question.en,question.de),function()
      local rows={};for _,r in ipairs(question.choices)do rows[#rows+1]={value=r[1],label=tr(r[2],r[3])}end
      rows[#rows+1]={label=tr('LATER','SPÄTER'),value='leave'}
      local panel=ui.menu.new(game,tr('REMEMBER','ERINNERE DICH'),rows,{onCancel=done,onChoose=function(choice,list)
        list:close();if choice.value=='leave'then if done then done()end;return end
        local ok,why=G.answer(game,choice.value)
        if not ok then box(game,why=='wrong-answer'and tr('The reflection fades. Think back to your expedition. You may try again.',
          'Das Spiegelbild verblasst. Denke an deine Expedition zurück. Du kannst es erneut versuchen.')or whyText(why),done)
        elseif G.record().knowledge then box(game,tr('A quiet blue light rests on the water. UXIE recognises the knowledge you preserved. You may return prepared for an encounter.',
          'Ein ruhiges blaues Licht ruht auf dem Wasser. SELFE erkennt das bewahrte Wissen an. Du kannst vorbereitet zur Begegnung zurückkehren.'),done)
        else quiz(game,done)end
      end});panel.__vascHeaderLabel=tr('KNOWLEDGE','WISSEN');game.stack:push(panel)
    end)
  end
  ui.talks[G.sites.ARCHIVIST.name]=function(game,ow,n,done)
    local ok,why=gate(game,'ARCHIVIST');if not ok then box(game,whyText(why),done);return true end
    local q=G.record()
    if not q.briefed then
      G.begin(game);box(game,tr('NELE: Three gentle lights have appeared since the crossing closed. In Sinnoh, they tell stories of Uxie, Mesprit and Azelf: knowledge, feeling and courage.\n\nOne light waits near CAPE BRINK, another by MEMORIAL PILLAR, and the third above the TRAINER TOWER. Would you see what draws them here? Mila at the pillar might know more.',
        'NELE: Seit der Übergang geschlossen ist, erscheinen drei sanfte Lichter. In Sinnoh erzählt man von Selfe, Vesprit und Tobutz: Wissen, Gefühl und Mut.\n\nEines wartet am KAP KANTE, eines an der GEDENKSÄULE und das dritte über dem TRAINERTURM. Findest du heraus, was sie hierherzieht? Mila an der Säule weiß vielleicht mehr.'),done)
    elseif not q.complete and q.knowledge and q.compassion and q.resolve then
      G.report(game);box(game,tr('NELE: You remembered, you listened, and you kept going. Now the three lights shine together.\n\nI think the guardians heard you. If you visit them again, go as a friend. They have shown us enough without owing us anything.',
        'NELE: Du hast dich erinnert, zugehört und nicht aufgegeben. Jetzt leuchten die drei Lichter gemeinsam.\n\nIch glaube, die Hüter haben dich gehört. Wenn du sie wieder besuchst, geh als Freund. Sie haben uns schon viel gezeigt, ohne uns etwas zu schulden.'),done)
    else box(game,G.journal(),done)end
    return true
  end
  ui.talks[G.sites.UXIE.name]=function(game,ow,n,done)
    local ok,why=trialGate(game,'UXIE');if not ok then box(game,whyText(why),done)else quiz(game,done)end;return true
  end
  ui.talks[G.sites.MILA.name]=function(game,ow,n,done)
    local ok,why=trialGate(game,'MILA');if not ok then box(game,whyText(why),done);return true end
    local q=G.record()
    if q.keepsake then
      G.returnKeepsake(game);box(game,tr('MILA: That is the ribbon from my daughter\'s letter. The water took the words, but I remember them now. Thank you for listening and coming back.\n\nFor a moment, a warm pink reflection moves towards the stone east of the pillar. MESPRIT has heard you.',
        'MILA: Das ist die Schleife vom Brief meiner Tochter. Das Wasser nahm die Worte, aber jetzt erinnere ich mich an sie. Danke, dass du zugehört hast und zurückgekommen bist.\n\nEin warmes rosa Spiegelbild zieht kurz zum Stein östlich der Säule. VESPRIT hat dich gehört.'),done)
    elseif q.compassion then box(game,tr('MILA: I wrote back to my daughter. The next ferry will carry the letter. That gentle reflection still visits the stone to the east.',
      'MILA: Ich habe meiner Tochter zurückgeschrieben. Die nächste Fähre nimmt den Brief mit. Das sanfte Spiegelbild besucht noch den Stein im Osten.'),done)
    else
      G.request(game);box(game,tr('MILA: My daughter lives across the sea. During the strange tide, her letter slipped from my hands. A pink ribbon held its pages together.\n\nThe current ran north to Resort Gorgeous. Perhaps the ribbon reached its southern shore. If you find it, please bring it back. I want to remember her words.',
        'MILA: Meine Tochter lebt jenseits des Meeres. Während der seltsamen Gezeit glitt ihr Brief aus meinen Händen. Eine rosa Schleife hielt die Seiten zusammen.\n\nDie Strömung zog nach Norden zum Ferienparadies. Vielleicht erreichte die Schleife dessen Südstrand. Wenn du sie findest, bring sie bitte zurück. Ich möchte mich an ihre Worte erinnern.'),done)
    end
    return true
  end
  ui.talks[G.sites.KEEPSAKE.name]=function(game,ow,n,done)
    local ok,why=G.collect(game)
    box(game,ok and tr('A faded pink ribbon lies among the washed-up paper. You keep it safe with your expedition notes. Return it to MILA at Memorial Pillar.',
      'Eine verblasste rosa Schleife liegt zwischen angeschwemmtem Papier. Du verwahrst sie sicher bei den Expeditionsnotizen. Bring sie MILA an der Gedenksäule.')or(why=='already-collected'and tr('Only wet paper remains. The ribbon is already safe.',
      'Nur nasses Papier bleibt zurück. Die Schleife ist bereits in Sicherheit.')or whyText(why)),done);return true
  end
  ui.talks[G.sites.MESPRIT.name]=function(game,ow,n,done)
    local ok,why=trialGate(game,'MESPRIT');if not ok then box(game,whyText(why),done)else encounter(game,'MESPRIT',done)end;return true
  end
  ui.talks[G.sites.AZELF.name]=function(game,ow,n,done)
    if not G.record().resolve then
      local ok,why=G.proveResolve(game)
      box(game,ok and tr('The wind stills. AZELF recognises every floor you returned to, every partner you rested and every promise you kept. The guardian waits; you may prepare before approaching.',
        'Der Wind wird still. TOBUTZ erkennt jede Etage, zu der du zurückkehrtest, jeden ausgeruhten Partner und jedes gehaltene Versprechen an. Der Hüter wartet; du kannst dich vor der Begegnung vorbereiten.')or whyText(why),done)
    else
      local ok,why=trialGate(game,'AZELF');if not ok then box(game,whyText(why),done)else encounter(game,'AZELF',done)end
    end
    return true
  end
  local prior=S.chapters.journal
  S.chapters.journal=function()
    local text=prior();if S.state().expeditionComplete then text=text..'\n\n'..G.journal()end;return text
  end
  return G
end
