def extract_aiProcess_lines(file_path):
    ai_process_set = set()

    with open(file_path, 'r') as file:
        for line in file:
            nl = line.replace('#define', '').strip()
            if nl.startswith("aiProcess"):
                # Extract the part of the line up to the first space
                key = nl.split()[0]
                ai_process_set.add(key)

    return ai_process_set


def print_aligned_lines(lines):
    max_length = max(len(line.split('=')[0]) for line in lines)
    for line in lines:
        parts = line.split('=')
        key = parts[0]
        value = '='.join(parts[1:])
        print(f"{key:{max_length}} = {value}")


def main(file_p):
    result = sorted(extract_aiProcess_lines(file_p))

    with open('./../assimpcy/cPostProcess.pxd', 'w') as p_target:
        p_target.write('cdef extern from "postprocess.h" nogil:\n')
        define_idx = []
        for i, r in enumerate(result):
            if r.startswith('aiProcessPreset') or r == 'aiProcess_ConvertToLeftHanded':
                define_idx.append(i)
                p_target.write(f'    cdef unsigned int {r}\n')

        p_target.write(f'\n')
        p_target.write('    cdef enum aiPostProcessSteps:\n')

        for i, r in enumerate(result):
            if i in define_idx:
                continue
            p_target.write(f'        {r}\n')

    print('')
    print('class aiPostProcessSteps(Flag):')
    aligned = []
    for r in result:
        aligned.append(f"    {r} = cPostProcess.{r}")

    print_aligned_lines(aligned)

    print("\n    def __int__(self):")
    print("        return self.value")


if __name__ == '__main__':
    import sys

    if len(sys.argv) < 2:
        fp = '/usr/local/include/assimp/postprocess.h'
    else:
        fp = sys.argv[1]
    main(fp)
