from utils.parser.models import *
import os

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
        self.continue_id_stack = []

        if output and os.path.isfile(output):
            os.remove(output)
    
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
        
        mname = f'plex{self.get_unique_id()}'
        self.output(f'local {mname} = ')
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
        self.emit_memory_ref(assign.memory_ref)
        self.output('=')
        self.emit_expr(assign.value_expr)
        self.output('\n')
    
    def emit_array_assignment(self, arr_assign: ArrayAssignment):
        vname = f'assign_values{self.get_unique_id()}'
        self.output(f'local {vname} = ' + '{')
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
            iname = f'assign_i{self.get_unique_id()}'
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

        self.output(call.name)
        self.output(f'({",".join([Emitter().emit_expr(a).output_buffer for a in call.args])})\n')
    
    def emit_read(self, read: ReadStatement):
        vname = f'read_values{self.get_unique_id()}'
        self.output(f'local {vname}=' + '{')
        def outf(f):
            units = f.units or 1
            type = f.type or 'A5'
            if units == 1:
                return f'fortran_read("{type}", {units})'
            else:
                return f'table.unpack(fortran_read("{type}", {units}))'
        self.output(','.join([outf(f) for f in read.formats]))
        self.output('}\n')
        iname = f'write_i{self.get_unique_id()}'
        self.output(f'local {iname}=1\n')

        for mem_ref in read.memory_refs:
            if (
                isinstance(mem_ref, VariableRef)
                or isinstance(mem_ref, ArrayRef)
            ):
                self.emit_memory_ref(mem_ref)
                self.output(f'={vname}[{iname}]\n')
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
            self.output(',1 do\nfortran_write(')
            self.emit_memory_ref(array_ref_range.array_loc_ref)
            self.output(f')\n')
            self.output('end\n')
            return

        insert_idx = 0
        for f in write.formats:
            if isinstance(f, str):
                if f == '\n':
                    self.output(f'fortran_write("\\n")\n')
                else:
                    self.output(f'fortran_write({Emitter().emit_expr(f).output_buffer})\n')
                continue
            if isinstance(f, FormatPattern):
                mem_ref = write.value_list[insert_idx]
                if (
                    isinstance(mem_ref, VariableRef)
                    or isinstance(mem_ref, ArrayRef)
                ):
                    insert_idx += 1
                    self.output('fortran_write(')
                    self.emit_memory_ref(mem_ref)
                    self.output(f')\n')
                    continue
                
                self.error(f'Reference not supported')
        return

    def emit_subroutine(self, fn: Subroutine):
        self.output(f'function {fn.name}({",".join(fn.params)})\n')
        for body_stmt in fn.body_stmts:
            self.emit_statement(body_stmt)
        self.output('end\n')
        pass
    
    def emit_array_def(self, array_def: ArrayDef):
        self.output(f'{"" if array_def.name in self.global_vars else "local "}{array_def.name}' + ' = {}\n')

    def emit_arithmetic_if(self, if_stmt: ArithmeticIfStatement):
        self.output('if (')
        self.emit_expr(if_stmt.cond)
        self.output(f'<0) then\ngoto l{str(if_stmt.neg_stmt_id).zfill(5)}\n')
        self.output('elseif (')
        self.emit_expr(if_stmt.cond)
        self.output(f'==0) then\ngoto l{str(if_stmt.zero_stmt_id).zfill(5)}\n')
        self.output(f'else\ngoto l{str(if_stmt.pos_stmt_id).zfill(5)}\nend\n')

    def emit_statement(self, stmt: Statement):
        if stmt.id is not None:
            self.output(f'::l{str(stmt.id).zfill(5)}::\n')
        
        for n in stmt.nodes:
            if (
                isinstance(n, Implicit)
                or isinstance(n, EnableRand)
            ): continue
            if isinstance(n, GlobalVarDef): self.global_vars.append(n.name); continue
            if isinstance(n, ArrayDef): self.emit_array_def(n); continue
            if isinstance(n, ReturnSubroutine): self.output('return\n'); continue
            if isinstance(n, LogicalIfStatement): self.emit_logical_if_stmt(n); continue
            if isinstance(n, Goto): self.emit_goto(n); continue
            if isinstance(n, Assignment): self.emit_assignment(n); continue
            if isinstance(n, ArrayAssignment): self.emit_array_assignment(n); continue
            if isinstance(n, ForLoop): self.emit_for_loop(n); continue
            if isinstance(n, CallSubroutine): self.emit_call(n); continue
            if isinstance(n, ReadStatement): self.emit_read(n); continue
            if isinstance(n, FormatPattern): continue
            if isinstance(n, Continue): self.output(f'goto c{str(self.continue_id_stack[-1]).zfill(5)}\n'); continue
            if isinstance(n, Stop) or isinstance(n, ExitProgram): self.output('stop()\n'); continue
            if isinstance(n, Pause): self.output(f'pause("{n.msg}")\n'); continue
            if isinstance(n, TypeStatement): self.emit_write(n); continue
            if isinstance(n, Subroutine): self.emit_subroutine(n); continue
            if isinstance(n, Accept): self.output('read_key()'); continue
            if isinstance(n, ArithmeticIfStatement): self.emit_arithmetic_if(n); continue
            
            self.error(f'Node type "{getattr(n, "__name__", n.__class__.__name__)}" not supported')

    def emit_lua(self):
        def emit(node):
            if isinstance(node, Statement): return self.emit_statement(node)

            self.error(f'Node type "{getattr(node, "__name__", node.__class__.__name__)}" not supported')

        for node in self.ast:
            emit(node)
    
    def emit_file_hex(self, file_id):
        pass

def export_cartridge(ast, datfilename):
    emitter = Emitter(ast, [datfilename], output='cca.lua')
    lua = emitter.emit_lua()
    gfx_hex = emitter.emit_file_hex(1)
    pass