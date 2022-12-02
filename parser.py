import re
from typing import List


OPERATORS = ['(', ')', ',', '"', "'", '-', '.', '/', '=', '+', '?', '*', '!']
KEYWORDS = ['IMPLICIT', 'INTEGER', 'REAL', 'COMMON', 'DIMENSION']

class Token:
    def __init__(self, line_num, col_num, chars):
        self.line_num = line_num
        self.col_num = col_num
        self.chars = chars

class EndOfLine(Token): pass

class Operator(Token): pass

class Keyword(Token): pass

class Identifier(Token): pass

class IntegerConstant(Token): pass

class FloatConstant(Token): pass

class OctalConstant(Token): pass

class Statement:

    def __init__(self, line_num, id, data):
        self.line_num = line_num
        self.id = id
        self.data = data
    
    def tokenize(self):
        tokens = []

        def error(char_idx, msg):
            raise Exception(f'Ln {self.line_num}, Col {char_idx + 1}: {msg}')

        char_idx = -1
        while char_idx < len(self.data) - 1:
            char_idx += 1
            token = self.data[char_idx]

            if token == ' ':
                token = ''
                continue

            if token == '"':
                while char_idx < len(self.data) - 1:
                    char_idx += 1
                    char = self.data[char_idx]
                    if not str.isnumeric(char):
                        char_idx -= 1
                        break
                    token += char
                if not re.match(r'"[0-7]+', token):
                    error(char_idx, f'Invalid octal constant {token}')

                tokens.append(OctalConstant(self.line_num, char_idx + 1, token))
                continue

            if token in OPERATORS:
                tokens.append(Operator(self.line_num, char_idx + 1, token))
                continue

            if str.isnumeric(token):
                while char_idx < len(self.data) - 1:
                    char_idx += 1
                    char = self.data[char_idx]
                    if not str.isnumeric(char) and char != '.':
                        char_idx -= 1
                        break
                    token += char
                if not re.match(r'\d+(\.\d+)?', token):
                    error(char_idx, f'Invalid numeric constant {token}')

                if '.' in token:
                    tokens.append(FloatConstant(self.line_num, char_idx + 1, token))
                else:
                    tokens.append(IntegerConstant(self.line_num, char_idx + 1, token))
                continue

            if str.isalpha(token):
                while char_idx < len(self.data) - 1:
                    char_idx += 1
                    char = self.data[char_idx]
                    if not str.isalnum(char):
                        char_idx -= 1
                        break
                    token += char
                
                if token in KEYWORDS:
                    tokens.append(Keyword(self.line_num, char_idx + 1, token))
                else:
                    tokens.append(Identifier(self.line_num, char_idx + 1, token))
                
                continue
        
            error(char_idx, f'Unexpected token {token}')
        
        tokens.append(EndOfLine(self.line_num, len(self.data), ''))

        return tokens

def read_lines(filename):
    with open(filename) as f:
        return [l.strip('\n\r') for l in f]

def tokenize(filename):

    lines = read_lines(filename)

    stmts = []

    # Flatten continuous lines
    line_idx = -1
    start_line_num = None
    prev_stmt_data = ''
    stmt_id = None
    stmt_data = ''
    prev_stmt_id = None
    try:
        while line_idx < len(lines) - 1:
            line_idx += 1

            prev_stmt_id = stmt_id
            current_line = lines[line_idx]
            
            if not current_line or current_line.startswith('C'): continue

            if '\t' not in current_line:
                raise Exception('Missing tab, identification column could not be identified')
            else:
                # Statement ID & Data
                [stmt_id, stmt_data] = f' {current_line}'.split('\t')
                try:
                    stmt_id = int(stmt_id)
                except:
                    stmt_id = None
            
            # Line continuation
            if (
                not prev_stmt_data
                or prev_stmt_id and prev_stmt_id == stmt_id and stmt_data[0] not in ('0', ' ')
            ):
                prev_stmt_data += stmt_data
                continue
            if not stmt_id and stmt_data[0] in (str(n) for n in range(10)):
                prev_stmt_data += re.match(r'^\d+(.+)$', stmt_data).group(1).strip()
                continue

            stmts.append(Statement(start_line_num, prev_stmt_id, prev_stmt_data))
            prev_stmt_id = stmt_id
            prev_stmt_data = stmt_data
            start_line_num = start_line_num = line_idx + 1
    except Exception as e:
        raise Exception(f'Ln {line_idx + 1}: {e}')
    
    return [
        t for tokens in [stmt.tokenize() for stmt in stmts]
        for t in tokens
    ]

