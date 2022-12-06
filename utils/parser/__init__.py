import re
from typing import List
import inspect
from utils.parser.models import *


OPERATORS = ['(', ')', ',', '"', "'", '.', '=', '?', '!']
ARITHMETIC_OPERATORS = ['+', '-', '*', '/']
RELATIONAL_OPERATORS = ['EQ', 'NE', 'GT', 'LT', 'GE', 'LE']
LOGICAL_OPERATORS = ['AND', 'OR', 'NOT', 'EQV', 'NEQV', 'XOR']
KEYWORDS = [
    'IMPLICIT', 'INTEGER', 'REAL', 'COMMON', 'DIMENSION', 'IF', 'GOTO',
    'DATA', 'DO', 'CALL', 'FORMAT', 'READ', 'TYPE', 'CONTINUE', 'STOP',
    'PAUSE', 'GO', 'TO', 'RAN', 'MOD', 'END', 'SUBROUTINE', 'RETURN', 'ACCEPT'
]

class Token:
    def __init__(self, line_num: int, col_num: int, chars: str):
        self.line_num = line_num
        self.col_num = col_num
        self.chars = chars

class EndOfLine(Token): pass

class Operator(Token): pass

class ArithmeticOperator(Token): pass

class RelationalOperator(Token): pass

class LogicalOperator(Token): pass

class Keyword(Token): pass

class Identifier(Token): pass

class Constant(Token):
    def value(self):
        return self.chars

class StringConstant(Token): pass

class IntegerConstant(Token):
    def value(self):
        return int(self.chars)

class OctalConstant(Token):
    def value(self):
        return int(self.chars[1:], 8)

class RawStatement:

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
                if not re.match(r'^"[0-7]+$', token):
                    error(char_idx, f'Invalid octal constant {token}')

                tokens.append(OctalConstant(self.line_num, char_idx + 1, token))
                continue

            if token == "'":
                while char_idx < len(self.data) - 1:
                    char_idx += 1
                    char = self.data[char_idx]
                    if char == "'":
                        token += char
                        break
                    token += char
                if match := re.match(r"'([A-Z0-9 !\.\?]*)'", token):
                    tokens.append(StringConstant(self.line_num, char_idx + 1, match.group(1)))
                    continue
                else:
                    error(char_idx, f'Invalid string constant {token}')

            if str.isnumeric(token):
                while char_idx < len(self.data) - 1:
                    char_idx += 1
                    char = self.data[char_idx]
                    if not str.isnumeric(char):
                        char_idx -= 1
                        break
                    token += char
                
                tokens.append(IntegerConstant(self.line_num, char_idx + 1, token))
                continue

            if token in ARITHMETIC_OPERATORS:
                tokens.append(ArithmeticOperator(self.line_num, char_idx + 1, token))
                continue

            if token in OPERATORS:
                tokens.append(Operator(self.line_num, char_idx + 1, token))
                continue

            if str.isalpha(token):
                while char_idx < len(self.data) - 1:
                    char_idx += 1
                    char = self.data[char_idx]
                    if not str.isalnum(char):
                        char_idx -= 1
                        break
                    token += char
                
                if token in RELATIONAL_OPERATORS:
                    tokens.append(RelationalOperator(self.line_num, char_idx + 1, token))
                    continue

                if token in LOGICAL_OPERATORS:
                    tokens.append(LogicalOperator(self.line_num, char_idx + 1, token))
                    continue

                if token in KEYWORDS:
                    tokens.append(Keyword(self.line_num, char_idx + 1, token))
                    continue
                else:
                    tokens.append(Identifier(self.line_num, char_idx + 1, token))
                    continue
        
            error(char_idx, f'Unexpected token {token}')
        
        tokens.append(EndOfLine(self.line_num, len(self.data), ''))

        return tokens

def read_lines(filename):
    with open(filename) as f:
        return [l.strip('\n\r') for l in f]

