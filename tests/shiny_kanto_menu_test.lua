-- A fresh Kanto save can inspect its Catch Combo before the Hall of Fame.
local hooks,screens,saves,options={}, {}, {}, {shiny_catch_combo=true}
local opened
local mod={id='kanto_ascendant',exports={},
  hooks={wrap=function(_,name,fn)hooks[name]=fn end},
  events={on=function()end},
  save={get=function(_,key)return saves[key]end,
    set=function(_,key,value)saves[key]=value;return true end},
  options={get=function(_,key)return options[key]end},
  content={items={register=function()end},screens={register=function(_,id,screen)
    screens[id]=screen
  end}},
  ui={
    insertBefore=function(items,label,entry)
      local out={entry};for _,item in ipairs(items)do out[#out+1]=item end
      return out
    end,
    push=function(_,id)opened=id end,
    ListMenu={new=function(_,title,rows)return {title=title,rows=rows}end},
  },
}
local postgame={hasHallOfFame=function()return false end}
local Combo=dofile('shiny_catch_combo.lua')()
local Shiny=dofile('shiny_system.lua')(mod,{postgame=postgame,catchCombo=Combo})
saves.shiny_system={catchCombo={species='PIKACHU',count=11},seen={},caught={},
  encounters={},caughtCounts={},awards={}}
local game={save={pokedex={seen={},owned={}}},
  data={pokemon={PIKACHU={name='PIKACHU',dex=25}}}}
local items=hooks['ui.start_menu.items'](function(_,rows)return rows end,
  game,{{label='SAVE'}})
assert(items[1]and items[1].ascendantLabel=='SHINY DEX',
  'fresh Kanto save cannot open Shiny Dex')
items[1].onSelect()
assert(opened=='AscendantShinyDex')
local menu=screens.AscendantShinyDex.new(game)
assert(menu.rows[1].label=='CATCH COMBO'and menu.rows[1].right=='x11',
  'Kanto Catch Combo count is not visible before the League')
options.shiny_catch_combo=false
menu=screens.AscendantShinyDex.new(game)
assert(menu.rows[1].label~='CATCH COMBO','disabled Card still shows combo')
assert(Shiny.catchCombo().count==11,'turning off Card destroyed saved history')
print('PASS Kanto pre-League Catch Combo menu and optional Card')
