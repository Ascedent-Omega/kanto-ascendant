-- Chapter four: recover a frozen record, then physically retrace its seal.
-- The rehearsal seals no live rift and never creates a catchable legendary.
return function(S,ui)
  local I={sites={}}
  local tr,box=ui.tr,ui.box
  local function state()
    local s=S.state();s.chapters=s.chapters or{};s.chapters.four=s.chapters.four or{}
    return s,s.chapters.four
  end
  local function add(id,source,x,y,sprite)
    local map,lx,ly=S.location(source,x,y);assert(map,'missing ice memory site '..id)
    I.sites[id]={map=map,x=lx,y=ly}
    ui.npc(map,'KA_SEVII_ICE_'..id,sprite,'KA_SEVII_ICE_'..id,lx,ly)
  end
  add('GUIDE','FourIsland_IcefallCave_Entrance',19,29,'SPRITE_HIKER')
  add('RECORD','FourIsland_IcefallCave_B1F',10,8,'SPRITE_POKE_BALL')
  add('ANCHOR','FourIsland_IcefallCave_Back',12,15,'SPRITE_BOULDER')
  I.route={}
  for _,p in ipairs{{12,16},{11,16},{11,15},{11,14},{12,14},{13,14},{13,15},{13,16},{12,16}}do
    local map,x,y=S.location('FourIsland_IcefallCave_Back',p[1],p[2])
    assert(S.walkable(map,x,y),'memory trace needs dry floor')
    I.route[#I.route+1]={map=map,x=x,y=y}
  end
  local function position(game)
    local ow=game and game.overworld;local p=ow and ow.player
    return ow and p and {map=ow.map.id,x=p.cellX,y=p.cellY}
  end
  local function same(a,b)return a and b and a.map==b.map and a.x==b.x and a.y==b.y end
  local function near(game,site)
    local p=position(game)
    return p and p.map==site.map and math.abs(p.x-site.x)+math.abs(p.y-site.y)==1
  end
  local function allowed(game,s)return S.unlocked(game)and s.chapterThreeComplete==true end
  function I.refresh(game)
    local _,q=state();local marked={}
    for index=1,(q.traced and #I.route or q.traceIndex or 0)do
      local p=I.route[index];if p then marked[p.x..','..p.y]=true end
    end
    S.refreshCellPictures(game,'kaSeviiTraceBlocks',marked)
  end
  function I.begin(game)
    local s,q=state()
    if not allowed(game,s)then return false,'chapter-three-required'end
    if not near(game,I.sites.GUIDE)then return false,'not-at-guide'end
    if q.briefed then return false,'already-briefed'end
    q.briefed=true;S.persist(s);return true
  end
  function I.readRecord(game)
    local s,q=state()
    if not allowed(game,s)or not q.briefed then return false,'guide-required'end
    if not near(game,I.sites.RECORD)then return false,'not-at-record'end
    if q.recordRead then return false,'already-read'end
    q.recordRead=true;S.persist(s);return true
  end
  function I.startTrace(game)
    local s,q=state()
    if not allowed(game,s)or not q.recordRead then return false,'record-required'end
    if q.traced then return false,'already-traced'end
    if not same(position(game),I.route[1])then return false,'start-south-of-anchor'end
    q.tracing=true;q.traceIndex=1;q.interrupted=nil;S.persist(s);I.refresh(game);return true
  end
  function I.report(game)
    local s,q=state()
    if not allowed(game,s)or not q.traced then return false,'trace-required'end
    if not near(game,I.sites.GUIDE)then return false,'not-at-guide'end
    if q.complete then return false,'already-reported'end
    q.complete=true;s.chapterFourComplete=true;S.persist(s);return true
  end
  function I.journal()
    local _,q=state()
    if not q.briefed then
      return tr('EXPEDITION NOTES: Meet HAGEN beside the entrance of ICEFALL CAVE on FOUR ISLAND. LINA\'s sketch matches the old expedition\'s anchor stones.',
        'EXPEDITIONSNOTIZEN: Triff HAGEN beim Eingang der EISKASKADENHÖHLE auf EILAND VIER. LINAS Skizze passt zu den Ankersteinen der alten Expedition.')
    elseif not q.recordRead then
      return tr('HAGEN: Surf to the western cave passage. Thin ice cracks under your first step and breaks on a second visit. The sealed record case lies below, in the western chamber. Ladders lead back up.',
        'HAGEN: Surfe zum westlichen Höhlengang. Dünnes Eis reißt beim ersten Betreten und bricht beim zweiten. Die versiegelte Aktenkapsel liegt darunter, in der westlichen Kammer. Leitern führen zurück nach oben.')
    elseif not q.traced then
      return tr('FROZEN RECORD: Reach the rear chamber beyond the northern water passage. Stand on the ice directly SOUTH of its stone, face it and interact. Then trace the eight outer steps: LEFT, UP, UP, RIGHT, RIGHT, DOWN, DOWN, LEFT. Keep the stone inside the boundary. Leaving the line only resets this attempt.',
        'EISPROTOKOLL: Erreiche die hintere Kammer jenseits des nördlichen Wasserwegs. Stelle dich auf das Eis direkt SÜDLICH des Steins, sieh ihn an und sprich ihn an. Dann gehe acht Schritte außen herum: LINKS, HOCH, HOCH, RECHTS, RECHTS, RUNTER, RUNTER, LINKS. Halte den Stein innerhalb der Grenze. Verlassen der Linie setzt nur diesen Versuch zurück.')
    elseif not q.complete then
      return tr('EXPEDITION NOTES: The reconstructed boundary holds around the anchor. The shadow itself was never trapped. Return to HAGEN at the cave entrance with the record.',
        'EXPEDITIONSNOTIZEN: Die rekonstruierte Grenze hält um den Anker. Der Schatten selbst war nie gefangen. Kehre mit dem Protokoll zu HAGEN am Höhleneingang zurück.')
    end
    return tr('EXPEDITION NOTES: The old seals closed crossings, not the world behind them. On FIVE ISLAND, GEZEITENLINIE station has lost power and radio contact. Find its staff in the old warehouse east of town.',
      'EXPEDITIONSNOTIZEN: Die alten Siegel schlossen Übergänge, nicht die Welt dahinter. Auf EILAND FÜNF sind Strom und Funk der Station GEZEITENLINIE ausgefallen. Suche ihre Besatzung im alten Lagerhaus östlich des Orts.')
  end
  function I.onStep(game,ow,x,y)
    local s,q=state();if not q.tracing then return false end
    local index=tonumber(q.traceIndex)or 0
    local p={map=ow.map.id,x=x,y=y};local expected=I.route[index+1]
    if not allowed(game,s)or not same(p,expected)then
      q.tracing=false;q.traceIndex=nil;q.interrupted=true;S.persist(s);I.refresh(game)
      box(game,tr('The line fades. The record is safe. Start again directly south of the stone and keep to its outer ring.',
        'Die Linie verblasst. Das Protokoll bleibt erhalten. Beginne erneut direkt südlich des Steins und bleibe auf seinem äußeren Ring.'))
      return true
    end
    q.traceIndex=index+1
    if q.traceIndex==#I.route then q.traced=true;q.tracing=false end
    S.persist(s);I.refresh(game)
    if q.traced then
      box(game,tr('A closed line surrounds the stone. The ice reflects a vast shape beyond it, still moving freely.\n\nThe final record becomes legible: "We did not imprison the shadow. We closed its way here. Keep the anchors apart; join their boundaries."\n\nYou copy the method. Return to HAGEN.',
        'Eine geschlossene Linie umgibt den Stein. Das Eis spiegelt dahinter eine riesige Gestalt, die sich weiter frei bewegt.\n\nDer letzte Eintrag wird lesbar: "Wir haben den Schatten nicht eingesperrt. Wir schlossen seinen Weg hierher. Halte die Anker getrennt; verbinde ihre Grenzen."\n\nDu schreibst das Verfahren ab. Kehre zu HAGEN zurück.'))
      return true
    end
    return false
  end
  function I.install(game)
    local s,q=state()
    if q.tracing and not same(position(game),I.route[tonumber(q.traceIndex)or 0])then
      q.tracing=false;q.traceIndex=nil;q.interrupted=true;S.persist(s)
    end
    I.refresh(game)
  end
  ui.talks.KA_SEVII_ICE_GUIDE=function(game,ow,n,done)
    local s,q=state()
    if not allowed(game,s)then
      box(game,tr('HAGEN: I have seen that mark before... Lina was sketching one just like it in the forest on THREE ISLAND. I hope she is all right.',
        'HAGEN: Das Zeichen kenne ich doch... Lina hat so eines im Wald auf EILAND DREI gezeichnet. Hoffentlich geht es ihr gut.'),done)
    elseif not q.briefed then
      box(game,tr('HAGEN: Lina found the same mark? My grandparents told me about an expedition trapped here when the cave froze overnight. Their record case is beneath the ice in the western passage.\n\nMind your step. The thin ice cracks underfoot, and a second step breaks it. There are ladders below. Let us see what the expedition learned before we touch that anchor.',
        'HAGEN: Lina hat dasselbe Zeichen gefunden? Meine Großeltern erzählten von einer Expedition, die hier eingeschlossen wurde, als die Höhle über Nacht zufror. Ihre Aktenkapsel liegt unter dem Eis im westlichen Gang.\n\nPass auf, wo du hintrittst. Das dünne Eis bekommt beim ersten Schritt Risse, beim zweiten bricht es. Unten gibt es Leitern. Finden wir erst heraus, was die Expedition wusste, bevor wir den Anker berühren.'),
        function()I.begin(game);if done then done()end end)
    elseif q.traced and not q.complete then
      box(game,tr('HAGEN: They shut a doorway. They never trapped the shadow itself. No wonder it came back.\n\nMara\'s station on FIVE ISLAND has gone quiet. They work in the old warehouse east of town. Take them this record, quickly. If their equipment is feeding a doorway, they need to know.',
        'HAGEN: Sie haben eine Tür geschlossen. Den Schatten selbst hielten sie nie fest. Kein Wunder, dass er zurückkam.\n\nMaras Station auf EILAND FÜNF meldet sich nicht mehr. Sie arbeiten im alten Lagerhaus östlich des Orts. Bring ihnen das Protokoll, schnell. Falls ihre Geräte eine solche Tür speisen, müssen sie es wissen.'),
        function()I.report(game);if done then done()end end)
    else box(game,I.journal(),done)end
    return true
  end
  ui.talks.KA_SEVII_ICE_RECORD=function(game,ow,n,done)
    local s,q=state()
    if not allowed(game,s)or not q.briefed then box(game,I.journal(),done)
    else
      box(game,tr('The waterproof case contains a map of the rear chamber and a scratched diagram.\n\n"Stand south of the anchor. Face the stone to begin. Trace its outer edge: LEFT, UP, UP, RIGHT, RIGHT, DOWN, DOWN, LEFT. Do not cross through the centre."\n\n"The boundary must close. The shadow will remain beyond it."\n\nYou copy the map and the eight steps into your notes.',
        'Die wasserdichte Kapsel enthält eine Karte der hinteren Kammer und eine eingeritzte Skizze.\n\n"Stehe südlich des Ankers. Sieh den Stein an, um zu beginnen. Folge seinem äußeren Rand: LINKS, HOCH, HOCH, RECHTS, RECHTS, RUNTER, RUNTER, LINKS. Durchquere nicht die Mitte."\n\n"Die Grenze muss sich schließen. Der Schatten bleibt dahinter bestehen."\n\nDu überträgst Karte und acht Schritte in deine Notizen.'),
        function()I.readRecord(game);if done then done()end end)
    end
    return true
  end
  ui.talks.KA_SEVII_ICE_ANCHOR=function(game,ow,n,done)
    local s,q=state()
    if not allowed(game,s)or not q.recordRead or q.traced then box(game,I.journal(),done)
    elseif not same(position(game),I.route[1])then
      box(game,tr('The first mark lies directly SOUTH of the stone. Begin there, facing the anchor.',
        'Das erste Zeichen liegt direkt SÜDLICH des Steins. Beginne dort mit Blick zum Anker.'),done)
    else
      box(game,tr('The first line appears beneath your feet. Walk around the outer ice: LEFT, UP, UP, RIGHT, RIGHT, DOWN, DOWN, LEFT.\n\nThis is a reconstruction. The marked ring will not collapse.',
        'Unter deinen Füßen erscheint die erste Linie. Gehe um den äußeren Eisrand: LINKS, HOCH, HOCH, RECHTS, RECHTS, RUNTER, RUNTER, LINKS.\n\nDies ist eine Rekonstruktion. Der markierte Ring bricht nicht ein.'),
        function()I.startTrace(game);if done then done()end end)
    end
    return true
  end
  return I
end