def get_raw_statements(filename):

    lines = read_lines(filename)

    stmts: List[RawStatement] = []

    # Flatten continuous lines
    line_idx = -1
    start_line_num = None
    prev_stmt_data = ''
    stmt_id = None
    stmt_data = ''
    prev_stmt_id = None
    try:
        while line_idx < len(lines):
            line_idx += 1

            if line_idx < len(lines):
                current_line = lines[line_idx]
                
                if not current_line or current_line.startswith('C'): continue

                if len(current_line) < 5:
                    raise Exception('Identification column could not be identified, too few columns')
                else:
                    # Statement ID & Data
                    stmt_id = current_line[:5]
                    try:
                        stmt_id = int(stmt_id)
                    except:
                        stmt_id = None
                    stmt_data = current_line[5:]
                
                # Line continuation
                if (
                    not prev_stmt_data
                    or prev_stmt_id and prev_stmt_id == stmt_id and stmt_data[0] not in ('0', ' ')
                ):
                    prev_stmt_data += stmt_data
                    continue
                if not stmt_id and stmt_data[0] in (str(n) for n in range(10)):
                    prev_stmt_data += re.match(r'^\d+ (.+)$', stmt_data).group(1)
                    continue

            stmts.append(RawStatement(start_line_num, prev_stmt_id, prev_stmt_data))
            prev_stmt_id = stmt_id
            prev_stmt_data = stmt_data
            start_line_num = start_line_num = line_idx + 1
    except Exception as e:
        raise Exception(f'Ln {line_idx + 1}: {e}')
    
    return stmts


