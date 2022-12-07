def get_num_symbols(filename):
    symbols = []
    with open(filename, 'r') as file:
        while 1:
            char = file.read(1)
            if not char:
                break
            if char not in symbols:
                symbols.append(char)
    return len(symbols)