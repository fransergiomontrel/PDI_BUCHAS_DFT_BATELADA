#!/usr/bin/env python3
"""Check the completed Quartus build (internal timing and restored monitor pins)."""
import re
from pathlib import Path

root = Path(__file__).resolve().parents[1]
rpt = (root / 'output_files/sensor_buchas.sta.rpt').read_text()
pins = (root / 'output_files/sensor_buchas.pin').read_text()
match = re.search(r'; Worst-case Slack\s*;([^\n]+)', rpt)
assert match, 'Multicorner summary missing'
values = [float(x.strip()) for x in match[1].split(';') if x.strip()]
assert len(values) == 5, values
assert all(x >= 0 for x in values), f'Negative slack: {values}'
assert 'Timing requirements not met' not in rpt
assert re.search(r'; Unconstrained Clocks\s*; 0\s*; 0\s*;', rpt)
for pin, name in ((10, 'debug'), (12, 'debug_res'), (13, 'ncs')):
    assert re.search(rf'^{name}\s*:\s*{pin}\s*:\s*output\s*:', pins, re.M), (pin, name)
print('PASS: multicorner internal timing; all internal clocks constrained; pins 10/12/13 restored')
for kind, value in zip(('setup', 'hold', 'recovery', 'removal', 'minimum pulse width'), values):
    print(f'{kind}: {value:.3f} ns')
print('External I/O timing is outside this check, pending board specifications.')
