#!/usr/bin/env python3
"""Run isolated physical post-League journeys for RED, GREEN and BLUE."""
import argparse
import json
import os
from pathlib import Path
import subprocess

parser = argparse.ArgumentParser()
parser.add_argument('--engine', type=Path, required=True)
parser.add_argument('--love', type=Path, required=True)
parser.add_argument('--output', type=Path, required=True)
parser.add_argument('--identity-prefix', required=True)
parser.add_argument('--characters', nargs='+', choices=('RED', 'GREEN', 'BLUE'), default=['RED', 'GREEN', 'BLUE'])
parser.add_argument('--natural', action='store_true', help='Keep random encounters and track continuous team resources.')
parser.add_argument('--seed', type=int, default=90230)
args = parser.parse_args()
root = Path(__file__).resolve().parents[1]
args.output.mkdir(parents=True, exist_ok=True)
results = []
for index, character in enumerate(args.characters):
    report = 'journey-' + character.lower() + '.json'
    log = args.output / ('journey-' + character.lower() + '.log')
    env = dict(os.environ)
    env.update(POKEPORT_IDENTITY=args.identity_prefix + '-' + character.lower(),
               POKEPORT_VERSION='red', POKEPORT_SPEED='16', POKEPORT_NO_DISCORD='1',
               HABITAT_QA_ROOT=str(args.output), SEVII_KASC_ROOT=str(root),
               SEVII_QA_OUTPUT=str(args.output), SEVII_JOURNEY_CHARACTER=character,
               SEVII_JOURNEY_REPORT=report, SEVII_JOURNEY_RESUME='0', SEVII_JOURNEY_LAST='7',
               SEVII_JOURNEY_NATURAL='1' if args.natural else '0', SEVII_JOURNEY_SEED=str(args.seed + index),
               POKEPORT_DRIVER=str(root / 'tests/sevii_native_journey_driver.lua'))
    print('START', character, str(log), flush=True)
    with log.open('w') as stream:
        run = subprocess.run([str(args.love), '.'], cwd=args.engine, env=env,
                             stdout=stream, stderr=subprocess.STDOUT)
    if run.returncode:
        raise SystemExit(f'{character} failed ({run.returncode}); inspect {log}')
    data = json.loads((args.output / report).read_text())
    assert data['complete'] and data['chapter'] == 7
    assert data['character'] == character and data['characterEnabled']
    if args.natural:
        assert data['resources']['battles'] and len(data['resources']['rests']) == 7
        assert all(row.get('result') and row['result'] != 'lose' for row in data['resources']['battles'])
    results.append(data)
    print('PASS', character, data['steps'], 'navigator steps', flush=True)
(args.output / 'journeys-all-characters.json').write_text(json.dumps({
    'passed': True, 'characters': results, 'requestedCharacters': args.characters,
    'scope': ('Actual physical Sevii story journeys, all seven chapters and return to Kanto. '
             'Initial post-League/team fixtures, ordinary random encounters and persistent resources; '
             'visible overworld encounters disabled. Actual Center rests on island arrivals; '
             'not an optional-trainer or all-species capture test.' if args.natural else
             'Actual physical Sevii story journeys, all seven chapters and return to Kanto. '
             'Initial post-League/team fixtures and disabled random/visible encounters; '
             'not a balance or all-species capture test.')}, indent=2) + '\n')
print('SEVII_REQUESTED_CHARACTER_JOURNEYS_PASS', ','.join(args.characters), flush=True)
