"""Authenticate original BPRD movement labels independently of the importer.

Only numeric source metadata is emitted. No ROM artwork or saved game data.
Reference: pret/pokefirered/src/event_object_movement.c IsElevationMismatchAt.
"""
import argparse, hashlib, json, struct
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('--rom',type=Path,required=True);p.add_argument('--bundle',type=Path,required=True);p.add_argument('--output',type=Path,required=True);a=p.parse_args()
raw=a.rom.read_bytes();sha='18a3758ceeef2c77b315144be2c3910d6f1f69fe';assert len(raw)==0x1000000 and hashlib.sha1(raw).hexdigest()==sha
manifest=json.loads((Path(__file__).resolve().parents[1]/'scripts/sevii_maps_bprd.json').read_text())
def u32(at):return struct.unpack_from('<I',raw,at)[0]
def ptr(at):
 v=u32(at)-0x8000000;assert 0<=v<len(raw);return v
sources={}
for spec in manifest['maps']:
 head=ptr(ptr(0x3525cc+spec['group']*4)+spec['number']*4)
 layout=ptr(0x34eab0+(spec['layoutOverride']-1)*4)if spec.get('layoutOverride')else ptr(head)
 w,h=u32(layout),u32(layout+4);assert (w,h)==(spec['width'],spec['height']);grid=ptr(layout+12)
 cells=list(struct.unpack_from('<'+str(w*h)+'H',raw,grid))
 for override in spec.get('cellOverrides',[]):
  x,y=override['x'],override['y'];sx,sy=override['copyFrom'];cells[y*w+x]=cells[sy*w+sx]&~0xc00
 sources[spec['source']]=(w,h,cells)
bundle=json.loads(a.bundle.read_text());rows=[];cells_checked=0;blocked_edges=0;layer15=0
for d,ts in zip(bundle['maps'],bundle['tilesets']):
 w,h,cells=sources[d['kaSeviiSource']];ox,oy=d['kaSeviiSourceOrigin'];sw,sh=d['kaSeviiSourceSize'];mw,mh=d['width']*2,d['height']*2
 original=[''.join(chr(33+(cells[(oy+y)*w+ox+x]>>12))if x<sw and y<sh else'!'for x in range(mw))for y in range(mh)]
 if bundle.get('revision',0)>=8:assert d['kaSeviiElevations']==original,d['id']
 def kind(x,y):
  b=d['blocks'][(y//2)*d['width']+x//2];return ts['sourceCellCollision'][b][y%2*2+x%2]
 pairs=[]
 for y in range(mh):
  for x in range(mw):
   cells_checked+=1;e=ord(original[y][x])-33
   if kind(x,y)not in ('FLOOR','GRASS','WATER'):continue
   layer15+=e==15
   for direction,dx,dy in [('up',0,-1),('down',0,1),('left',-1,0),('right',1,0)]:
    xx,yy=x+dx,y+dy
    if not(0<=xx<mw and 0<=yy<mh)or kind(xx,yy)not in ('FLOOR','GRASS','WATER'):continue
    target=ord(original[yy][xx])-33
    if e!=0 and target not in(0,15)and e!=target:
     pairs.append([x,y,direction,xx,yy,e,target]);blocked_edges+=1
 rows.append({'map':d['id'],'source':d['kaSeviiSource'],'origin':[ox,oy],'rows':original,'blockedEdges':pairs})
defs={d['id']:d for d in bundle['maps']};tiles={d['tileset']:t for d,t in zip(bundle['maps'],bundle['tilesets'])};seams=[]
def seam_kind(d,x,y):
 if not(0<=x<d['width']*2 and 0<=y<d['height']*2):return 'WALL'
 block=d['blocks'][(y//2)*d['width']+x//2];return tiles[d['tileset']]['sourceCellCollision'][block][y%2*2+x%2]
by_id={r['map']:r for r in rows}
for d in bundle['maps']:
 for compass,c in d['connections'].items():
  target=defs[c['map']];w,h=d['width']*2,d['height']*2;tw,th=target['width']*2,target['height']*2
  border=[(x,0 if compass=='north'else h-1)for x in range(w)]if compass in ('north','south')else[(0 if compass=='west'else w-1,y)for y in range(h)]
  for x,y in border:
   off=c['offset']*2
   if compass=='north':xx,yy=x-off,th-1
   elif compass=='south':xx,yy=x-off,0
   elif compass=='west':xx,yy=tw-1,y-off
   else:xx,yy=0,y-off
   if seam_kind(d,x,y)not in('FLOOR','GRASS')or seam_kind(target,xx,yy)not in('FLOOR','GRASS'):continue
   a_layer=ord(by_id[d['id']]['rows'][y][x])-33;b_layer=ord(by_id[target['id']]['rows'][yy][xx])-33
   warp=any(q['x']==xx and q['y']==yy for q in target['kaSeviiWarps'])
   expected=warp or a_layer==0 or b_layer in(0,15)or a_layer==b_layer
   seams.append({'map':d['id'],'x':x,'y':y,'dir':{'north':'up','south':'down','west':'left','east':'right'}[compass],'dest':target['id'],'toX':xx,'toY':yy,'a':a_layer,'b':b_layer,'expected':expected})
assert layer15==0,'traversable layer 15 needs retained actor elevation support'
report={'completed':True,'romSHA1':sha,'sources':len(sources),'maps':rows,'cells':cells_checked,'blockedEdges':blocked_edges,'drySeams':seams,'traversableLayer15':layer15,'scope':'Original movement labels; exact source bytes including declared cell overrides and padding. Numeric labels are not world heights. Native and static renderer parity are separate checks.'}
a.output.write_text(json.dumps(report,indent=2)+'\n');print('SOURCE_ELEVATION_ORACLE',len(rows),cells_checked,blocked_edges)
