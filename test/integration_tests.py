import subprocess

targets_to_test = [
  {'target': 'examples:good-bugs'},
  {'target': 'examples:bad-bugs', 'expected_to_fail': True},
  {'target': 'examples:bad-bugs-high', 'expected_to_fail': False},
  {'target': 'examples:bad-bugs-excluded', 'expected_to_fail': False},
]

cmd = 'bazel test {target}'

failures = []

for target_to_test in targets_to_test:
  process = subprocess.Popen(cmd.format(**target_to_test), shell=True)
  process.wait()
  target_actually_failed = process.returncode != 0
  target_expected_to_fail = target_to_test.get('expected_to_fail', False)
  if target_actually_failed != target_expected_to_fail:
    if target_actually_failed:
      failures.append(target_to_test['target'] + ' expected to succeed!')
    else:
      failures.append(target_to_test['target'] + ' expected to fail!')

if len(failures) > 0:
  print('****** FAILURES ******')
  print('\n'.join(failures))
  exit(3)

print('All integration tests passed!')
