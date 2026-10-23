#!/usr/bin/env python3
"""Check app-owned translation keys and printf placeholders without touching user data."""
import json
import re
from pathlib import Path

root = Path(__file__).resolve().parent.parent
catalog = json.loads((root / 'Sources/ThemeResources/Translations.json').read_text())
errors = []
used = set()
literal = r'"((?:\\.|[^"\\])*)"'
for path in (root / 'Sources').rglob('*.swift'):
    source = path.read_text()
    for pattern in [r'L10n\.tr\(\s*' + literal, r'(?:singular|plural):\s*' + literal]:
        for match in re.finditer(pattern, source):
            key = json.loads('"' + match.group(1) + '"')
            used.add(key)
            if key not in catalog:
                errors.append(f'{path.relative_to(root)}: missing translation: {key!r}')
    for match in re.finditer(r'\b(?:Text|Label|Button|Toggle|StudyTextEntry|SettingRow|SettingsCard)\(\s*' + literal, source):
        key = match.group(1)
        if key in catalog and catalog[key] != key:
            errors.append(f'{path.relative_to(root)}: unlocalized UI literal: {key!r}')
for key, value in catalog.items():
    if not value.strip():
        errors.append(f'Empty English translation: {key!r}')
    placeholders = lambda s: re.findall(r'%(?:\d+\$)?[@d]', s)
    if placeholders(key) != placeholders(value):
        errors.append(f'Placeholder mismatch: {key!r} -> {value!r}')
if errors:
    raise SystemExit('\n'.join(errors))
print(f'OK: {len(catalog)} English entries; {len(used)} literal/plural keys checked. Dynamic metadata is covered by LocalizationTests.')
