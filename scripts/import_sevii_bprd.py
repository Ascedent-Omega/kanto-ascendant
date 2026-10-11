#!/usr/bin/env python3
"""Private, reproducible seven-island import from the user's German FireRed.

No ROM or extracted graphics are supplied by this script. Outputs are local
build products. Format reference: pret/pokefirered include/global.fieldmap.h.
Supports the exact BPRD revision-0 image below, never guesses US offsets.
"""
import argparse
import copy
import hashlib
import json
import math
import struct
from pathlib import Path

from PIL import Image

SHA1 = '18a3758ceeef2c77b315144be2c3910d6f1f69fe'
GROUPS = 0x3525CC
LAYOUTS = 0x34EAB0
PREFIX = 'KA_SEVII_'
MANIFEST = Path(__file__).with_name('sevii_maps_bprd.json')

WATER = {0x10, 0x11, 0x12, 0x13, 0x15, 0x1A, 0x1B, 0x50, 0x51, 0x52, 0x53}


class Rom:
    def __init__(self, data):
        if len(data) != 0x1000000 or hashlib.sha1(data).hexdigest() != SHA1:
            raise ValueError('Requires verified German FireRed BPRD revision 0; unsupported ROM')
        self.data = data

    def u16(self, pos):
        return struct.unpack_from('<H', self.data, pos)[0]

    def u32(self, pos):
        return struct.unpack_from('<I', self.data, pos)[0]

    def ptr(self, pos):
        value = self.u32(pos) - 0x08000000
        if not 0 <= value < len(self.data):
            raise ValueError(f'Invalid ROM pointer at {pos:#x}')
        return value

    def lz(self, pos):
        if self.data[pos] != 0x10:
            raise ValueError('Invalid LZ77 header')
        size = self.u32(pos) >> 8
        if not 0 < size <= 0x100000:
            raise ValueError('Invalid decompressed size')
        pos += 4
        out = bytearray()
        while len(out) < size:
            flags = self.data[pos]
            pos += 1
            for bit in range(7, -1, -1):
                if len(out) >= size:
                    break
                if flags & (1 << bit):
                    a, b = self.data[pos:pos + 2]
                    pos += 2
                    length, distance = (a >> 4) + 3, ((a & 15) << 8 | b) + 1
                    if distance > len(out):
                        raise ValueError('Invalid LZ77 backreference')
                    for _ in range(min(length, size - len(out))):
                        out.append(out[-distance])
                else:
                    out.append(self.data[pos])
                    pos += 1
        return bytes(out)

    def tileset(self, pos):
        tiles, palettes, metatiles, attrs = (self.ptr(pos + i) for i in (4, 8, 12, 20))
        raw = self.lz(tiles) if self.data[pos] else self.data[tiles:tiles + 640 * 32]
        return dict(raw=raw, palettes=palettes, metatiles=metatiles, attrs=attrs)


def rgb(value):
    return tuple(round(((value >> shift) & 31) * 255 / 31) for shift in (0, 5, 10)) + (255,)


