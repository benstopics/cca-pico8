from utils.parser.models import *
import os

LOCAL_KEYWORD = 'local'

logical_ops = {
    'AND': '&',
    'OR': '|',
    'XOR': '~'
}

relational_ops = {
    'EQ': '==',
    'NE': '~=',
    'GT': '>',
    'LT': '<',
    'GE': '>=',
    'LE': '<='
}

class Emitter:
    def __init__(self, ast=None, read_fnames=None, output=None):
        self.ast = ast
        self.read_fnames = read_fnames
        self.output_fname = output
        self.output_buffer = ''
        self.unique_id = 0
        self.global_vars = []
        self.symbol_stack = [[]]
        self.continue_id_stack = []
        self.subroutine = False
        self.subroutine_args = []

        if output and os.path.isfile(output):
            os.remove(output)
    
    def symbol_known(self, symbol):
        for scope in self.symbol_stack:
            for s in scope:
                if s == symbol: return True
        
        return False
    
    def add_symbol(self, symbol):
        self.symbol_stack[-1].append(symbol)
    
    def get_unique_id(self):
        self.unique_id += 1
        return str(self.unique_id).zfill(5)
    
    def output(self, chrs):
        self.output_buffer += chrs
        if self.output_fname is not None:
            with open(self.output_fname, 'a') as f:
                f.write(chrs)
    
    def error(self, msg):
        raise Exception(f'{msg} ... {self.output_buffer[20:]}')
    
    def emit_expr(self, expr):
        if isinstance(expr, LogicalExpr):
            self.output('(')
            self.emit_expr(expr.lterm)
            self.output(logical_ops[expr.op])
            self.emit_expr(expr.rterm)
            self.output(')')
            return self
        if isinstance(expr, RelationalExpr):
            self.output('(')
            self.emit_expr(expr.lterm)
            self.output(relational_ops[expr.op])
            self.emit_expr(expr.rterm)
            self.output(')')
            return self
        if isinstance(expr, ArithmeticExpr):
            self.output('(')
            self.emit_expr(expr.lterm)
            self.output(expr.op)
            self.emit_expr(expr.rterm)
            self.output(')')
            return self
        if isinstance(expr, Modulo):
            self.output('(')
            self.emit_expr(expr.quotient)
            self.output('%')
            self.emit_expr(expr.divisor)
            self.output(')')
            return self
        if isinstance(expr, NegateExpr):
            self.output('-')
            self.emit_expr(expr.expr)
            return self
        if (
            isinstance(expr, VariableRef)
            or isinstance(expr, ArrayRef)
        ):
            self.emit_memory_ref(expr)
            return self
        if (
            isinstance(expr, int)
            or isinstance(expr, float)
        ):
            self.output(str(expr))
            return self
        if isinstance(expr, str):
            s = expr.replace("\n", "\\n")
            self.output(f'"{s}"')
            return self
        if isinstance(expr, RandExpr):
            self.output('math.random()')
            return self
        
        self.error(f'Invalid expression')
    
    def emit_logical_if_stmt(self, if_stmt: LogicalIfStatement):
        self.output('if (')
        self.emit_expr(if_stmt.cond)
        self.output(') then\n')
        self.emit_statement(if_stmt.stmt)
        self.output('end\n')
    
    def emit_goto(self, goto: Goto):
        if len(goto.stmt_ids) == 1:
            self.output(f'goto l{str(goto.stmt_ids[0]).zfill(5)}\n')
            return
        
        mname = f'PLEX{self.get_unique_id()}'
        self.output(f'{mname} = ')
        self.emit_expr(goto.multiplexer_expr)
        self.output('\n')
        for i in range(len(goto.stmt_ids)):
            if i > 0:
                self.output('else')
            if i == len(goto.stmt_ids) - 1:
                self.output('\n')
            if i == 0 or i < len(goto.stmt_ids) - 1:
                self.output(f'if ({mname}=={i + 1}) then\n')
            self.output(f'goto l{str(goto.stmt_ids[i]).zfill(5)}\n')
            if i == len(goto.stmt_ids) - 1:
                self.output('end\n')
        pass
    
    def emit_memory_ref(self, mem_ref):
        if isinstance(mem_ref, VariableRef):
            self.output(mem_ref.name)
            return
        
        if isinstance(mem_ref, ArrayRef):
            self.output(mem_ref.name)
            self.output('[')
            self.output(']['.join([Emitter().emit_expr(i).output_buffer for i in mem_ref.indexes]))
            self.output(']')
            return
        
        raise Exception('Invalid reference')
    
    def emit_assignment(self, assign: Assignment):
        if self.subroutine and not self.symbol_known(assign.memory_ref.name):
            self.add_symbol(assign.memory_ref.name)
            self.output(f'{LOCAL_KEYWORD} ')
        self.emit_memory_ref(assign.memory_ref)
        self.output('=')
        self.emit_expr(assign.value_expr)
        self.output('\n')
    
    def emit_array_assignment(self, arr_assign: ArrayAssignment):
        vname = f'ASSIGN_VALUES{self.get_unique_id()}'
        self.output(f'{vname} = ' + '{')
        self.output(','.join([Emitter().emit_expr(v).output_buffer for v in arr_assign.value_exprs]))
        self.output('}\n')
        
        if isinstance(arr_assign.loc_ref, ArrayRefRange):
            self.output(f'for {arr_assign.loc_ref.counter_name}=')
            self.emit_expr(arr_assign.loc_ref.start_expr)
            self.output(',')
            self.emit_expr(arr_assign.loc_ref.stop_expr)
            self.output(',1 do\n')
            self.emit_memory_ref(arr_assign.loc_ref.array_loc_ref)
            self.output(f'={vname}[{arr_assign.loc_ref.counter_name}]\n')
            self.output('end\n')
            return
        
        if isinstance(arr_assign.loc_ref, VariableRef):
            iname = f'ASSIGN_I{self.get_unique_id()}'
            self.output(f'for {iname}=1,{len(arr_assign.value_exprs)},1 do\n')
            self.output(f'{arr_assign.loc_ref.name}={vname}[{iname}]\n')
            self.output('end\n')
            return
        
        self.error('Invalid array assignment reference')
    
    def emit_for_loop(self, forloop: ForLoop, continue_id=None):
        if continue_id is None:
            continue_id = self.get_unique_id()
            self.output(f'::c{continue_id.zfill(5)}::\n')
        self.continue_id_stack.append(continue_id)
        self.output(f'for {forloop.counter_name}=')
        self.emit_expr(forloop.start_expr)
        self.output(',')
        self.emit_expr(forloop.stop_expr)
        self.output(',1 do\n')
        for body_stmt in forloop.body_stmts:
            self.emit_statement(body_stmt)
        self.output('end\n')
        self.continue_id_stack.pop()
    
    def emit_call(self, call: CallSubroutine):
        if call.name == 'IFILE': return

        for arg in call.args:
            if isinstance(arg, VariableRef) and not self.symbol_known(arg.name):
                self.emit_assignment(Assignment(VariableRef(arg.name), 0))
        
        if call.args:
            self.output(', '.join([a.name if getattr(a, 'name', None) else '_' for a in call.args]))
            self.output(' = ')
            self.output('table.unpack(')
        self.output(call.name)
        self.output(f'({",".join([Emitter().emit_expr(a).output_buffer for a in call.args])})')
        if call.args:
            self.output(')')
        self.output('\n')
        
    def emit_read(self, read: ReadStatement):
        vname = f'READ_VALUES{self.get_unique_id()}'
        self.output(f'{vname}=' + '{')
        def outf(f):
            units = f.units or 1
            type = f.type or 'A5'
            if units == 1:
                return f'FORTRAN_READ("{type}", {units})'
            else:
                return f'table.unpack(FORTRAN_READ("{type}", {units}))'
        self.output(','.join([outf(f) for f in read.formats]))
        self.output('}\n')
        iname = f'WRITE_I{self.get_unique_id()}'
        self.output(f'{iname}=1\n')

        for mem_ref in read.memory_refs:
            if (
                isinstance(mem_ref, VariableRef)
                or isinstance(mem_ref, ArrayRef)
            ):
                self.emit_memory_ref(mem_ref)
                self.output(f'={vname}[{iname}]\n')
                self.output(f'{iname} = {iname} + 1\n')
                continue
            if isinstance(mem_ref, ArrayRefRange):
                self.output(f'for {mem_ref.counter_name}=')
                self.emit_expr(mem_ref.start_expr)
                self.output(',')
                self.emit_expr(mem_ref.stop_expr)
                self.output(',1 do\n')
                self.emit_memory_ref(mem_ref.array_loc_ref)
                self.output(f'={vname}[{mem_ref.counter_name} + {iname}]\n')
                self.output('end\n')
                self.output(f'{iname} = {iname} + 1\n')
                return
            
            self.error(f'Reference not supported')
    
    def emit_write(self, write: TypeStatement):
        if (
            len(write.value_list) == 1
            and isinstance(write.value_list[0], ArrayRefRange)
        ):
            array_ref_range: ArrayRefRange = write.value_list[0]
            self.output(f'for {array_ref_range.counter_name}=')
            self.emit_expr(array_ref_range.start_expr)
            self.output(',')
            self.emit_expr(array_ref_range.stop_expr)
            self.output(',1 do\nFORTRAN_WRITE(')
            self.emit_memory_ref(array_ref_range.array_loc_ref)
            self.output(f')\n')
            self.output('end\n')
            return

        insert_idx = 0
        for f in write.formats:
            if isinstance(f, str):
                if f == '\n':
                    self.output(f'FORTRAN_WRITE("\\n")\n')
                else:
                    self.output(f'FORTRAN_WRITE({Emitter().emit_expr(f).output_buffer})\n')
                continue
            if isinstance(f, FormatPattern):
                mem_ref = write.value_list[insert_idx]
                if (
                    isinstance(mem_ref, VariableRef)
                    or isinstance(mem_ref, ArrayRef)
                ):
                    insert_idx += 1
                    self.output('FORTRAN_WRITE(')
                    self.emit_memory_ref(mem_ref)
                    self.output(f')\n')
                    continue
                
                self.error(f'Reference not supported')
        return

    def emit_subroutine(self, fn: Subroutine):
        self.subroutine = True
        self.output(f'function {fn.name}({",".join(fn.params)})\n')
        self.subroutine_args = [*fn.params]
        self.symbol_stack.append(fn.params)
        for body_stmt in fn.body_stmts:
            self.emit_statement(body_stmt, ignore=[GlobalVarDef])
        self.output('end\n')
        self.subroutine = False
        self.symbol_stack.pop()
        pass
    
    def emit_array_def(self, array_def: ArrayDef):
        if self.subroutine:
            if array_def.name in self.global_vars: return
            else: self.output(f'{LOCAL_KEYWORD} ')
        
        self.output(f'{array_def.name} = ')

        if len(array_def.dims) == 1:
            self.output(f'INIT_ARR1({array_def.dims[0]})\n')
            return
            
        if len(array_def.dims) == 2:
            self.output(f'INIT_ARR2({array_def.dims[0]},{array_def.dims[1]})\n')
            return
        
        self.error('Number of dimensions not supported')

    def emit_arithmetic_if(self, if_stmt: ArithmeticIfStatement):
        self.output('if (')
        self.emit_expr(if_stmt.cond)
        self.output(f'<0) then\ngoto l{str(if_stmt.neg_stmt_id).zfill(5)}\n')
        self.output('elseif (')
        self.emit_expr(if_stmt.cond)
        self.output(f'==0) then\ngoto l{str(if_stmt.zero_stmt_id).zfill(5)}\n')
        self.output(f'else\ngoto l{str(if_stmt.pos_stmt_id).zfill(5)}\nend\n')

    def emit_statement(self, stmt: Statement, emit_only=None, ignore=None):
        
        nodes = [
            n for n in stmt.nodes
            if (
                (not ignore or n.__class__ not in ignore)
                and (not emit_only or n.__class__ in emit_only)
            )
        ]
        
        if nodes and stmt.id is not None:
            self.output(f'::l{str(stmt.id).zfill(5)}::\n')
        
        for n in nodes:
            if (
                isinstance(n, Implicit)
                or isinstance(n, EnableRand)
            ): continue
            if isinstance(n, GlobalVarDef):
                self.add_symbol(n.name)
                self.output(f'{n.name} = nil\n')
                continue
            if isinstance(n, ArrayDef): self.emit_array_def(n); continue
            if isinstance(n, ReturnSubroutine):
                self.output('if true then return ')
                if self.subroutine_args:
                    self.output('{' + ','.join(self.subroutine_args) + '} ')
                self.output('end\n')
                continue
            if isinstance(n, LogicalIfStatement): self.emit_logical_if_stmt(n); continue
            if isinstance(n, Goto): self.emit_goto(n); continue
            if isinstance(n, Assignment): self.emit_assignment(n); continue
            if isinstance(n, ArrayAssignment): self.emit_array_assignment(n); continue
            if isinstance(n, ForLoop): self.emit_for_loop(n); continue
            if isinstance(n, CallSubroutine): self.emit_call(n); continue
            if isinstance(n, ReadStatement): self.emit_read(n); continue
            if isinstance(n, FormatPattern): continue
            if isinstance(n, Continue): self.output(f'goto c{str(self.continue_id_stack[-1]).zfill(5)}\n'); continue
            if isinstance(n, Stop) or isinstance(n, ExitProgram): self.output('os.exit()\n'); continue
            if isinstance(n, Pause): self.output(f'PAUSE("{n.msg}")\n'); continue
            if isinstance(n, TypeStatement): self.emit_write(n); continue
            if isinstance(n, Subroutine): self.emit_subroutine(n); continue
            if isinstance(n, Accept): self.output('READ_KEY()\n'); continue
            if isinstance(n, ArithmeticIfStatement): self.emit_arithmetic_if(n); continue
            
            self.error(f'Node type "{getattr(n, "__name__", n.__class__.__name__)}" not supported')

    def emit_lua(self, header='', emit_only=None, ignore=None):
        def emit(node, emit_only=None, ignore=None):
            if isinstance(node, Statement):
                return self.emit_statement(node, emit_only=emit_only, ignore=ignore)

            self.error(f'Node type "{getattr(node, "__name__", node.__class__.__name__)}" not supported')

        self.output(header)
        
        # Emit functions second
        for node in self.ast:
            emit(node, emit_only=[GlobalVarDef])
        
        # Emit functions second
        for node in self.ast:
            emit(node, emit_only=[Subroutine])
        
        # Emit everything else third
        for node in self.ast:
            emit(node, ignore=[GlobalVarDef, Subroutine])
    
    def emit_file_hex(self, file_id):
        pass

def export_cartridge(ast, datfilename):
    emitter = Emitter(ast, [datfilename], output='cca.lua')
    header = """
function INIT_ARR1(size)
local a = {}
for i=1,size do
  a[i]=0
end
return a
end
function INIT_ARR2(size1, size2)
local a = {}
for i=1,size1 do
    a[i] = {}
    for j=1,size2 do
    a[i][j]=0
    end
end
return a
end
function READ_KEY()
end
function PAUSE(msg)
end
function FORTRAN_READ(type, units)
    return {}
end
function FORTRAN_WRITE(value)
end
"""
    lua = emitter.emit_lua(header)
    gfx_hex = emitter.emit_file_hex(1)
    pass