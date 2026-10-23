#!/usr/bin/env python3
"""Compare deterministic code workloads in Release; does not measure the real UI.

The baseline is copied to a temporary package. The caller's checkout and personal
archive are never edited. Build/test logs and all individual samples are retained.
"""
import argparse
import json
import os
from pathlib import Path
import shutil
import statistics
import subprocess
import tempfile

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--baseline-source', type=Path, required=True)
parser.add_argument('--output', type=Path, required=True)
parser.add_argument('--runs', type=int, default=3)
parser.add_argument('--disable-sandbox', action='store_true')
args = parser.parse_args()
if args.runs < 1:
    parser.error('--runs must be positive')
root = Path(__file__).resolve().parent.parent
baseline_source = args.baseline_source.resolve()
output = args.output.resolve()
output.mkdir(parents=True, exist_ok=True)
flags = ['--disable-sandbox'] if args.disable_sandbox else []

def test(package, log_name, extra=(), sample=None):
    env = os.environ.copy()
    env.pop('KOMOREBI_BENCHMARK_OUTPUT', None)
    if sample:
        env['KOMOREBI_BENCHMARK_OUTPUT'] = str(sample)
    command = ['swift', 'test', '-c', 'release', '--package-path', str(package), '--filter', 'testReleaseWorkloads', *flags, *extra]
    with (output / log_name).open('w') as log:
        subprocess.run(command, env=env, stdout=log, stderr=subprocess.STDOUT, check=True)

with tempfile.TemporaryDirectory(prefix='komorebi-benchmark-baseline-') as temporary:
    baseline = Path(temporary)
    for name in ['Sources', 'Tests']:
        shutil.copytree(baseline_source / name, baseline / name)
    shutil.copy2(baseline_source / 'Package.swift', baseline / 'Package.swift')
    harness = (root / 'Tests/PerformanceRegressionTests.swift').read_text().split('\nextension PerformanceRegressionTests')[0]
    # Compatibility adapter: the old UI evaluated each cell/bucket separately.
    adapter = '''\n@MainActor extension StudyStore {
    func calendarShares(in intervals: [DateInterval]) -> [[CalendarSubjectShare]] { intervals.map { calendarShares(in: $0) } }
    func totals(in intervals: [DateInterval], subject: UUID? = nil) -> [Double] { intervals.map { total(in: $0, subject: subject) } }
}\n'''
    if 'func totals(in intervals:' in (baseline / 'Sources/Services/StudyStore.swift').read_text():
        adapter = ''
    (baseline / 'Tests/PerformanceRegressionTests.swift').write_text(harness + adapter)
    for name, package in [('before', baseline), ('after', root)]:
        test(package, f'{name}-build.log')
    results = {'before': [], 'after': []}
    for run in range(1, args.runs + 1):
        for name, package in [('before', baseline), ('after', root)]:
            sample = output / f'{name}-{run}.json'
            test(package, f'{name}-{run}.log', ['--skip-build'], sample)
            results[name].append(json.loads(sample.read_text()))
    for key in ['hover_checksum', 'total_checksum', 'month_checksum', 'buckets_checksum']:
        if len({result[key] for samples in results.values() for result in samples}) != 1:
            raise RuntimeError(f'Workload result changed: {key}')
    metrics = {}
    for key in results['after'][0]:
        if key.endswith('_seconds'):
            before = statistics.median(result[key] for result in results['before'])
            after = statistics.median(result[key] for result in results['after'])
            metrics[key] = {'before_seconds': before, 'after_seconds': after,
                            'reduction_percent': (1 - after / before) * 100}
    summary = {'runs_per_version': args.runs, 'method': 'Alternating Release XCTest processes; median; geometry prepared once',
               'scope': 'Code microbenchmarks only. Not UI CPU, FPS, hitches, power or memory.',
               'checksums_equal': True, 'metrics': metrics}
    (output / 'summary.json').write_text(json.dumps(summary, indent=2) + '\n')
    print(json.dumps(summary, indent=2))
