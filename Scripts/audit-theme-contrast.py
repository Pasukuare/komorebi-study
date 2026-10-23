#!/usr/bin/env python3
"""Recompute WCAG 2.1 contrast from the actual resolved component RGB export.
Usage: audit-theme-contrast.py contrast.csv. Produces a checked CSV beside it.
The export is emitted by HalloweenThemeTests with KOMOREBI_HALLOWEEN_AUDIT.
"""
import csv,sys
from pathlib import Path
p=Path(sys.argv[1]);rows=list(csv.DictReader(p.open()))
def luminance(channels):
 return sum((v/12.92 if v<=.04045 else ((v+.055)/1.055)**2.4)*w for v,w in zip(channels,(.2126,.7152,.0722)))
failed=[]
for r in rows:
 a=luminance([float(r[k]) for k in ['fr','fg','fb']]);b=luminance([float(r[k]) for k in ['br','bg','bb']]);ratio=(max(a,b)+.05)/(min(a,b)+.05)
 r['rapporto_python']=ratio;r['esito']='OK' if ratio>=float(r['soglia']) else 'FAIL'
 if r['esito']=='FAIL':failed.append(r)
with p.with_name(p.stem+'-verificato.csv').open('w',newline='') as f:
 w=csv.DictWriter(f,fieldnames=list(rows[0]));w.writeheader();w.writerows(rows)
print(f'{len(rows)} combinazioni effettive: {len(failed)} sotto soglia.')
if failed:sys.exit(1)
