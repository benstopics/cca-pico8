from .parser import read_lines


def write_lines(filename, lines):
    with open(filename, "w") as f:
        f.writelines('\n'.join(lines) + '\n')

def format_file(filename):
    lines = read_lines(filename)
    new_lines = []
    for line in lines:
        new_line = ''
        chrs = ''
        for chr in line:
            if chr == '\t':
                spaces = 5 - (len(chrs) % 5)
                new_line += ' ' * spaces
                chrs = ''
                continue
            new_line += chr
            chrs += chr
        new_lines.append(new_line)
    
    write_lines('formatted-' + filename, new_lines)

def columnize_tabs():
    format_file('cca.f')
    format_file('cca.dat')