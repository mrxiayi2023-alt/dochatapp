import os, glob

dart_files = sorted(glob.glob('lib/**/*.dart', recursive=True))
go_files = sorted(glob.glob('server/**/*.go', recursive=True))
all_files = dart_files + go_files

print(f'Dart files: {len(dart_files)}')
print(f'Go files: {len(go_files)}')
print(f'Total files: {len(all_files)}')
for f in all_files:
    print(f)
