#!/usr/bin/env python3
"""Compile all authored Sevii species into capacity-checked reachable pools."""
import argparse
import hashlib
import json
from pathlib import Path
from audit_sevii_geometry import audit

ROOT=Path(__file__).resolve().parents[1]


def compile_habitats(bundle, output):
    requirements=json.loads((ROOT/'SEVII_SPECIES_REQUIREMENTS.json').read_text())
    authored=json.loads((ROOT/'sevii_habitats.json').read_text())
    targets={r['id']:r for r in requirements['ordinary']}
    expected=set(targets)
    named=[s for d in authored['districts']for s in d['species']]
    assert len(named)==len(set(named)), 'Duplicate authored species'
    assert set(named)==expected, {'missing':sorted(expected-set(named)),'unexpected':sorted(set(named)-expected)}
    proof=audit(bundle)
    assert proof['passed'], 'Fix disconnected geometry before assigning habitats'
    maps={m['id']:m for m in bundle['maps']}
    pools={};locations={}
    for district in authored['districts']:
        terrain=district['terrain']
        eligible=[]
        for mid,cells in sorted(proof['habitatSurfaces'].items()):
            if cells['source']in district['sources'] and cells[terrain]:
                eligible.append(mid)
        assert eligible, 'No reachable '+terrain+' cells in '+district['id']
        for species in district['species']:
            available=[mid for mid in eligible if len(pools.get((mid,terrain),{}).get('species',[]))<10]
            assert available, 'Expand habitat capacity for '+district['id']+'; no silent slot truncation'
            mid=min(available,key=lambda m:(len(pools.get((m,terrain),{}).get('species',[])),m))
            m=maps[mid]
            if (mid,terrain)not in pools:
                cells=proof['habitatSurfaces'][mid][terrain]
                anchor=min(cells,key=lambda p:(abs(p[0]-m['width'])+abs(p[1]-m['height']),p))
                pools[mid,terrain]=dict(map=mid,source=m['kaSeviiSource'],island=m['kaSeviiIsland'],terrain=terrain,
                    anchor=anchor,reachableCells=len(cells),species=[])
            source=targets[species]
            row=dict(id=species,key=source['key'],dex=source['dex'],generation=source['generation'],
                names=source['names'],district=district['id'],districtNames=district['names'],level=district['level'])
            pools[mid,terrain]['species'].append(row)
            locations[species]=dict(map=mid,source=m['kaSeviiSource'],island=m['kaSeviiIsland'],terrain=terrain,
                x=pools[mid,terrain]['anchor'][0],y=pools[mid,terrain]['anchor'][1],district=district['id'])
    assert set(locations)==expected
    coverage={}
    for character,required in requirements['characters'].items():
        missing=[s for s in required['missingSpecies']if s not in locations]
        assert not missing,(character,missing)
        coverage[character]=dict(required=len(required['missingSpecies']),assigned=len(required['missingSpecies']),missing=missing)
    output.mkdir(parents=True,exist_ok=True)
    result=dict(schema='kasc.sevii-compiled-habitats/v1',romSha1=bundle['romSha1'],
        authoredSha256=hashlib.sha256((ROOT/'sevii_habitats.json').read_bytes()).hexdigest(),
        ordinarySpecies=len(locations),districts=len(authored['districts']),characterCoverage=coverage,
        pools=[pools[k]for k in sorted(pools)],locations=locations)
    (output/'habitats.json').write_text(json.dumps(result,ensure_ascii=False,separators=(',',':'))+'\n')
    (output/'geometry-audit.json').write_text(json.dumps(proof,separators=(',',':'))+'\n')
    return result


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('bundle',type=Path);args=parser.parse_args()
    result=compile_habitats(json.loads(args.bundle.read_text()),args.bundle.parent)
    print('Compiled',result['ordinarySpecies'],'species in',len(result['pools']),'reachable pools;',result['districts'],'districts')
