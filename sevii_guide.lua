-- Public field guide reads the same catalogue as encounters. No second
-- species list or claimed catch location can drift away from live pools.
return function(S,opts)
  local G={}
  local function tr(en,de)return opts.i18n and opts.i18n.text(en,de)or en end
  local function localized(names)return tr(names.en,names.de)end
  local reasons={
    ['beyond-kanto-sealed']={'This save still limits ordinary Pokemon to Kanto. Open BEYOND KANTO through Driftglass to enable these habitats and their evolutions.',
      'Dieser Spielstand begrenzt gewöhnliche Pokemon noch auf Kanto. Öffne JENSEITS VON KANTO über Driftglass, um diese Fangorte und Entwicklungen freizuschalten.'},
    ['league-required']={'Return after winning the Pokemon League.','Komm nach deinem Sieg in der Pokemon-Liga wieder.'},
    ['generation-profile']={'Your generation profile does not allow this species yet. In AUTO, finish Mara\'s buoy investigation on One Island.','Dein Generationsprofil erlaubt diese Art noch nicht. In AUTO: Schließe Maras Bojenforschung auf Eiland Eins ab.'},
    ['hoenn-disabled']={'Hoenn encounters are switched off in your settings.','Hoenn-Begegnungen sind in deinen Einstellungen abgeschaltet.'},
    ['missing-art']={'This species needs its graphics pack installed before it can appear.','Diese Art erscheint erst, wenn ihr Grafikpaket installiert ist.'},
    ['species-not-registered']={'This species is unavailable in the installed content.','Diese Art ist im installierten Inhalt nicht verfügbar.'},
    ['identity-mismatch']={'This species is unavailable in the installed content.','Diese Art ist im installierten Inhalt nicht verfügbar.'},
  }
  function G.entries(game,island)
    local rows={}
    for id,target in pairs(S.habitats.bySpecies)do
      if not island or target.pool.island==island then
        local allowed,reason=S.habitats.availability(game,target.row)
        rows[#rows+1]={id=id,label=localized(target.row.names),target=target,
          available=allowed,reason=not allowed and reason or nil}
      end
    end
    table.sort(rows,function(a,b)return a.label<b.label end)
    return rows
  end
  local function bearing(pool)
    local map=S.maps[pool.map];local source=map.kaSeviiSource
    local width,height=0,0;local count=0
    for _,m in pairs(S.maps)do
      if m.kaSeviiSource==source then
        local o,z=m.kaSeviiSourceOrigin,m.kaSeviiSourceSize
        width=math.max(width,o[1]+z[1]);height=math.max(height,o[2]+z[2]);count=count+1
      end
    end
    if count==1 then return ''end
    local x=map.kaSeviiSourceOrigin[1]+pool.anchor[1]
    local y=map.kaSeviiSourceOrigin[2]+pool.anchor[2]
    local horizontal=x<width/3 and tr('west','Westen')or x>width*2/3 and tr('east','Osten')or nil
    local vertical=y<height/3 and tr('north','Norden')or y>height*2/3 and tr('south','Süden')or nil
    return '\n'..tr('Search area: ','Suchgebiet: ')..
      (vertical and horizontal and vertical..' / '..horizontal or vertical or horizontal or tr('centre','Mitte'))
  end
  function G.describe(game,id)
    local target=S.habitats.bySpecies[id];if not target then return nil end
    local row,pool=target.row,target.pool
    local terrain={grass=tr('Tall grass','Hohes Gras'),water=tr('Water; use SURF','Wasser; benutze SURFER'),
      indoor=tr('Inside; walking encounters','Innenraum; Begegnungen beim Gehen')}
    local allowed,reason=S.habitats.availability(game,row)
    local status=tr('Can be caught here.','Hier fangbar.')
    if not allowed then local pair=reasons[reason]or reasons['species-not-registered'];status=tr(pair[1],pair[2])end
    local rare=S.habitats.rare and S.habitats.rare[id]
    local condition=''
    if rare then
      if rare.time=='night'then condition=tr('\nRarity: easier to find at night.','\nSeltenheit: nachts häufiger.')
      elseif rare.time=='day'then condition=tr('\nRarity: easier to find by day.','\nSeltenheit: tagsüber häufiger.')
      elseif rare.weather=='rain'then condition=tr('\nRarity: easier to find in rain.','\nSeltenheit: bei Regen häufiger.')end
    end
    local level=S.scaling and S.scaling.wild(game,row.level)or row.level
    if opts.difficulty then
      level=opts.difficulty.adjustLevel(level,'wild',opts.difficulty.progressBadges(game))
    end
    return localized(row.names)..' - '..tr('Island ','Eiland ')..pool.island..'\n'..
      localized(row.districtNames)..'\n'..S.maps[pool.map].label..bearing(pool)..'\n'..
      terrain[pool.terrain]..' / Lv. '..level..condition..'\n\n'..status
  end
  function G.open(game)
    local Menu=opts.ui and opts.ui.ListMenu or require('src.ui.ListMenu')
    local Text=require('src.render.TextBox')
    local islands={}
    for island=1,7 do islands[#islands+1]={label=tr('ISLAND ','EILAND ')..island,value=island}end
    game.stack:push(Menu.new(game,tr('FIELD GUIDE','FANGORTBUCH'),islands,{
      kind='sevii-guide',onChoose=function(item)
        -- Keep the island menu below the species menu. Cancel returns one
        -- level; closing a description preserves the selected species.
        local rows=G.entries(game,item.value)
        game.stack:push(Menu.new(game,tr('SIGHTINGS','SICHTUNGEN'),rows,{
          kind='sevii-sightings',pageJump=true,
          ascendantFocusHelp=function(entry)return entry and G.describe(game,entry.id)or''end,
          onChoose=function(entry)
            if opts.showGuideHelp then
              opts.showGuideHelp(game,entry.label,G.describe(game,entry.id))
            else game.stack:push(Text.new(game,G.describe(game,entry.id)))end
          end,
        }))
      end,
    }))
  end
  return G
end
