-- A displaced nightmare is resolved without requiring either legendary catch.
-- The quiet trail follows actual successful Lost Cave doors, including loops.
return function(S,ui)
  local D={sites={},route={},KEY='moonlitNight'};local E=assert(S.specialEncounters)
  local tr,box=ui.tr,ui.box
  local function state()
    local s=S.state();s.mysteries=s.mysteries or{};s.mysteries[D.KEY]=s.mysteries[D.KEY]or{}
    return s,s.mysteries[D.KEY]
  end
  function D.record()local _,q=state();return q end
  local function add(id,source,x,y,sprite)
    local m,lx,ly=S.location(source,x,y);assert(m and S.walkable(m,lx,ly),'blocked dream site '..id)
    for _,n in ipairs(S.maps[m].objects)do assert(n.x~=lx or n.y~=ly,'occupied dream site '..id)end
    for _,w in ipairs(S.links[m])do assert(math.abs(w.x-lx)+math.abs(w.y-ly)>1,'dream site blocks door '..id)end
    local p={map=m,x=lx,y=ly,name='KA_SEVII_DREAM_'..id};D.sites[id]=p
    ui.npc(m,p.name,sprite,p.name,lx,ly);return p
  end
  add('ILSE','FiveIsland_ResortGorgeous_House',8,3,'SPRITE_NURSE')
  add('JORI','FiveIsland_ResortGorgeous_House',3,4,'SPRITE_YOUNGSTER')
  add('FEATHER','FiveIsland_WaterLabyrinth',12,8,'SPRITE_PAPER')
  add('CRESSELIA','FiveIsland_WaterLabyrinth',14,11,'SPRITE_BOULDER')
  add('LANTERN','FiveIsland_LostCave_Room1',4,6,'SPRITE_POKEDEX')
  add('DARKRAI','FiveIsland_LostCave_Room10',5,4,'SPRITE_BOULDER')
  local directions={{8,5,'EAST','OSTEN'},{5,1,'NORTH','NORDEN'},{5,8,'SOUTH','SÜDEN'},
    {5,8,'SOUTH','SÜDEN'},{8,5,'EAST','OSTEN'},{2,5,'WEST','WESTEN'},
    {5,8,'SOUTH','SÜDEN'},{8,5,'EAST','OSTEN'},{5,1,'NORTH','NORDEN'}}
  for i=1,10 do D.route[i]=assert(S.location('FiveIsland_LostCave_Room'..i,5,5))end
  D.doors={}
  for i,d in ipairs(directions)do
    local found
    for _,link in ipairs(S.links[D.route[i]])do
      if link.x==d[1]and link.y==d[2]and link.map==D.route[i+1]then found=link;break end
    end
    assert(found,'dream route mismatch at room '..i);D.doors[i]=found
  end
  E.register('CRESSELIA',{dex=488,level=68,site=D.sites.CRESSELIA,owner='sevii_dreams.lua',ready=function()return D.record().awake==true end})
  E.register('DARKRAI',{dex=491,level=70,site=D.sites.DARKRAI,owner='sevii_dreams.lua',ready=function()return D.record().complete==true end})
  local function gate(game,id)
    if not E.near(game,D.sites[id])then return false,'not-at-site'end
    return E.storyReady(game)
  end
  local function begun(game,id)
    local ok,why=gate(game,id);if not ok then return false,why end
    if not D.record().briefed then return false,'briefing-required'end
    return true
  end
  function D.begin(game)
    local ok,why=gate(game,'ILSE');if not ok then return false,why end
    local s,q=state();if q.briefed then return false,'already-briefed'end
    q.briefed=true;S.persist(s);return true
  end
  function D.collectFeather(game)
    local ok,why=begun(game,'FEATHER');if not ok then return false,why end
    local s,q=state();if q.featherTaken then return false,'already-collected'end
    q.featherTaken=true;q.feather=true;S.persist(s);return true
  end
  function D.wake(game)
    local ok,why=begun(game,'JORI');if not ok then return false,why end
    local s,q=state();if q.awake then return false,'already-awake'end
    if not q.feather then return false,'feather-required'end
    q.awake=true;S.persist(s);return true
  end
  function D.startTrail(game)
    local ok,why=begun(game,'LANTERN');if not ok then return false,why end
    local s,q=state()
    if not(q.awake and q.feather)then return false,'wake-required'end
    if q.quiet then return false,'already-quiet'end
    if q.refugeReady then return false,'already-traced'end
    q.trail=1;q.lostWay=false;q.refugeReady=false;S.persist(s);return true
  end
  function D.onWarp(game,from,link)
    local s,q=state();if not q.trail or q.quiet or q.refugeReady then return end
    local index=q.trail;local expected=D.doors[index]
    local ready=E.storyReady(game)
    if ready and expected and from==D.route[index]and link==expected then
      q.trail=index+1;q.refugeReady=q.trail==#D.route
    else
      q.trail=nil;q.lostWay=true
    end
    S.persist(s)
  end
  function D.soothe(game)
    local ok,why=begun(game,'DARKRAI');if not ok then return false,why end
    local s,q=state();if q.quiet then return false,'already-quiet'end
    if not(q.awake and q.feather and q.refugeReady)then return false,'trail-required'end
    q.quiet=true;q.feather=false;q.trail=nil;S.persist(s);return true
  end
  function D.report(game)
    local ok,why=begun(game,'ILSE');if not ok then return false,why end
    local s,q=state();if q.complete then return false,'already-complete'end
    if not(q.awake and q.quiet)then return false,'quiet-required'end
    q.complete=true;q.title='SEVII_MOONLIT_NIGHT';S.persist(s);return true
  end
  function D.journal()
    local q=D.record()
    if not q.briefed then return tr('A MOONLIT NIGHT: After the expedition, visit nurse ILSE in the house at Resort Gorgeous on FIVE ISLAND. Someone is still trapped in a nightmare.',
      'EINE NACHT IM MONDLICHT: Besuche nach der Expedition Pflegerin ILSE im Haus des Ferienparadieses auf EILAND FÜNF. Jemand steckt noch in einem Albtraum fest.')end
    if q.complete then return tr('A MOONLIT NIGHT COMPLETE: JORI sleeps peacefully. CRESSELIA may be approached on the Water Labyrinth islet, DARKRAI in the deepest Lost Cave chamber. Earlier ownership prevents a second specimen.',
      'EINE NACHT IM MONDLICHT ABGESCHLOSSEN: JORI schläft wieder friedlich. CRESSELIA ist auf dem Eiland im Wasserirrgarten erreichbar, DARKRAI in der tiefsten Kammer der Verlorenen Höhle. Früherer Besitz verhindert ein zweites Exemplar.')end
    if not q.featherTaken then return tr('ILSE: Look for the pale feather on the grassy islet in the western Water Labyrinth. Search the water west of Resort Gorgeous with SURF.',
      'ILSE: Suche die helle Feder auf dem grasigen Eiland im westlichen Wasserirrgarten. Erkunde mit SURFER das Wasser westlich des Ferienparadieses.')end
    if not q.awake then return tr('Bring the feather to JORI inside the house at Resort Gorgeous. You have tucked it safely into your field notes.',
      'Bring die Feder zu JORI im Haus des Ferienparadieses. Sie liegt sicher zwischen deinen Feldnotizen.')end
    if q.quiet then return tr('The cave is quiet. Return to ILSE at Resort Gorgeous and report that the nightmare no longer reaches the house.',
      'Die Höhle ist ruhig. Kehre zu ILSE im Ferienparadies zurück und berichte, dass der Albtraum das Haus nicht mehr erreicht.')end
    if q.refugeReady then return tr('Set the feather in the stone in the final chamber. Let its light separate the quiet refuge from the house.',
      'Lege die Feder in den Stein der letzten Kammer. Ihr Licht trennt den stillen Rückzugsort vom Haus.')end
    local route={};for _,d in ipairs(directions)do route[#route+1]=tr(d[3],d[4])end
    return tr('JORI: Start the lantern in Lost Cave\'s first room. Follow each doorway in order: ',
      'JORI: Entzünde die Laterne im ersten Raum der Verlorenen Höhle. Folge den Türen der Reihe nach: ')..table.concat(route,' - ')..
      tr('.\n\nA wrong door loses the light trail. Return to the lantern and restart. Saving preserves a correct partial trail. Completed doors: ',
        '.\n\nEine falsche Tür verliert die Lichtspur. Kehre zur Laterne zurück und beginne erneut. Speichern erhält eine richtige Teilstrecke. Durchquerte Türen: ')..math.max(0,(q.trail or 1)-1)..'/9'
  end
  local function explain(why)
    local lines={
      ['legend_owned']={'Your records already attest to this legend. The lingering moonlight or shadow does not create a second Pokemon. The people\'s recovery remains complete.',
        'Deine Aufzeichnungen belegen diese Legende bereits. Zurückgebliebenes Mondlicht oder Schatten erzeugt kein zweites Pokemon. Die Bewohner bleiben von den Albträumen befreit.'},
      ['generation-profile']={'This encounter needs a generation profile including Sinnoh Pokemon. Your quest progress is preserved.',
        'Diese Begegnung braucht ein Generationsprofil mit Sinnoh-Pokemon. Dein Questfortschritt bleibt erhalten.'},
      ['legend_history_unavailable']={'Earlier ownership cannot be checked. Retry with a readable Legacy archive and bank.',
        'Früherer Besitz ist nicht pruefbar. Versuche es mit lesbarem Vermächtnisarchiv und erreichbarer Bank erneut.'},
      ['save-failed']={'Saving failed. The encounter has not started.','Speichern fehlgeschlagen. Die Begegnung hat nicht begonnen.'},
      ['missing-art']={'The Pokemon art package is incomplete. Your progress is preserved.',
        'Das Grafikpaket dieses Pokemon ist unvollständig. Dein Fortschritt bleibt erhalten.'},
      ['no-healthy-party']={'Rest your team before approaching.','Erhole dein Team vor der Begegnung.'},
      ['finale-required']={'First finish MARA\'s expedition and seal the local crossing.','Beende zuerst MARAS Expedition und versiegle den örtlichen Übergang.'},
      ['league-required']={'Return after the Pokemon League.','Kehre nach der Pokemon-Liga zurück.'},
      ['beyond-kanto-sealed']={'This discovery requires BEYOND KANTO.','Diese Entdeckung setzt JENSEITS VON KANTO voraus.'},
    }
    local row=lines[why];return row and tr(row[1],row[2])or D.journal()
  end
  local function encounter(game,id,done)
    local ok,why=E.availability(game,id);if not ok then box(game,explain(why),done);return end
    local panel=ui.menu.new(game,id,{
      {label=tr('APPROACH','NÄHERN'),value='battle',right='Lv '..(E.level and E.level(game,id)or E.rows[id].level)},
      {label=tr('LATER','SPÄTER'),value='leave'},
    },{onCancel=done,onChoose=function(choice,list)
      list:close();if done then done()end
      if choice.value=='battle'then local started,reason=E.start(game,id);if not started then box(game,explain(reason))end end
    end});panel.__vascHeaderLabel=tr('MOONLIGHT','MONDLICHT');game.stack:push(panel)
  end
  ui.talks[D.sites.ILSE.name]=function(game,ow,n,done)
    local ok,why=gate(game,'ILSE');if not ok then box(game,explain(why),done);return true end
    local q=D.record()
    if not q.briefed then
      D.begin(game);box(game,tr('ILSE: Jori keeps dreaming of a house where morning never comes. Now he will not wake at all.\n\nSomeone saw a pale crescent over the western WATER LABYRINTH. A feather from Cresselia helped a child in an old Sinnoh story. I know it sounds like a story, but... will you look on the grassy islet?',
        'ILSE: Jori träumt immer wieder von einem Haus, in dem es nie Morgen wird. Jetzt wacht er gar nicht mehr auf.\n\nJemand sah eine helle Sichel über dem westlichen WASSERIRRGARTEN. In einer alten Geschichte aus Sinnoh half Cresselias Feder einem Kind. Ich weiß, das klingt wie ein Märchen, aber... suchst du auf dem grasigen Eiland danach?'),done)
    elseif q.quiet and not q.complete then
      D.report(game);box(game,tr('ILSE: Jori woke with the sunrise. He asked for breakfast! I thought I might never hear that again. The shadow has its own quiet place now, far from this house. Thank you for bringing him home to us.',
        'ILSE: Jori ist mit der Sonne aufgewacht. Und er wollte Frühstück! Ich dachte schon, das höre ich nie wieder. Der Schatten hat jetzt einen stillen Ort, weit weg von diesem Haus. Danke, dass du ihn zu uns zurückgebracht hast.'),done)
    else box(game,D.journal(),done)end;return true
  end
  ui.talks[D.sites.JORI.name]=function(game,ow,n,done)
    local q=D.record()
    if q.awake then box(game,q.complete and tr('JORI: I dreamed of an ordinary ferry. It arrived exactly where it should. I never thought that could be such a lovely dream.',
      'JORI: Ich habe von einer ganz normalen Fähre geträumt. Sie kam genau dort an, wo sie sollte. Ich hätte nie gedacht, dass das so ein schöner Traum sein kann.')or D.journal(),done)
    else
      local ok,why=D.wake(game)
      box(game,ok and tr('The feather glows softly. JORI opens his eyes.\n\nJORI: I remember the way! Light the old lantern in Lost Cave\'s first room. Then keep to the nine doors in my notes. The feather can leave its light in the last chamber. The shadow needs a place to rest away from our house.',
        'Die Feder leuchtet sanft. JORI öffnet die Augen.\n\nJORI: Ich erinnere mich an den Weg! Entzünde die alte Laterne im ersten Raum der Verlorenen Höhle. Folge dann den neun Türen in meinen Notizen. Die Feder kann ihr Licht in der letzten Kammer hinterlassen. Der Schatten braucht einen Ruheort fern von unserem Haus.')or explain(why),done)
    end;return true
  end
  ui.talks[D.sites.FEATHER.name]=function(game,ow,n,done)
    local ok,why=D.collectFeather(game)
    box(game,ok and tr('A pale feather glows among the grass. You tuck it between your field notes. The crescent-shaped reflection remains by the southern stone. Jori is waiting at home.',
      'Eine helle Feder leuchtet im Gras. Du steckst sie zwischen deine Feldnotizen. Beim südlichen Stein schimmert noch das sichelförmige Spiegelbild. Jori wartet zu Hause.')or(why=='already-collected'and tr('The feather has already been recovered. No second feather appears.',
      'Die Feder wurde bereits geborgen. Es erscheint keine zweite.')or explain(why)),done);return true
  end
  ui.talks[D.sites.LANTERN.name]=function(game,ow,n,done)
    local q=D.record()
    if q.quiet then box(game,D.journal(),done)
    else
      local ok,why=D.startTrail(game)
      box(game,ok and tr('Moonlight gathers in the lantern. The trail begins here.\n\n','Mondlicht sammelt sich in der Laterne. Die Spur beginnt hier.\n\n')..D.journal()or explain(why),done)
    end;return true
  end
  ui.talks[D.sites.CRESSELIA.name]=function(game,ow,n,done)
    local ok,why=begun(game,'CRESSELIA');if not ok then box(game,explain(why),done)else encounter(game,'CRESSELIA',done)end;return true
  end
  ui.talks[D.sites.DARKRAI.name]=function(game,ow,n,done)
    if D.record().complete then encounter(game,'DARKRAI',done)
    else
      local ok,why=D.soothe(game)
      box(game,ok and tr('You set the feather into the stone. The moonlit trail folds into a gentle circle around the chamber. The distant house no longer appears in the darkness.\n\nThe shadow grows still. Darkrai\'s echo has a refuge away from the sleepers. Return to ILSE; no battle is needed to end the nightmare.',
        'Du legst die Feder in den Stein. Die Mondlichtspur schließt sich zu einem sanften Kreis um die Kammer. Das ferne Haus erscheint nicht mehr in der Dunkelheit.\n\nDer Schatten wird still. Darkrais Echo hat einen Rückzugsort fern von den Schlafenden. Kehre zu ILSE zurück; kein Kampf ist nötig, um den Albtraum zu beenden.')or explain(why),done)
    end;return true
  end
  local prior=S.chapters.journal
  S.chapters.journal=function()
    local text=prior();if S.state().expeditionComplete then text=text..'\n\n'..D.journal()end;return text
  end
  return D
end
