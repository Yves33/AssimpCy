import re


def main(file_path):
    with open(file_path) as f:
        input_lines = f.readlines()

    pattern = r'#define\s+.*?"([^"]+)",?\s*0,\s*0\s*$|#define\s+.*?"([^"]+)"\s*$'

    results = []

    for line in input_lines:
        match = re.match(pattern, line)
        if match:
            mat_name = match.group(1) if match.group(1) else match.group(2)

            key_name = re.search(r'#define\s+(\w+)', line).group(1).replace('AI_MATKEY_', '').replace('_BASE',
                                                                                                      '').upper()
            key_name = key_name.replace("_", "", 1) if key_name.startswith('_') else key_name

            formatted_name = f"'{mat_name}': '{key_name}',"
            results.append(formatted_name)

    for result in results:
        print(result)


if __name__ == '__main__':
    import sys
    if len(sys.argv) < 2:
        hp = '/usr/local/include/assimp/material.h'
    else:
        hp = sys.argv[1]
    main(hp)