class SyntacticAnalyzer:
    def __init__(self, stmts: List[RawStatement]):
        self.raw_stmts = stmts
        self.tokens: List[Token] = None
        self.token_cursor = 0
        self.stmt_cursor = -1
    
    def error(self, token: Token, msg):
        raise Exception(f'Ln {token.line_num}, Col {token.col_num}: {msg}')

    def consume(self, expect=None):
        token = self.tokens[self.token_cursor]

        if expect:
            if isinstance(expect, str) and token.chars != expect:
                self.error(token, f'Expected {expect}')
            elif inspect.isclass(expect) and not isinstance(token, expect):
                self.error(token, f'Expected {expect.__name__}')

        self.token_cursor += 1
        return token.chars
    
    def next_statement(self):
        self.stmt_cursor += 1

        if self.stmt_cursor >= len(self.raw_stmts): return

        stmt = self.raw_stmts[self.stmt_cursor]
        self.tokens = stmt.tokenize()
        self.token_cursor = 0

        return stmt
    
    def lookahead(self, offset=0):
        return self.tokens[self.token_cursor + offset]
    
    def get_implicit(self):
        self.consume('IMPLICIT')
        datatype = self.consume('INTEGER')
        self.consume('(')
        pattern = self.consume('A')
        pattern += self.consume('-')
        pattern += self.consume('Z')
        self.consume(')')
        return Implicit(datatype, pattern)
    
    def get_real_ran(self):
        self.consume('REAL')
        self.consume('RAN')
        return EnableRand()
    
    def comma_list(self, add_item):
        items = []
        items.append(add_item())
        while self.lookahead().chars == ',':
            self.consume(',')
            items.append(add_item())
        return items
    
    def get_common(self):
        self.consume('COMMON')
        def get_global_var_def():
            varname = self.consume(Identifier)
            return GlobalVarDef(varname)
        return self.comma_list(get_global_var_def)
    
    def get_dimension(self):
        self.consume('DIMENSION')
        def get_array_def():
            varname = self.consume(Identifier)
            self.consume('(')
            dims = self.comma_list(lambda: self.get_arithmetic_expr())
            self.consume(')')
            return ArrayDef(varname, dims)
        return self.comma_list(get_array_def)
    
    def get_numeric_const(self):
        val = None

        if isinstance(self.lookahead(), IntegerConstant):
            val = self.lookahead().value()
            self.consume()

            if (
                self.lookahead().chars == '.'
                and isinstance(self.lookahead(1), IntegerConstant)
            ):
                self.consume('.')
                val = float(f'{str(val)}.{self.consume(IntegerConstant)}')
            
            return val
        
        if isinstance(self.lookahead(), OctalConstant):
            val = self.lookahead().value()
            self.consume()

        if val is None:
            self.error(self.lookahead(), 'Invalid numeric constant')
        
        return val
    
    def get_integer_const(self):
        lookahead = self.lookahead()

        if (
            isinstance(lookahead, IntegerConstant)
            or isinstance(lookahead, OctalConstant)
        ):
            val = lookahead.value()
            self.consume()
            return val
    
    def get_value_expr(self):
        if self.lookahead().chars == '(':
            self.consume('(')
            expr = self.get_arithmetic_expr()
            self.consume(')')
            return expr
        
        negate = False
        if self.lookahead().chars == '-':
            self.consume('-')
            negate = True

        expr = None
        if isinstance(self.lookahead(), Identifier):
            expr = self.get_memory_ref()
        elif self.lookahead().chars == 'MOD':
            self.consume('MOD')
            self.consume('(')
            quotient = self.get_value_expr()
            self.consume(',')
            divisor = self.get_value_expr()
            self.consume(')')
            expr = Modulo(quotient, divisor)
        elif (
            isinstance(self.lookahead(), IntegerConstant)
            or isinstance(self.lookahead(), OctalConstant)
        ):
            expr = self.get_numeric_const()
        elif isinstance(self.lookahead(), StringConstant):
            expr = self.consume(StringConstant)
        elif self.lookahead().chars == 'RAN':
            expr = self.get_rand()
        
        if expr is None:
            self.error(self.lookahead(), f'Invalid value expression {self.lookahead().chars}')
        
        if negate:
            return NegateExpr(expr)
        
        return expr
    
    def get_arithmetic_expr_prec2(self, invalid_ops=[]):
        
        expr = self.get_value_expr()
        while (
            self.lookahead().chars in ['*', '/']
            and self.lookahead().chars not in invalid_ops
        ):
            op = self.consume(ArithmeticOperator)
            rterm = self.get_value_expr()
            expr = ArithmeticExpr(expr, op, rterm)
        
        return expr
    
    def get_arithmetic_expr(self, invalid_ops=[]):
        
        expr = self.get_arithmetic_expr_prec2(invalid_ops=invalid_ops)
        while (
            self.lookahead().chars in ['+', '-']
            and self.lookahead().chars not in invalid_ops
        ):
            op = self.consume(ArithmeticOperator)
            rterm = self.get_arithmetic_expr_prec2(invalid_ops=invalid_ops)
            expr = ArithmeticExpr(expr, op, rterm)
        
        return expr
    
    def get_relational_expr(self):
        if self.lookahead().chars == '(':
            self.consume('(')
            expr = self.get_relational_expr()
            self.consume(')')
            return expr
        else:
            expr = self.get_arithmetic_expr()
        
        while (
            self.lookahead().chars == '.'
            and isinstance(self.lookahead(1), RelationalOperator)
        ):
            self.consume('.')
            op = self.consume(RelationalOperator)
            self.consume('.')
            rterm = self.get_arithmetic_expr()
            expr = RelationalExpr(expr, op, rterm)
        
        return expr
    
    def get_logical_expr(self):
        if self.lookahead().chars == '(':
            self.consume('(')
            expr = self.get_logical_expr()
            self.consume(')')
        else:
            expr = self.get_relational_expr()

        while (
            self.lookahead().chars == '.'
            or isinstance(self.lookahead(), ArithmeticOperator)
        ):
            if self.lookahead().chars == '.':
                self.consume('.')
                if isinstance(self.lookahead(), LogicalOperator):
                    op = self.consume(LogicalOperator)
                    self.consume('.')
                    rterm = self.get_logical_expr()
                    expr = LogicalExpr(expr, op, rterm)
                elif isinstance(self.lookahead(), RelationalOperator):
                    op = self.consume(RelationalOperator)
                    self.consume('.')
                    rterm = self.get_logical_expr()
                    expr = RelationalExpr(expr, op, rterm)
                else:
                    self.error(self.lookahead(), 'Expected logical or relational operator')
            elif isinstance(self.lookahead(), ArithmeticOperator):
                op = self.consume(ArithmeticOperator)
                rterm = self.get_logical_expr()
                expr = ArithmeticExpr(expr, op, rterm)
            else:
                self.error(self.lookahead(), 'Expected arithmetic operator')
        
        return expr
    
    def get_if(self):
        self.consume('IF')
        self.consume('(')
        cond = self.get_logical_expr()
        self.consume(')')

        if isinstance(self.lookahead(), IntegerConstant):
            neg_stmt_id = self.consume(IntegerConstant)
            self.consume(',')
            zero_stmt_id = self.consume(IntegerConstant)
            self.consume(',')
            pos_stmt_id = self.consume(IntegerConstant)
            return ArithmeticIfStatement(cond, neg_stmt_id, zero_stmt_id, pos_stmt_id)

        stmt = self.get_statement()
        return LogicalIfStatement(cond, stmt)
    
    def get_goto(self):
        if self.lookahead().chars == 'GOTO':
            self.consume('GOTO')
        else:
            self.consume('GO')
            self.consume('TO')

        if self.lookahead().chars == '(':
            self.consume('(')
            stmt_ids = self.comma_list(lambda: self.consume(IntegerConstant))
            self.consume(')')
            multiplexer_expr = self.get_arithmetic_expr()
            return Goto(stmt_ids, multiplexer_expr)
        
        stmt_ids = [self.consume(IntegerConstant)]
        return Goto(stmt_ids)
    
    def get_array_loc_ref(self):
        name = self.consume(Identifier)
        self.consume('(')
        indexes = self.comma_list(lambda: self.get_arithmetic_expr())
        self.consume(')')
        return ArrayRef(name, indexes)

    def get_memory_ref(self):
        if (
            isinstance(self.lookahead(), Identifier)
            and self.lookahead(1).chars == '('
        ):
            return self.get_array_loc_ref()
        
        return VariableRef(self.consume(Identifier))
    
    def get_assignment(self):
        memory_ref = self.get_memory_ref()
        self.consume('=')
        value_expr = self.get_logical_expr()
        return Assignment(memory_ref, value_expr)
    
    def get_array_ref_range(self):
        self.consume('(')
        array_loc_ref = self.get_array_loc_ref()
        self.consume(',')
        counter_name = self.consume(Identifier)
        self.consume('=')
        start_expr = self.get_value_expr()
        self.consume(',')
        stop_expr = self.get_value_expr()
        self.consume(')')
        return ArrayRefRange(array_loc_ref, start_expr, stop_expr, counter_name)
    
    def get_data(self):
        self.consume('DATA')

        loc_ref = None
        name = None
        if self.lookahead().chars == '(':
            loc_ref = self.get_array_ref_range()
        elif isinstance(self.lookahead(), Identifier):
            name = self.consume(Identifier)
        else:
            self.error(self.lookahead(), 'Expected either array reference or array reference range')

        self.consume('/')
        values = self.comma_list(lambda: self.get_arithmetic_expr(invalid_ops=['/']))
        self.consume('/')

        if not loc_ref:
            loc_ref = VariableRef(name)

        return ArrayAssignment(loc_ref, values)
    
    def get_do_loop(self):
        self.consume('DO')
        stop_stmt_id = self.get_integer_const()
        counter_name = self.consume(Identifier)
        self.consume('=')
        start_expr = self.get_arithmetic_expr()
        self.consume(',')
        stop_expr = self.get_arithmetic_expr()

        # TODO - Support user defined increment

        body_stmts = []

        while self.raw_stmts[self.stmt_cursor].id != stop_stmt_id:
            self.consume(EndOfLine)
            body_stmts.append(self.get_statement(self.next_statement()))
            
        return ForLoop(counter_name, start_expr, stop_expr, body_stmts)
    
    def get_call(self):
        self.consume('CALL')
        name = self.consume(Identifier)
        self.consume('(')
        args = self.comma_list(lambda: self.get_logical_expr())
        self.consume(')')
        return CallSubroutine(name, args)
    
    def get_formats(self, stmt=None):
        if stmt:
            sa = SyntacticAnalyzer([stmt])
            sa.next_statement()
        else:
            sa = self
        
        sa.consume('FORMAT')
        sa.consume('(')
        def get_format():
            if isinstance(sa.lookahead(), StringConstant):
                text = sa.consume()
                if sa.lookahead().chars == '/':
                    sa.consume('/')
                    return text + '\n'
                return text
            
            if sa.lookahead().chars == '/':
                sa.consume('/')
                return '\n'
            
            pattern = ''
            if isinstance(sa.lookahead(), IntegerConstant):
                pattern += sa.consume(IntegerConstant)
            if isinstance(sa.lookahead(), Identifier):
                pattern += sa.consume(Identifier)
            if match := re.match(r'^(\d*)([A-Z]?\d*)$', pattern):
                unit, type = match.groups()
                return FormatPattern(
                    int(unit) if unit else None,
                    type or None
                )
            sa.error(sa.lookahead(), f'Invalid FORMAT pattern {pattern}')

        formats = sa.comma_list(get_format)
        sa.consume(')')
        return formats
    
    def find_stmt_by_id(self, id, start_idx=0):
        stmt = None
        for stmt_idx in range(len(self.raw_stmts)):
            if stmt_idx < start_idx: continue
            
            stmt = self.raw_stmts[stmt_idx]
            if stmt.id == id:
                stmt = stmt
                break
        else:
            self.error(self.lookahead(), f'Could not find statement ID {id}')

        return stmt
    
    def get_read(self):
        self.consume('READ')
        self.consume('(')
        device_id = self.get_integer_const()
        self.consume(',')
        format_stmt_id = self.get_integer_const()
        self.consume(')')
        def get_mem_ref():
            if self.lookahead().chars == '(':
                return self.get_array_ref_range()
            return self.get_memory_ref()
        memory_refs = self.comma_list(get_mem_ref)

        formats = self.get_formats(self.find_stmt_by_id(int(format_stmt_id)))

        return ReadStatement(device_id, formats, memory_refs)
    
    def get_pause(self):
        self.consume('PAUSE')
        msg = self.consume(StringConstant)
        return Pause(msg)
    
    def get_rand(self):
        self.consume('RAN')
        self.consume('(')
        self.consume('QZ')
        self.consume(')')
        return RandExpr()

    def get_type(self):
        self.consume('TYPE')
        format_stmt_id = self.consume(IntegerConstant)

        value_list = []
        if self.lookahead().chars == ',':
            self.consume(',')
            def get_value():
                if self.lookahead().chars == '(':
                    return self.get_array_ref_range()
                return self.get_value_expr()
            value_list = self.comma_list(get_value)
        
        formats = self.get_formats(self.find_stmt_by_id(int(format_stmt_id)))

        return TypeStatement(formats, value_list)
    
    def get_subroutine(self):
        self.consume('SUBROUTINE')
        name = self.consume(Identifier)
        self.consume('(')
        params = self.comma_list(lambda: self.consume(Identifier))
        self.consume(')')

        body_stmts = []

        while self.raw_stmts[self.stmt_cursor + 1].tokenize()[0].chars != 'END':
            self.consume(EndOfLine)
            body_stmts.append(self.get_statement(self.next_statement(), subroutine=True))
        
        self.next_statement()

        self.consume('END')
        
        return Subroutine(name, params, body_stmts)
    
    def get_accept(self):
        self.consume('ACCEPT')
        format_stmt_id = self.get_integer_const()
        self.consume(',')
        array_ref_range = self.get_array_ref_range()
        formats = self.get_formats(self.find_stmt_by_id(int(format_stmt_id), start_idx=self.stmt_cursor))

        return Accept(formats, array_ref_range)

    def get_statement(self, stmt: RawStatement=None, subroutine=False):
        def get_nodes():
            if isinstance(self.lookahead(), Keyword):
                if self.lookahead().chars == 'IMPLICIT': return self.get_implicit()
                if self.lookahead().chars == 'REAL': return self.get_real_ran()
                if self.lookahead().chars == 'COMMON': return self.get_common()
                if self.lookahead().chars == 'DIMENSION': return self.get_dimension()
                if self.lookahead().chars == 'IF': return self.get_if()
                if (
                    self.lookahead().chars == 'GOTO'
                    or self.lookahead().chars == 'GO'
                ): return self.get_goto()
                if self.lookahead().chars == 'DATA': return self.get_data()
                if self.lookahead().chars == 'DO': return self.get_do_loop()
                if self.lookahead().chars == 'CALL': return self.get_call()
                if self.lookahead().chars == 'READ': return self.get_read()
                if self.lookahead().chars == 'FORMAT': self.get_formats(); return
                if self.lookahead().chars == 'CONTINUE': self.consume(); return Continue()
                if self.lookahead().chars == 'STOP': self.consume(); return Stop()
                if self.lookahead().chars == 'PAUSE': return self.get_pause()
                if self.lookahead().chars == 'TYPE': return self.get_type()
                if not subroutine and self.lookahead().chars == 'END':
                    self.consume(); return ExitProgram()
                if self.lookahead().chars == 'SUBROUTINE': return self.get_subroutine()
                if self.lookahead().chars == 'RETURN': self.consume(); return ReturnSubroutine()
                if self.lookahead().chars == 'ACCEPT': return self.get_accept()
            
            if isinstance(self.lookahead(), Identifier):
                return self.get_assignment()
            
            self.error(self.lookahead(), f'Invalid start of statement {self.lookahead().chars}')

        return Statement(getattr(stmt, 'id', None), get_nodes())
    
    def get_ast(self):
        syntax_nodes = []

        while self.stmt_cursor < len(self.raw_stmts) - 1:
            self.next_statement()
            syntax_nodes.append(self.get_statement(self.raw_stmts[self.stmt_cursor]))
            self.consume(EndOfLine)
        
        return syntax_nodes

def build_ast(filename):
    stmts = get_raw_statements(filename)
    ast = SyntacticAnalyzer(stmts).get_ast()
    return ast