-- Expedition chapters extend the existing save rather than replacing the
-- first chapter or its generation-evidence receipts.
return function(S,ui)
  local C={sites={}}
  local tr,box=ui.tr,ui.box
  local function state()
    local s=S.state();s.chapters=s.chapters or{};s.chapters.two=s.chapters.two or{}
    return s,s.chapters.two
  end
  local function at(game,site)
    local ow=game and game.overworld;local p=ow and ow.player
    return ow and p and ow.map.id==site.map and
      math.abs(p.cellX-site.x)+math.abs(p.cellY-site.y)==1
  end
  local function add(id,source,x,y,sprite,text)
    local map,lx,ly=S.location(source,x,y);assert(map,'missing chapter location '..id)
    C.sites[id]={map=map,x=lx,y=ly,source=source}
    ui.npc(map,'KA_SEVII_'..id,sprite,text,lx,ly)
  end
  add('ARCHIVIST','TwoIsland_JoyfulGameCorner',3,5,'SPRITE_SCIENTIST','KA_SEVII_ARCHIVE')
  add('MIRROR_STONE','TwoIsland_CapeBrink',15,21,'SPRITE_BOULDER','KA_SEVII_MIRROR')
  function C.readArchive(game)
    if not S.unlocked(game)or not at(game,C.sites.ARCHIVIST)then return false,'not-at-archive'end
    local s,q=state()
    if not s.chapterOneComplete then return false,'chapter-one-required'end
    if q.archiveRead then return false,'already-read'end
    q.archiveRead=true;S.persist(s);return true
  end
  function C.decode(game,symbols)
    if not S.unlocked(game)or not at(game,C.sites.MIRROR_STONE)then return false,'not-at-mirror'end
    local s,q=state()
    if not s.chapterOneComplete or not q.archiveRead then return false,'archive-required'end
    if q.decoded then return false,'already-decoded'end
    if type(symbols)~='table'or #symbols~=3 or symbols[1]~='SHORE'
        or symbols[2]~='WAVE'or symbols[3]~='STAR'then return false,'wrong-reflection'end
    q.decoded=true;S.persist(s);return true
  end
  function C.report(game)
    if not S.unlocked(game)or not at(game,C.sites.ARCHIVIST)then return false,'not-at-archive'end
    local s,q=state()
    if not s.chapterOneComplete or not q.archiveRead or not q.decoded then return false,'mirror-required'end
    if q.complete then return false,'already-reported'end
    q.complete=true;s.chapterTwoComplete=true;S.persist(s);return true
  end
  function C.journal()
    local s,q=state()
    if not s.chapterOneComplete then
      return tr('MARA: Examine both buoys, then bring me your readings.',
        'MARA: Prüfe beide Messbojen und bring mir die Ergebnisse.')
    elseif not q.archiveRead then
      return tr('MARA: Visit the island archive on TWO ISLAND. The keeper may recognise the mirrored coastline in our readings.',
        'MARA: Besuche das INSELARCHIV auf EILAND ZWEI. Vielleicht erkennt der Archivar die gespiegelte Küste aus unseren Messungen.')
    elseif not q.decoded then
      return tr('EXPEDITION NOTES: At CAPE BRINK, follow the western path uphill. The marked stone stands on the eastern bank of the upper pool. Read STAR - WAVE - SHORE as a reflection: from the other end.',
        'EXPEDITIONSNOTIZEN: Am KAP KANTE führt der westliche Weg hinauf. Der markierte Stein steht am Ostufer des oberen Beckens. Lies STERN - WELLE - UFER wie ein Spiegelbild: vom anderen Ende.')
    elseif not q.complete then
      return tr('EXPEDITION NOTES: The water showed an unfamiliar coastline. Return to the archive on TWO ISLAND with the copied inscription.',
        'EXPEDITIONSNOTIZEN: Das Wasser zeigte eine fremde Küste. Bring die abgeschriebene Inschrift zum INSELARCHIV auf EILAND ZWEI.')
    end
    if s.chapterSixComplete and C.finale then
      local text=C.finale.journal()
      if s.expeditionComplete and S.mysteries then text=text..'\n\n'..S.mysteries.journal()end
      return text
    end
    if s.chapterFiveComplete and C.ruins then return C.ruins.journal()end
    if s.chapterFourComplete and C.station then return C.station.journal()end
    if s.chapterThreeComplete and C.ice then return C.ice.journal()end
    if C.rescue then return C.rescue.journal()end
    return tr('MARA: The old seals held a boundary in place. Something is opening it from the other side. A surveyor went missing in THREE ISLAND\'s BERRY FOREST; that is our next lead.',
      'MARA: Die alten Siegel hielten eine Grenze geschlossen. Etwas öffnet sie von der anderen Seite. Im BEERENFORST auf EILAND DREI wird eine Vermesserin vermisst. Das ist unsere nächste Spur.')
  end
  ui.talks.KA_SEVII_ARCHIVE=function(game,ow,n,done)
    local s,q=state()
    if not s.chapterOneComplete then
      box(game,tr('KEEPER: Mara was asking about our oldest songs. If you are helping her on ONE ISLAND, come back when she has seen your readings.',
        'ARCHIVAR: Mara hat nach unseren ältesten Liedern gefragt. Wenn du ihr auf EILAND EINS hilfst, komm mit ihren Messungen noch einmal vorbei.'),done)
    elseif not q.archiveRead then
      box(game,tr('KEEPER: My grandmother sang this when the sea turned strange: "Star, wave, shore. Water reads from the other end. Never cross the coastline in the glass."\n\nThere is a stone by the upper pool at CAPE BRINK. I used to think the song was just meant to keep children away from it. Here, take a copy.',
        'ARCHIVAR: Meine Großmutter sang das, wenn das Meer unruhig wurde: "Stern, Welle, Ufer. Das Wasser liest vom anderen Ende. Betritt nie die Küste im Glas."\n\nAm oberen Becken von KAP KANTE steht ein Stein. Früher dachte ich, das Lied sollte nur Kinder davon fernhalten. Hier, nimm eine Abschrift.'),
        function()C.readArchive(game);if done then done()end end)
    elseif q.decoded and not q.complete then
      box(game,tr('KEEPER: You saw another shore in that pool? My grandmother was warning us, then. Those marks were meant to hold something back.\n\nLina took the old expedition map into BERRY FOREST on THREE ISLAND. She should have returned by now. Please, find her. Take this copy with you.',
        'ARCHIVAR: Du hast im Becken ein anderes Ufer gesehen? Dann wollte Großmutter uns warnen. Die Zeichen sollten etwas fernhalten.\n\nLina nahm die alte Expeditionskarte mit in den BEERENFORST auf EILAND DREI. Sie hätte längst zurück sein müssen. Bitte such sie. Nimm diese Abschrift mit.'),
        function()C.report(game);if done then done()end end)
    else box(game,C.journal(),done)end
    return true
  end
  ui.talks.KA_SEVII_MIRROR=function(game,ow,n,done)
    local s,q=state()
    if s.seviiRiftSealed then
      box(game,tr('The pool reflects only the island sky. The warning remains on the stone. Your expedition notes preserve the vanished coastline.',
        'Das Becken spiegelt nur den Inselhimmel. Die Warnung bleibt auf dem Stein. Deine Expeditionsnotizen bewahren die verschwundene Küste.'),done)
      return true
    end
    if not s.chapterOneComplete or not q.archiveRead then
      box(game,tr('Three marks: a star, a wave, a shore. An old song might explain them. The archive on TWO ISLAND keeps the island records.',
        'Drei Zeichen: ein Stern, eine Welle, ein Ufer. Vielleicht erklärt ein altes Lied ihre Bedeutung. Im INSELARCHIV auf EILAND ZWEI liegen die Inselberichte.'),done)
      return true
    elseif q.decoded then
      box(game,tr('The surface is still again. Your notes preserve the unfamiliar coastline and the words: "Hold the boundary. Do not follow the shadow."',
        'Die Oberfläche ruht wieder. Deine Notizen bewahren die fremde Küste und die Worte: "Halte die Grenze. Folge nicht dem Schatten."'),done)
      return true
    end
    box(game,tr('The stone reads: STAR - WAVE - SHORE. The song says: "Water reads from the other end." Touch the signs in the reflected order.',
      'Auf dem Stein steht: STERN - WELLE - UFER. Im Lied heißt es: "Das Wasser liest vom anderen Ende." Berühre die Zeichen in der gespiegelten Reihenfolge.'),function()
      local chosen={};local Menu=require('src.ui.ListMenu')
      local function pick()
        game.stack:push(Menu.new(game,tr('SIGN ','ZEICHEN ')..(#chosen+1)..'/3',{
          {label=tr('STAR','STERN'),value='STAR'},{label=tr('WAVE','WELLE'),value='WAVE'},
          {label=tr('SHORE','UFER'),value='SHORE'},
        },{onCancel=done,onChoose=function(item)
          game.stack:pop();chosen[#chosen+1]=item.value
          if #chosen<3 then pick();return end
          local ok,why=C.decode(game,chosen)
          local text
          if ok then
            text=tr('The ripples run backwards. Another shore appears beyond your reflection. A huge shadow slips beneath it, and the image breaks.\n\nWords rise through the water: "Hold the boundary. Do not follow the shadow." You copy them for the keeper.',
              'Die Wellen laufen rückwärts. Hinter deinem Spiegelbild erscheint ein anderes Ufer. Ein riesiger Schatten gleitet darunter hindurch, dann zerreißt das Bild.\n\nWorte steigen aus dem Wasser auf: "Halte die Grenze. Folge nicht dem Schatten." Du schreibst sie für den Archivar ab.')
          elseif why=='wrong-reflection' then
            text=tr('Only ordinary ripples. Nothing is lost. Try reading the inscription from its other end.',
              'Nur gewöhnliche Wellen. Nichts ist verloren. Lies die Inschrift noch einmal vom anderen Ende.')
          else text=C.journal()end
          box(game,text,done)
        end}))
      end
      pick()
    end)
    return true
  end
  local modules={}
  if ui.forestRescue then
    C.rescue=ui.forestRescue(S,ui)
    modules[#modules+1]=C.rescue
  end
  if ui.iceMemory then C.ice=ui.iceMemory(S,ui);modules[#modules+1]=C.ice end
  if ui.stationMission then C.station=ui.stationMission(S,ui);modules[#modules+1]=C.station end
  if ui.ruinsMission then C.ruins=ui.ruinsMission(S,ui);modules[#modules+1]=C.ruins end
  if ui.finaleMission then C.finale=ui.finaleMission(S,ui);modules[#modules+1]=C.finale end
  function C.onBoulderMoved(game,ow,npc)
    for _,chapter in ipairs(modules)do
      if chapter.onBoulderMoved then chapter.onBoulderMoved(game,ow,npc)end
    end
  end
  function C.beforeWarp(game,ow,x,y,link)
    for _,chapter in ipairs(modules)do
      if chapter.beforeWarp then chapter.beforeWarp(game,ow,x,y,link)end
    end
  end
  function C.onStep(game,ow,x,y)
    for _,chapter in ipairs(modules)do
      if chapter.onStep and chapter.onStep(game,ow,x,y)then return true end
    end
    return false
  end
  function C.install(game)
    for _,chapter in ipairs(modules)do if chapter.install then chapter.install(game)end end
  end
  return C
end
