from utils.parser import build_ast
from utils.pico8 import export_cartridge


def main():
    ast = build_ast('formatted-cca.f')
    export_cartridge(ast, 'formatted-cca.dat')

if __name__ == "__main__":
    main()