class SyntacticAnalyzer:
    def __init__(self, tokens: List[Token]):
        self.tokens = tokens
        self.cursor = 0
    
    def error(self, token: Token, msg):
        raise Exception(f'Ln {token.line_num}, Col {token.col_num}: {msg}')

    def consume(self, expect_chars=None, expect_type: type=None):
        token = self.tokens[self.cursor]

        if expect_chars and token.chars != expect_chars:
            self.error(token, f'Expected {expect_chars}')

        if expect_type and not isinstance(token, expect_type):
            self.error(token, f'Expected {expect_type.__name__}')

        self.cursor += 1
        return token
    
    def lookahead(self, offset=0):
        return self.tokens[self.cursor + offset]

class Program:
    def __init__(self, ):
        pass

class Implicit:
    def __init__(self, datatype, pattern):
        self.datatype = datatype
        self.pattern = pattern

class EnableRand: pass

class GlobalVarDef:
    def __init__(self, name):
        self.name = name

class LocalVarDef:
    def __init__(self, name):
        self.name = name

class ArrayDef:
    def __init__(self, name, dims):
        self.name = name
        self.dims = dims

def build_ast(tokens: List[Token]):

    nodes = []

    sa = SyntacticAnalyzer(tokens)
    while sa.cursor < len(tokens):
        token = sa.consume()

        if isinstance(token, Keyword):
            if token.chars == 'IMPLICIT':
                datatype = sa.consume(expect_chars='INTEGER').chars
                sa.consume(expect_chars='(')
                pattern = sa.consume(expect_chars='A').chars
                pattern += sa.consume(expect_chars='-').chars
                pattern += sa.consume(expect_chars='Z').chars
                sa.consume(expect_chars=')')
                nodes.append(Implicit(datatype, pattern))
                sa.consume(expect_type=EndOfLine)
                continue
            if token.chars == 'REAL':
                sa.consume(expect_chars='RAN')
                nodes.append(EnableRand())
                sa.consume(expect_type=EndOfLine)
                continue
            if token.chars == 'COMMON':
                varname = sa.consume(expect_type=Identifier).chars
                nodes.append(GlobalVarDef(varname))
                while sa.lookahead().chars == ',':
                    sa.consume(expect_chars=',')
                    varname = sa.consume(expect_type=Identifier).chars
                    nodes.append(GlobalVarDef(varname))
                sa.consume(expect_type=EndOfLine)
                continue
            if token.chars == 'DIMENSION':
                varname = sa.consume(expect_type=Identifier).chars
                sa.consume(expect_chars='(')
                dims = []
                dim = sa.consume(expect_type=IntegerConstant).chars
                dims.append(int(dim))
                while sa.lookahead().chars == ',':
                    sa.consume(expect_chars=',')
                    dim = sa.consume(expect_type=IntegerConstant).chars
                    dims.append(int(dim))
                sa.consume(expect_chars=')')
                nodes.append(ArrayDef(varname, dims))
                while sa.lookahead().chars == ',':
                    sa.consume(expect_chars=',')
                    varname = sa.consume(expect_type=Identifier).chars
                    sa.consume(expect_chars='(')
                    dims = []
                    dim = sa.consume(expect_type=IntegerConstant).chars
                    dims.append(int(dim))
                    while sa.lookahead().chars == ',':
                        sa.consume(expect_chars=',')
                        dim = sa.consume(expect_type=IntegerConstant).chars
                        dims.append(int(dim))
                    sa.consume(expect_chars=')')
                    nodes.append(ArrayDef(varname, dims))
                sa.consume(expect_type=EndOfLine)
                continue

        sa.error(token, f'Invalid syntax {token.chars}')

def main():
    
    tokens = tokenize('cca.f')
    ast = build_ast(tokens)
    pass

if __name__ == "__main__":
    main()

# Things to implement:
# 