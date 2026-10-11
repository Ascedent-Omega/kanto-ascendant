-- Readable inscriptions and real Dotted Hole traversal, with no battle.
return function(S,ui)
  local P={sites={},floors={}}
  local tr,box=ui.tr,ui.box
  local function state()
    local s=S.state();s.chapters=s.chapters or{};s.chapters.six=s.chapters.six or{}
    return s,s.chapters.six
  end
  local function add(id,source,x,y,sprite)
    local map,lx,ly=S.location(source,x,y);assert(map,'missing ruin site '..id)
    P.sites[id]={map=map,x=lx,y=ly}
    ui.npc(map,'KA_SEVII_RUINS_'..id,sprite,'KA_SEVII_RUINS_'..id,lx,ly)
  end
  add('RESEARCHER','SixIsland_DottedHole_1F',4,3,'SPRITE_SCIENTIST')
  add('ANCHOR','SixIsland_DottedHole_SapphireRoom',7,4,'SPRITE_BOULDER')
  local clues={
    {'The first boundary faces the cold: NORTH.','Die erste Grenze weist zur Kälte: NORDEN.',6,1},
    {'The next boundary follows the setting sun: WEST.','Die nächste Grenze folgt der sinkenden Sonne: WESTEN.',1,5},
    {'The third boundary greets the rising sun: EAST.','Die dritte Grenze begrüßt die aufgehende Sonne: OSTEN.',11,5},
    {'The final boundary faces the warm sea: SOUTH.','Die letzte Grenze weist zum warmen Meer: SÜDEN.',6,9},
  }
  for i=1,4 do
    local source='SixIsland_DottedHole_B'..i..'F'
    add('STONE_'..i,source,3,3,'SPRITE_BOULDER')
    P.floors[i]=P.sites['STONE_'..i].map
  end
  local function at(game,p)
    local ow=game and game.overworld;local a=ow and ow.player
    return ow and a and ow.map.id==p.map and math.abs(a.cellX-p.x)+math.abs(a.cellY-p.y)==1
  end
  local function allowed(game)return S.unlocked(game)and S.state().chapterFiveComplete end
  function P.begin(game)
    if not allowed(game)or not at(game,P.sites.RESEARCHER)then return false end
    local s,q=state();if q.briefed then return false end
    q.briefed=true;q.depth=0;S.persist(s);return true
  end
  function P.read(game,i)
    if not allowed(game)or not P.sites['STONE_'..tostring(i)]or not at(game,P.sites['STONE_'..i])then return false end
    local s,q=state();if not q.briefed then return false end
    q.inscriptions=q.inscriptions or{};q.inscriptions[tostring(i)]=true;S.persist(s);return true
  end
  function P.beforeWarp(game,ow,x,y,link)
    if not allowed(game)then return end
    local s,q=state();if not q.briefed or q.witnessed then return end
    local index
    for i,map in ipairs(P.floors)do if map==ow.map.id then index=i end end
    if index then
      local clue=clues[index]
      if q.depth==index-1 and q.inscriptions and q.inscriptions[tostring(index)]and x==clue[3]and y==clue[4]then
        q.depth=index
      else q.depth=0;q.routeBroken=true end
      S.persist(s)
    elseif ow.map.id==P.sites.RESEARCHER.map then
      q.depth=0;q.routeBroken=false;S.persist(s)
    end
  end
  function P.witness(game,done)
    if not allowed(game)or not at(game,P.sites.ANCHOR)then return false,'not-at-anchor'end
    local s,q=state()
    if not q.briefed or q.depth~=4 then return false,'route-required'end
    if q.witnessed then return false,'already-seen'end
    return ui.apparition.open(game,ui.assetRoot,tr,function()
      -- Only the completed visible scene grants the receipt. Interrupted
      -- sessions replay it, and no party/Pokedex/gift API is touched.
      local current,r=state();r.witnessed=true;r.identity='GIRATINA'
      r.boundaryCopied=true;S.persist(current)
      box(game,tr('The stone bends towards you. Behind it, GIRATINA turns in an impossible sky. Your Pokemon recoil. You step back inside the old boundary; the opening contracts, but the shadow remains.\n\nYou copy the seal layout: three outer anchors and one empty centre. Take it to the researcher upstairs.',
        'Der Stein biegt sich auf dich zu. Dahinter dreht sich GIRATINA in einem unmöglichen Himmel. Deine Pokemon weichen zurück. Du trittst hinter die alte Grenze; die Öffnung schrumpft, doch der Schatten bleibt.\n\nDu zeichnest den Siegelplan ab: drei äußere Anker und eine freie Mitte. Bring ihn zur Forscherin im Eingang.'),done)
    end)
  end
  function P.report(game)
    if not allowed(game)or not at(game,P.sites.RESEARCHER)then return false end
    local s,q=state();if not q.witnessed or q.complete then return false end
    q.complete=true;s.chapterSixComplete=true;S.persist(s);return true
  end
  function P.journal()
    local s,q=state()
    if not q.briefed then return tr('MARA: Meet Iona inside DOTTED HOLE in SIX ISLAND\'s RUIN VALLEY.',
      'MARA: Triff Iona im PUNKTLOCH im RUINENTAL auf EILAND SECHS.')end
    if not q.witnessed then return tr('IONA: Read the stone on each underground floor, then walk to its marked direction: NORTH, WEST, EAST, SOUTH. A wrong hole returns you upstairs. You can try again; your copied inscriptions remain.',
      'IONA: Lies auf jeder Unterebene den Stein und gehe zur genannten Richtung: NORDEN, WESTEN, OSTEN, SÜDEN. Ein falsches Loch führt nach oben. Versuche es erneut; abgeschriebene Inschriften bleiben erhalten.')end
    if not q.complete then return tr('Return to Iona at the DOTTED HOLE entrance with the seal layout.',
      'Bringe den Siegelplan zu Iona im Eingang des PUNKTLOCHS.')end
    return tr('MARA: Giratina remains beyond the boundary. Take the three-anchor plan to TANOBY RUINS on SEVEN ISLAND. We must close the local crossing without stepping through it.',
      'MARA: Giratina bleibt jenseits der Grenze. Bring den Plan mit den drei Ankern zu den TANOBY-RUINEN auf EILAND SIEBEN. Wir müssen den örtlichen Übergang schließen, ohne ihn zu betreten.')
  end
  ui.talks.KA_SEVII_RUINS_RESEARCHER=function(game,ow,n,done)
    local s,q=state()
    if not allowed(game)then box(game,tr('IONA: The station on FIVE ISLAND has gone silent. Help its crew first.',
      'IONA: Die Station auf EILAND FÜNF schweigt. Hilf zuerst ihrer Besatzung.'),done)
    elseif not q.briefed then box(game,tr('IONA: Mara\'s readings brought me here. Each stone points deeper into the ruins, but the passages do not always lead where they should. Read the inscriptions as you go. I think the last stone holds the seal we are looking for.',
      'IONA: Maras Messungen haben mich hierhergeführt. Jeder Stein weist tiefer in die Ruinen, doch die Gänge führen nicht immer dorthin, wo sie sollten. Lies die Inschriften unterwegs. Ich glaube, der letzte Stein birgt das gesuchte Siegel.'),function()P.begin(game);if done then done()end end)
    elseif q.witnessed and not q.complete then box(game,tr('IONA: Giratina... That is the name Rory heard in Sinnoh. The stone cannot hold it. It can only close the way it opened here.\n\nMara is gathering a team at TANOBY on SEVEN ISLAND. Bring her this plan. We may be able to save Sevii, even if Giratina is still out there.',
      'IONA: Giratina... Diesen Namen hat Rory in Sinnoh gehört. Der Stein kann es nicht festhalten. Er kann nur den Weg schließen, den es hier geöffnet hat.\n\nMara sammelt ein Team bei TANOBY auf EILAND SIEBEN. Bring ihr diesen Plan. Vielleicht können wir Sevii schützen, auch wenn Giratina noch da draußen ist.'),function()P.report(game);if done then done()end end)
    else box(game,P.journal(),done)end
    return true
  end
  for i=1,4 do local index=i
    ui.talks['KA_SEVII_RUINS_STONE_'..i]=function(game,ow,n,done)
      box(game,tr(clues[index][1],clues[index][2]),function()P.read(game,index);if done then done()end end);return true
    end
  end
  ui.talks.KA_SEVII_RUINS_ANCHOR=function(game,ow,n,done)
    local ok,why=P.witness(game,done)
    if not ok then
      if why=='missing-art'or why=='unreadable-art'then box(game,tr('The apparition artwork is missing from this installation. Restore the Sevii art package, then examine this stone again. Your progress is preserved.',
        'Die Erscheinungsgrafik fehlt in dieser Installation. Stelle das Sevii-Grafikpaket wieder her und untersuche den Stein erneut. Dein Fortschritt bleibt erhalten.'),done)
      else box(game,P.journal(),done)end
    end
    return true
  end
  function P.install(game)
    local s,q=state();if not q.depth or q.depth==0 or q.witnessed then return end
    local map=game.overworld and game.overworld.map.id
    local expected=q.depth==4 and P.sites.ANCHOR.map or P.floors[q.depth+1]
    if map~=expected then q.depth=0;S.persist(s)end
  end
  return P
end
