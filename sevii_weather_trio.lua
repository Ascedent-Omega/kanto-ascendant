-- The three character-bound Hoenn legends answer on Sevii after their own
-- fissure-door visit and the 130-species foundation. Old portals stay shut.
return function(S,ui,opts)
  local P=assert(opts.hoennLegendPortals,'Hoenn legend owner missing')
  local journey=assert(opts.journey,'Legacy journey missing')
  local dex=assert(opts.hoennDex,'Hoenn Dex authority missing')
  local tr,box=ui.tr,ui.box
  local T={sites={},canCapture=function(game,battle,species)
    return P.canCapture(game,battle,species)
  end}
  local places={
    RED={source='MtEmber_RubyPath_B3F',x=19,y=6,species='GROUDON'},
    BLUE={source='FourIsland_IcefallCave_Back',x=12,y=20,species='KYOGRE'},
    GREEN={source='TrainerTower_Roof',x=13,y=7,species='RAYQUAZA'},
  }
  local appliedNpcList
  function T.install(game)
    local ow=game and game.overworld
    if not(ow and ow.map and S.maps[ow.map.id])or appliedNpcList==ow.npcs then return end
    local world=ui.world and ui.world()
    if not(world and world.npc)then return end
    for _,site in pairs(T.sites)do
      if site.map==ow.map.id then
        local actor=world:npc(site.map,site.name)
        if not actor then return end
        -- Optional character/Dex seals must not gate ordinary cave routes.
        -- Groudon stands on the Ruby Path's sole corridor, before the
        -- independent Heatran reading. Keep interaction/capture gates while
        -- retaining the imported floor's walkability, even after capture.
        actor:setPassable(true)
      end
    end
    appliedNpcList=ow.npcs
  end
  for _,character in ipairs{'RED','BLUE','GREEN'}do
    local place=places[character]
    local map,x,y=S.location(place.source,place.x,place.y)
    assert(map and S.walkable(map,x,y),'blocked Sevii weather site '..character)
    for _,n in ipairs(S.maps[map].objects)do
      assert(n.x~=x or n.y~=y,'occupied Sevii weather site '..character)
    end
    for _,link in ipairs(S.links[map])do
      assert(math.abs(link.x-x)+math.abs(link.y-y)>1,'weather site blocks door '..character)
    end
    local site={map=map,x=x,y=y,character=character,species=place.species,
      name='KA_SEVII_WEATHER_'..character}
    T.sites[character]=site
    ui.npc(map,site.name,'SPRITE_KA_HEVO_LEGEND_'..place.species,
      site.name,x,y)
    S.maps[map].objects[#S.maps[map].objects].kaSeviiRoutePassable=true
    ui.talks[site.name]=function(game,ow,npc,done)
      if not S.specialEncounters.storyReady(game)then
        box(game,tr('The island crossing must be sealed before this stone answers.',
          'Erst nach dem Verschluss des Inselübergangs antwortet dieser Stein.'),done)
        return true
      end
      local current=journey.activeCharacter(game.save)
      if current~=character then
        box(game,tr('This seal answers only to the '..character..' path.',
          'Dieses Siegel antwortet nur dem '..character..'-Pfad.'),done)
        return true
      end
      if not journey.currentHevoDoorVisit(game.save,character)then
        box(game,tr('First visit the black door in your own fissure shrine.',
          'Besuche zuerst die schwarze Tür im eigenen Riss-Schrein.'),done)
        return true
      end
      local report=dex.report(game)
      if not report.portalReady then
        local missing=#(report.foundationMissing or{})
        box(game,tr('The Hoenn foundation is incomplete. Record '..missing..' more of its 130 species before this event awakens.',
          'Das Hoenn-Fundament ist unvollständig. Erfasse noch '..missing..' der 130 Arten, bevor dieses Ereignis erwacht.'),done)
        return true
      end
      local row=P.rows[character]
      if P.caught(game,row)then
        box(game,tr('The capture seal already remembers '..place.species..'. No second specimen appears.',
          'Das Fangsiegel erinnert sich an '..place.species..'. Ein zweites Exemplar erscheint nicht.'),done)
        return true
      end
      local state=S.state()
      state.weatherSealAwakened=state.weatherSealAwakened or{}
      if not state.weatherSealAwakened[character]then
        state.weatherSealAwakened[character]=true
        S.persist(state)
        box(game,tr('Your completed Hoenn foundation resonates with the seal. The stone breaks open; '..place.species..' is now waiting here. Approach it when you are ready.',
          'Dein vervollständigtes Hoenn-Fundament antwortet dem Siegel. Der Stein bricht auf; '..place.species..' wartet nun hier. Nähere dich, wenn du bereit bist.'),done)
        return true
      end
      local menu=ui.menu.new(game,place.species,{
        {value='approach',label=tr('APPROACH','NÄHERN'),right='Lv '..(P.seviiLevel and P.seviiLevel(game)or P.LEVEL)},
        {value='later',label=tr('LATER','SPÄTER')},
      },{onCancel=done,onChoose=function(choice,list)
        list:close()
        if choice.value=='approach'then P.challenge(game,ow,npc,done,row)
        elseif done then done()end
      end})
      menu.__vascHeaderLabel=tr('SEVII WEATHER SEAL','SEVII-WETTERSIEGEL')
      game.stack:push(menu)
      return true
    end
  end
  assert(P.bindSeviiSites(T.sites,function(game,base)
    return S.scaling and S.scaling.legend(game,base)or base
  end))
  local previous=S.chapters.journal
  S.chapters.journal=function()
    local text=previous()
    if S.state().expeditionComplete then
      text=text..'\n\n'..tr('WEATHER SEALS: The old Regi sanctuaries and weather portals are closed. The Regis answer only after the Tanoby balance quest. A character who visited their own black fissure door and completed the 130-species Hoenn foundation can awaken one weather seal on Sevii: RED at Mt Ember, BLUE in Icefall Cave, GREEN on Trainer Tower roof. Jirachi remains at the convergence door after the complete non-Jirachi Hoenn record.',
        'WETTERSIEGEL: Die alten Regi-Heiligtümer und Wetterportale sind geschlossen. Die Regis antworten nur nach dem Tanoby-Waagenrätsel. Nach dem Besuch der eigenen schwarzen Riss-Tür und 130 Hoenn-Arten kann jeder Charakter ein Wettersiegel auf Sevii erwecken: ROT am Glutberg, BLAU in der Eisfallhöhle, GRÜN auf dem Trainerturm-Dach. Jirachi bleibt nach dem vollständigen Hoenn-Eintrag ohne Jirachi an der Konvergenztür.')
    end
    return text
  end
  return T
end
