#!/usr/bin/env python3
"""Independent cell-graph audit: every imported doorway needs a route home.

Reads only the generated bundle. Accounts for forced door transitions,
water, and native map seams. Reports disconnected maps/doors as failures;
never treats registry presence alone as proof that an area is playable.
"""
import argparse
from collections import defaultdict, deque
import json
from pathlib import Path


def audit(bundle):
    maps = {m['id']: m for m in bundle['maps']}
    tiles = {t['id']: t for t in bundle['tilesets']}
    sources = defaultdict(list)
    for m in maps.values(): sources[m['kaSeviiSource']].append(m)
    def locate(source,x,y):
        for m in sources[source]:
            ox,oy=m['kaSeviiSourceOrigin'];w,h=m['kaSeviiSourceSize']
            if ox<=x<ox+w and oy<=y<oy+h:return m['id'],x-ox,y-oy
    kinds = {}
    for mid,m in maps.items():
        rows=tiles[m['tileset']]['sourceCellCollision']
        for y in range(m['height']*2):
            for x in range(m['width']*2):
                kind=rows[m['blocks'][(y//2)*m['width']+x//2]][(y%2)*2+x%2]
                if kind!='WALL':kinds[mid,x,y]=kind
    portal_cells={(m['id'],w['x'],w['y']) for m in maps.values()for w in m['kaSeviiWarps']}
    doors={};invalid=[]
    for mid,m in maps.items():
        for w in m['kaSeviiWarps']:
            target=maps[w['destMap']]
            dest=next(d for d in target['kaSeviiWarps']if d['sourceIndex']==w['destWarp'])
            ox,oy=target['kaSeviiSourceOrigin'];landing=None
            for dx,dy in [(0,1),(0,-1),(1,0),(-1,0)]:
                cell=locate(target['kaSeviiSource'],ox+dest['x']+dx,oy+dest['y']+dy)
                if cell and kinds.get(cell)in('FLOOR','GRASS')and cell not in portal_cells:
                    landing=cell;break
            if landing:doors[mid,w['x'],w['y']]=landing
            else:invalid.append({'map':mid,'warp':w['sourceIndex'],'reason':'unsafe-arrival'})
    falls={(m['id'],r['x'],r['y']):(r['map'],r['toX'],r['toY']) for m in maps.values()for r in m.get('kaSeviiFalls',[])}
    jumps=defaultdict(list)
    for mid,m in maps.items():
        for row in m.get('kaSeviiLedges',[]):
            x,y,dx,dy=row['x'],row['y'],row['dx'],row['dy']
            ox,oy=m['kaSeviiSourceOrigin']
            dest=locate(m['kaSeviiSource'],ox+x+dx*2,oy+y+dy*2)
            if dest in kinds:jumps[mid,x,y].append(dest)
    edges={};reverse=defaultdict(list)
    for cell in kinds:
        mid,x,y=cell;m=maps[mid];neighbors=[]
        if cell in doors:neighbors=[doors[cell]]
        elif cell not in portal_cells:
            # Thin ice permits the first crossing; revisiting it falls down.
            # This graph proves possible paths, not every puzzle-state order.
            if cell in falls:
                if falls[cell] not in kinds:invalid.append({'cell':cell,'reason':'unsafe-icefall'})
                else:neighbors.append(falls[cell])
            for dx,dy,side in [(1,0,'east'),(-1,0,'west'),(0,1,'south'),(0,-1,'north')]:
                nx,ny=x+dx,y+dy;dest=(mid,nx,ny)
                if not(0<=nx<m['width']*2 and 0<=ny<m['height']*2):
                    c=m['connections'].get(side)
                    if not c:continue
                    t=maps[c['map']];off=c['offset']*2
                    if side=='east':nx,ny=0,y-off
                    elif side=='west':nx,ny=t['width']*2-1,y-off
                    elif side=='south':nx,ny=x-off,0
                    else:nx,ny=x-off,t['height']*2-1
                    dest=(t['id'],nx,ny)
                if dest in kinds:neighbors.append(dest)
            neighbors.extend(jumps[cell])
        edges[cell]=neighbors
        for d in neighbors:reverse[d].append(cell)
    def visit(start,graph):
        seen=set(start);todo=deque(start)
        while todo:
            for d in graph.get(todo.popleft(),[]):
                if d not in seen:seen.add(d);todo.append(d)
        return seen
    report={'maps':len(maps),'walkableCells':len(kinds),'doors':len(doors),'invalid':invalid,'islands':[], 'habitatSurfaces':{}}
    for island in range(1,8):
        harbors=[m for m in maps.values()if m['kaSeviiIsland']==island and m['kaSeviiSource'].endswith('Island_Harbor')]
        assert len(harbors)==1,(island,harbors)
        home=(harbors[0]['id'],8,4);assert home in kinds
        reached=visit([home],edges);safe=visit([home],reverse)
        for cell in sorted(reached & safe):
            mid,x,y=cell
            if cell in portal_cells or cell in falls:continue
            if any((mid,x+dx,y+dy) in portal_cells for dx,dy in [(0,1),(0,-1),(1,0),(-1,0)]):continue
            kind=kinds[cell]
            terrain='water' if kind=='WATER' else 'grass' if kind=='GRASS' else 'indoor' if not maps[mid]['outdoor'] else None
            if terrain:
                record=report['habitatSurfaces'].setdefault(mid,{'source':maps[mid]['kaSeviiSource'],'island':island,'grass':[],'water':[],'indoor':[]})
                record[terrain].append([x,y])
        ids={mid for mid,_,_ in reached}
        report['islands'].append({'island':island,'reachableCells':len(reached),
            'unreachableMaps':[mid for mid,m in maps.items()if m['kaSeviiIsland']==island and mid not in ids
                and any(k in ('FLOOR','GRASS')for (m2,x,y),k in kinds.items()if m2==mid)],
            'sceneryFragments':[mid for mid,m in maps.items()if m['kaSeviiIsland']==island and mid not in ids
                and not any(k in ('FLOOR','GRASS')for (m2,x,y),k in kinds.items()if m2==mid)],
            'strandedDoorways':[{'map':mid,'x':x,'y':y,'destination':doors[mid,x,y]}for mid,x,y in doors
                if maps[mid]['kaSeviiIsland']==island and doors[mid,x,y]not in safe],
            'unreachableDoorways':[{'map':mid,'x':x,'y':y}for mid,x,y in doors
                if maps[mid]['kaSeviiIsland']==island and (mid,x,y)not in reached]})
    report['passed']=not invalid and all(not r[k]for r in report['islands']for k in ('unreachableMaps','strandedDoorways','unreachableDoorways'))
    return report


if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('bundle',type=Path);p.add_argument('--report',type=Path,required=True)
    args=p.parse_args();result=audit(json.loads(args.bundle.read_text()));args.report.write_text(json.dumps(result,indent=2)+'\n')
    print('Maps',result['maps'],'doorways',result['doors'],'cells',result['walkableCells'])
    for row in result['islands']:print('Island',row['island'],'unreachable maps',len(row['unreachableMaps']),'stranded doors',len(row['strandedDoorways']),'unreachable doors',len(row['unreachableDoorways']))
    raise SystemExit(0 if result['passed']else 1)