def metatile(rom, pair, mid):
    ts = pair[0 if mid < 640 else 1]
    index = mid if mid < 640 else mid - 640
    entries = struct.unpack_from('<8H', rom.data, ts['metatiles'] + index * 16)
    result = Image.new('RGBA', (16, 16), (0, 0, 0, 255))
    pixels = result.load()
    for layer in range(2):
        for quadrant in range(4):
            entry = entries[layer * 4 + quadrant]
            tid, pal = entry & 1023, entry >> 12
            source = pair[0 if tid < 640 else 1]
            tid = tid if tid < 640 else tid - 640
            palette = pair[0 if pal < 7 else 1]['palettes'] + pal * 32
            for y in range(8):
                for x in range(8):
                    sx, sy = (7 - x if entry & 1024 else x), (7 - y if entry & 2048 else y)
                    offset = tid * 32 + sy * 4 + sx // 2
                    if offset >= len(source['raw']):
                        raise ValueError(f'Tile {tid} exceeds tileset')
                    colour = (source['raw'][offset] >> (4 * (sx % 2))) & 15
                    if layer == 0 or colour != 0:
                        pixels[(quadrant % 2) * 8 + x, (quadrant // 2) * 8 + y] = rgb(rom.u16(palette + colour * 2))
    return result, rom.u32(ts['attrs'] + index * 4) & 511


DIRECTIONS = {1: 'south', 2: 'north', 3: 'west', 4: 'east'}
OPPOSITE = {'north': 'south', 'south': 'north', 'west': 'east', 'east': 'west'}
# The fourth chapter retraces an old boundary around the archive stone.
# Coordinates are original source cells, independent of runtime fragments.
MEMORY_RING = [(12,16),(11,16),(11,15),(11,14),(12,14),(13,14),(13,15),(13,16)]


def decode_source(rom, spec, selected):
    group, number = spec['group'], spec['number']
    header = rom.ptr(rom.ptr(GROUPS + group * 4) + number * 4)
    layout = rom.ptr(header)
    if spec.get('layoutOverride'):
        layout = rom.ptr(LAYOUTS + (spec['layoutOverride'] - 1) * 4)
    width, height = rom.u32(layout), rom.u32(layout + 4)
    assert (width, height) == (spec['width'], spec['height']), spec['source']
    grid = rom.ptr(layout + 12)
    pair = [rom.tileset(rom.ptr(layout + i)) for i in (16, 20)]
    cache, cells, kinds = {}, [], []
    overrides={(r['x'],r['y']):r for r in spec.get('cellOverrides',[])}
    for y in range(height):
        for x in range(width):
            value = rom.u16(grid + (y * width + x) * 2)
            if (x,y) in overrides:
                sx,sy=overrides[x,y]['copyFrom']
                value=rom.u16(grid+(sy*width+sx)*2) & ~0xC00
            mid, collision = value & 1023, (value >> 10) & 3
            if mid not in cache:
                cache[mid] = metatile(rom, pair, mid)
            behavior = cache[mid][1]
            kind = ('WALL' if collision or behavior in (0x38, 0x39, 0x3A, 0x3B)
                    else 'WATER' if behavior in WATER
                    else 'GRASS' if behavior in (2, 0xD1) else 'FLOOR')
            cells.append(value)
            kinds.append(kind)
    events = rom.ptr(header + 4)
    warps, sealed = [], []
    count = rom.data[events + 1]
    if count:
        base = rom.ptr(events + 8)
        for i in range(count):
            x, y, elevation, dest, num, grp = struct.unpack_from('<hhBBBB', rom.data, base + 8 * i)
            assert 0 <= x < width and 0 <= y < height, (spec['source'], x, y)
            target = selected.get((grp, num))
            override=spec.get('warpOverrides',{}).get(str(i+1))
            disabled=i+1 in spec.get('disabledWarps',[])
            if not disabled and (override or target and dest != 255):
                warps.append(dict(x=x, y=y, target=override['target'] if override else target['source'],
                    destWarp=override['destWarp'] if override else dest+1, sourceIndex=i+1))
                kinds[y * width + x] = 'FLOOR'
            else:
                sealed.append(dict(x=x, y=y, destination=[grp, num], reason='unused-layout-event' if disabled else 'dynamic-exit' if dest == 255 else 'outside-sevii'))
                kinds[y * width + x] = 'WALL'
    connections = []
    if rom.u32(header + 12):
        cp = rom.ptr(header + 12)
        count = rom.u32(cp)
        assert count <= 8
        base = rom.ptr(cp + 4) if count else 0
        for i in range(count):
            direction, offset, grp, num = struct.unpack_from('<IiBB', rom.data, base + i * 12)
            target = selected.get((grp, num))
            if target:
                assert offset % 2 == 0, 'Gen1 connections require whole block offsets'
                connections.append(dict(direction=DIRECTIONS[direction], offset=offset, target=target['source']))
            else:
                sealed.append(dict(edge=direction, destination=[grp, num]))
    # Block zero is a solid border even when its graphic is a source floor.
    if 0 not in cache:
        cache[0] = metatile(rom, pair, 0)
    if spec['source'] in ('FourIsland_IcefallCave_1F', 'FourIsland_IcefallCave_Back'):
        # This picture is selected by FireRed's step script, not necessarily
        # present in the static layout. Preserve it for the native crack step.
        cache[0x35A] = metatile(rom, pair, 0x35A)
    if spec['source'] == 'FourIsland_IcefallCave_Back':
        cache[0x359] = metatile(rom, pair, 0x359)
        for x, y in MEMORY_RING:
            at = y * width + x
            assert kinds[at] == 'FLOOR', 'Memory ring needs native dry floor'
            cells[at] = (cells[at] & ~1023) | 0x359
    return dict(spec=spec, header=header, layout=layout, cells=cells, kinds=kinds,
                cache=cache, warps=warps, sealed=sealed, connections=connections)


def block_keys(src, rect):
    x0, y0, width, height = rect
    sw = src['spec']['width']
    keys = [((0, 'WALL'),) * 4]
    lookup, blocks = {keys[0]: 0}, []
    for by in range(math.ceil(height / 2)):
        for bx in range(math.ceil(width / 2)):
            key = []
            for q in range(4):
                x, y = bx * 2 + q % 2, by * 2 + q // 2
                at = (y + y0) * sw + x + x0
                key.append((src['cells'][at], src['kinds'][at]) if x < width and y < height else (0, 'WALL'))
            key = tuple(key)
            if key not in lookup:
                lookup[key] = len(keys)
                keys.append(key)
            blocks.append(lookup[key])
    return keys, blocks


def partitions(src):
    spec = src['spec']
    w, h = spec['width'], spec['height']
    # Keep the released prototype's map IDs and local coordinates stable.
    if spec['name'] == 'KINDLE':
        return [('KINDLE_NORTH', (0, 0, 24, 70), 2108), ('KINDLE', (0, 70, 24, 70), 2101)]
    if 'index' in spec:
        return [(spec['name'], (0, 0, w, h), spec['index'])]
    # All new connected outdoor maps use the same 24x10-cell lattice. This
    # preserves the three distinct west connections of Six Island Water Path
    # without overwriting one direction in Gen1's single-edge schema.
    if spec.get('habitatGrid'):
        assert not src['connections'], 'Habitat partitions must not misalign exterior seams'
        cw,ch=spec['habitatGrid']
        assert cw%2==ch%2==0 and cw>0 and ch>0
    elif src['connections']:
        cw, ch = 24, 10
        assert w % cw == 0 and h % ch == 0, spec['source']
        for c in src['connections']:
            assert c['offset'] % (cw if c['direction'] in ('north', 'south') else ch) == 0
    elif len(block_keys(src, (0, 0, w, h))[0]) > 256:
        cw, ch = 24, 20
    else:
        return [(spec['name'], (0, 0, w, h), None)]
    return [(spec['name'] if x == y == 0 else spec['name'] + f'_X{x}_Y{y}',
             (x, y, min(cw, w-x), min(ch, h-y)), None)
            for y in range(0, h, ch) for x in range(0, w, cw)]


def inside(rect, x, y):
    rx, ry, rw, rh = rect
    return rx <= x < rx + rw and ry <= y < ry + rh


def connect(a, direction, b, offset):
    assert offset % 2 == 0
    row = dict(map=b['id'], offset=offset // 2)
    old = a['connections'].get(direction)
    assert not old or old == row, ('ambiguous connection', a['id'], direction, old, row)
    a['connections'][direction] = row


def wire_edges(sources, areas):
    for source, chunks in areas.items():
        for a in chunks:
            ax, ay, aw, ah = a['rect']
            for b in chunks:
                if a is b:
                    continue
                bx, by, bw, bh = b['rect']
                if ax == bx:
                    if ay + ah == by: connect(a, 'south', b, 0)
                    if by + bh == ay: connect(a, 'north', b, 0)
                if ay == by:
                    if ax + aw == bx: connect(a, 'east', b, 0)
                    if bx + bw == ax: connect(a, 'west', b, 0)
        sw, sh = sources[source]['spec']['width'], sources[source]['spec']['height']
        for c in sources[source]['connections']:
            direction = c['direction']
            vertical = direction in ('north', 'south')
            target = sources[c['target']]['spec']
            for a in chunks:
                ax, ay, aw, ah = a['rect']
                edge = {'north': ay == 0, 'south': ay+ah == sh, 'west': ax == 0, 'east': ax+aw == sw}
                if not edge[direction]: continue
                for b in areas[c['target']]:
                    bx, by, bw, bh = b['rect']
                    other = {'south': by == 0, 'north': by+bh == target['height'],
                             'east': bx == 0, 'west': bx+bw == target['width']}
                    if not other[direction]: continue
                    a0, alen = (ax, aw) if vertical else (ay, ah)
                    b0, blen = (bx, bw) if vertical else (by, bh)
                    if max(a0, b0+c['offset']) < min(a0+alen, b0+c['offset']+blen):
                        connect(a, direction, b, c['offset']+b0-a0)
    for chunks in areas.values():
        for m in chunks:
            for direction, c in m['connections'].items():
                target = next(t for ts in areas.values() for t in ts if t['id'] == c['map'])
                back = target['connections'].get(OPPOSITE[direction])
                assert back and back['map'] == m['id'] and back['offset'] == -c['offset'], ('nonreciprocal seam', m['id'], direction)


def render_chunk(src, m, output, animations=None):
    keys, blocks = block_keys(src, m['rect'])
    m['kaSeviiIceBlocks'] = []
    m['kaSeviiTraceBlocks'] = []
    m['kaSeviiStationGate'] = []
    source = src['spec']['source']
    if source in ('FourIsland_IcefallCave_1F', 'FourIsland_IcefallCave_Back'):
        lookup = {key: i for i, key in enumerate(keys)}
        for at, bid in enumerate(blocks):
            key = keys[bid]
            thin = [q for q, (value, _) in enumerate(key)
                    if src['cache'][value & 1023][1] in (0x26, 0x27)]
            if not thin: continue
            bx, by = at % m['width'], at // m['width']
            variants = {'0': bid}
            for mask in range(1, 2 ** len(thin)):
                variant = list(key)
                for bit, q in enumerate(thin):
                    if mask & (1 << bit):
                        value, kind = variant[q]
                        variant[q] = ((value & ~1023) | 0x35A, kind)
                variant = tuple(variant)
                if variant not in lookup:
                    lookup[variant] = len(keys)
                    keys.append(variant)
                variants[str(mask)] = lookup[variant]
            rows = m['kaSeviiIceBlocks'] if source.endswith('_1F') else m['kaSeviiTraceBlocks']
            rows.append(dict(x=bx, y=by, variants=variants,
                cells=[dict(x=bx*2+q%2, y=by*2+q//2, bit=1 << bit)
                       for bit, q in enumerate(thin)]))
    if source == 'FiveIsland_RocketWarehouse':
        # The narrow north-east airlock is controlled by chapter five.
        # Base data stays open for geometry audits; runtime restores its
        # saved open/closed state. Only the door cell changes collision.
        x,y=22-m['rect'][0],8-m['rect'][1]
        bx,by=x//2,y//2;bid=blocks[by*m['width']+bx];q=y%2*2+x%2
        closed=list(keys[bid]);assert closed[q][1]=='FLOOR'
        wall_at=8*src['spec']['width']+21
        assert src['kinds'][wall_at]=='WALL'
        closed[q]=(src['cells'][wall_at],'WALL')
        closed=tuple(closed)
        if closed not in keys:keys.append(closed)
        m['kaSeviiStationGate']=[dict(x=bx,y=by,cells=[dict(x=x,y=y,bit=1)],
            variants={'0':keys.index(closed),'1':bid})]
    assert len(keys) <= 256, (m['id'], len(keys))
    iw, ih = 512, math.ceil(len(keys) / 16) * 32
    atlas = Image.new('RGBA', (iw, ih), (0, 0, 0, 255))
    name = m['id'][len(PREFIX):].lower()
    ts = dict(id=m['tileset'], image='assets/sevii_local/' + name + '.png', imageWidth=iw,
              imageHeight=ih, tilesPerRow=64, trueColor=True, blocks=[], walkable=[],
              grassTiles=[], waterTiles=[], doorTiles=[], warpTiles=[], counterTiles=[], sourceCellCollision=[])
    for bid, key in enumerate(keys):
        px, py = bid % 16 * 32, bid // 16 * 32
        row = [(py // 8 + y) * 64 + px // 8 + x for y in range(4) for x in range(4)]
        ts['blocks'].append(row)
        ts['sourceCellCollision'].append([kind for _, kind in key])
        for q, (value, kind) in enumerate(key):
            atlas.paste(src['cache'][value & 1023][0], (px + q % 2 * 16, py + q // 2 * 16))
            feet = row[(q // 2 * 2 + 1) * 4 + q % 2 * 2]
            if kind not in ('WALL', 'WATER'): ts['walkable'].append(feet)
            if kind == 'WATER': ts['waterTiles'].append(feet)
            if kind == 'GRASS': ts['grassTiles'].append(feet)
    if animations is not None:
        animations.register(ts, src, keys)
    m['blocks'] = blocks
    # Movement elevations are discrete collision layers, not voxel heights.
    # Retain the complete native cell grid, including transparent layer 0
    # stair mouths and layer 15, instead of allowing adjacent 3/5 terraces
    # to be crossed wherever their artwork is otherwise walkable.
    x0, y0, w, h = m['rect']
    m['kaSeviiElevations'] = [
        ''.join(chr(33 + (src['cells'][(y+y0)*src['spec']['width']+x+x0] >> 12))
                if x < w and y < h else '!' for x in range(m['width']*2))
        for y in range(m['height']*2)
    ]
    m['kaSeviiLedges'] = []
    x0,y0,w,h = m['rect']
    for y in range(h):
        for x in range(w):
            at=(y+y0)*src['spec']['width']+x+x0
            behavior=src['cache'][src['cells'][at] & 1023][1]
            direction={0x38:('right',1,0),0x39:('left',-1,0),0x3A:('up',0,-1),0x3B:('down',0,1)}.get(behavior)
            if direction:
                facing,dx,dy=direction
                sx,sy=x-dx,y-dy
                if 0<=sx<w and 0<=sy<h:
                    b=blocks[(sy//2)*m['width']+sx//2]
                    if ts['sourceCellCollision'][b][sy%2*2+sx%2] in ('FLOOR','GRASS'):
                        stand=ts['blocks'][b][(sy%2*2+1)*4+sx%2*2]
                        front=ts['blocks'][blocks[(y//2)*m['width']+x//2]][(y%2*2+1)*4+x%2*2]
                        m['kaSeviiLedges'].append(dict(x=sx,y=sy,dx=dx,dy=dy,
                            standingTile=stand,ledgeTile=front,facing=facing,input=facing,tileset=m['tileset']))
    atlas.save(output / (name + '.png'))
    return ts


def import_maps(rom, output):
    specs = json.loads(MANIFEST.read_text())['maps']
    selected = {(s['group'], s['number']): s for s in specs}
    sources = {s['source']: decode_source(rom, s, selected) for s in specs}
    # Some GBA exits are dynamic/script-owned. Seal only that unsupported
    # entrance instead of silently routing it to an unrelated warp slot.
    for src in sources.values():
        retained = []
        for w in src['warps']:
            target = sources[w['target']]
            if any(t['sourceIndex'] == w['destWarp'] for t in target['warps']):
                retained.append(w)
            else:
                src['kinds'][w['y']*src['spec']['width']+w['x']] = 'WALL'
                src['sealed'].append(dict(x=w['x'], y=w['y'], destination=w['target'], reason='script-owned-target'))
        src['warps'] = retained
    areas, next_index = {}, 2200
    for source, src in sources.items():
        areas[source] = []
        for name, rect, fixed_index in partitions(src):
            index = fixed_index if fixed_index is not None else next_index
            if fixed_index is None: next_index += 1
            x, y, w, h = rect
            m = dict(id=PREFIX+name, index=index, label=src['spec']['label'], tileset=PREFIX+'TILES_'+name,
                     width=math.ceil(w/2), height=math.ceil(h/2), borderBlock=0, outdoor=src['spec']['group'] == 3,
                     connections={}, warps=[], objects=[], signs=[], kaSeviiWarps=[],
                     kaSeviiSource=source, kaSeviiIsland=src['spec']['island'],
                     kaSeviiSourceOrigin=[x,y], kaSeviiSourceSize=[w,h],
                     kaSeviiSealed=[dict(s, x=s['x']-x, y=s['y']-y) for s in src['sealed'] if 'x' in s and inside(rect,s['x'],s['y'])],
                     kaOwner='kasc.sevii-expedition/v1', voxelMode='FULL', voxelEnabled=True,
                     voxelRevision=1, rect=rect)
            areas[source].append(m)
    wire_edges(sources, areas)
    output.mkdir(parents=True, exist_ok=True)
    from sevii_tile_animations_bprd import AnimationCompiler
    animations = AnimationCompiler(rom, output)
    bundle = dict(schema='kasc.sevii-bprd/v1', revision=8, romSha1=SHA1, maps=[], tilesets=[],
                  limitations=['Flattened GBA layers',
                               'Cross-fragment ledge fronts require additional movement handling',
                               'Script-owned dynamic exits require authored replacement'])
    audit = []
    for source, src in sources.items():
        for m in areas[source]:
            x, y, w, h = m['rect']
            for warp in src['warps']:
                if not inside(m['rect'], warp['x'], warp['y']): continue
                dest = next(t for t in sources[warp['target']]['warps'] if t['sourceIndex'] == warp['destWarp'])
                target = next(t for t in areas[warp['target']] if inside(t['rect'],dest['x'],dest['y']))
                m['kaSeviiWarps'].append(dict(x=warp['x']-x, y=warp['y']-y, destMap=target['id'],
                    destWarp=warp['destWarp'], sourceIndex=warp['sourceIndex']))
            bundle['tilesets'].append(render_chunk(src,m,output,animations))
            m['kaSeviiFalls']=[]
            if source=='FourIsland_IcefallCave_1F':
                for cy in range(h):
                    for cx in range(w):
                        at=(cy+y)*src['spec']['width']+cx+x
                        behavior=src['cache'][src['cells'][at] & 1023][1]
                        if behavior in (0x26,0x27):
                            target=next(t for t in areas['FourIsland_IcefallCave_B1F']if inside(t['rect'],cx+x,cy+y))
                            m['kaSeviiFalls'].append(dict(x=cx,y=cy,map=target['id'],
                                toX=cx+x-target['rect'][0],toY=cy+y-target['rect'][1]))
            bundle['maps'].append(m)
        sw, sh = src['spec']['width'], src['spec']['height']
        preview = Image.new('RGBA',(sw*16,sh*16))
        for y in range(sh):
            for x in range(sw): preview.paste(src['cache'][src['cells'][y*sw+x] & 1023][0], (x*16,y*16))
        preview.save(output/(src['spec']['name'].lower()+'-preview.png'))
        audit.append(dict(source=source, island=src['spec']['island'], header=hex(src['header']), layout=hex(src['layout']),
            size=[sw,sh], maps=[m['id'] for m in areas[source]], importedWarps=len(src['warps']), sealedExits=src['sealed']))
    for m in bundle['maps']:
        del m['rect']
    from build_sevii_habitats import compile_habitats
    compile_habitats(bundle,output)
    (output/'bundle.json').write_text(json.dumps(bundle,separators=(',',':'))+'\n')
    (output/'import-report.json').write_text(json.dumps(dict(romSha1=SHA1,sources=audit),indent=2)+'\n')
    return bundle


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('rom', type=Path)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    bundle = import_maps(Rom(args.rom.read_bytes()), args.output)
    print(f"Imported {len(bundle['maps'])} maps from verified BPRD ROM into {args.output}")


if __name__ == '__main__':
    main()
