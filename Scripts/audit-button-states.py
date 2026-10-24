#!/usr/bin/env python3
"""Validate the actual resolved Swift theme contrast CSV emitted by SubjectPolishTests.
Run: KOMOREBI_BUTTON_AUDIT=/tmp/buttons.csv swift test -c release --filter SubjectPolishTests
     python3 Scripts/audit-button-states.py /tmp/buttons.csv
"""
import csv, sys
with open(sys.argv[1], newline='') as source:
    rows = list(csv.DictReader(source))
failures = [r for r in rows if float(r['contrasto']) < float(r['soglia'])]
expected = {(theme, mode, style, state) for theme in ['komorebi', 'halloween']
            for mode in ['light', 'dark'] for style in ['action','primary','secondary','destructive','ghost']
            for state in ['default','hover','pressed','focus','disabled']}
actual = {(r['tema'],r['modalita'],r['stile'],r['stato']) for r in rows}
missing = expected - actual
for row in failures: print('FAIL',row)
if missing: print('Missing states:',sorted(missing))
print(f'{len(rows)} samples; {len(failures)} contrast failures; {len(missing)} missing states')
sys.exit(bool(failures or missing or not rows))
