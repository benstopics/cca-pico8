from utils.parser.models import *
import os

LOCAL_KEYWORD = 'local'
PICO8 = True

logical_ops = {
    'AND': ' and ',
    'OR': ' or '
}

relational_ops = {
    'EQ': '==',
    'NE': '~=',
    'GT': '>',
    'LT': '<',
    'GE': '>=',
    'LE': '<='
}

arithmetic_fns = {
    '*': 'stringmul',
    '/': 'stringdiv',
    '+': 'stringadd',
    '-': 'stringsub',
    '%': 'stringmod',
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
            if getattr(expr, 'paren', False):
                self.output('(')
            self.emit_expr(expr.lterm)
            self.output(logical_ops[expr.op])
            self.emit_expr(expr.rterm)
            if getattr(expr, 'paren', False):
                self.output(')')
            return self
        if isinstance(expr, RelationalExpr):
            tonum = (
                (not isinstance(expr.lterm, str) and not isinstance(expr.rterm, str))
                and expr.op != 'EQ'
                and expr.op != 'NE'
            )
            if getattr(expr, 'paren', False):
                self.output('(')
            if tonum:
                self.output('tonum(')
            self.emit_expr(expr.lterm)
            if tonum:
                if PICO8:
                    self.output(', 2)')
                else:
                    self.output(')')
            self.output(relational_ops[expr.op])
            if tonum:
                self.output('tonum(')
            self.emit_expr(expr.rterm)
            if tonum:
                if PICO8:
                    self.output(', 2)')
                else:
                    self.output(')')
            if getattr(expr, 'paren', False):
                self.output(')')
            return self
        if isinstance(expr, ArithmeticExpr):
            self.output(arithmetic_fns[expr.op])
            self.output('(')
            self.emit_expr(expr.lterm)
            self.output(',')
            self.emit_expr(expr.rterm)
            self.output(')')
            return self
        if isinstance(expr, Modulo):
            self.output(arithmetic_fns['%'])
            self.output('(')
            self.emit_expr(expr.quotient)
            self.output(',')
            self.emit_expr(expr.divisor)
            self.output(')')
            return self
        if isinstance(expr, NegateExpr):
            self.output('stringneg')
            self.output('(')
            self.emit_expr(expr.expr)
            self.output(')')
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
            self.output(f'"{str(expr)}"')
            return self
        if isinstance(expr, str):
            s = expr.replace("\n", "\\n")
            self.output(f'"{s}"')
            return self
        if isinstance(expr, RandExpr):
            self.output('math.random()' if not PICO8 else 'rnd()')
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
            # if PICO8:
            #     self.output(f'printh("goto " .. {str(goto.stmt_ids[0]).zfill(5)})\n')
            # else:
            #     self.output(f'io.write("goto " .. {str(goto.stmt_ids[0]).zfill(5)} .. "\\n")\n')
            self.output(f'goto l{str(goto.stmt_ids[0]).zfill(5)}\n')
            return
        
        mname = f'PLEX{self.get_unique_id()}'
        self.output(f'{mname} = ')
        self.emit_expr(goto.multiplexer_expr)
        self.output('\n')
        for i in range(len(goto.stmt_ids)):
            if i > 0:
                self.output('else')
            self.output(f'if ({mname}=="{i + 1}") then\n')
            # if PICO8:
            #     self.output(f'printh("goto " .. {str(goto.stmt_ids[i]).zfill(5)})\n')
            # else:
            #     self.output(f'io.write("goto " .. {str(goto.stmt_ids[i]).zfill(5)} .. "\\n")\n')
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
            self.output('[tonum(')
            self.output(')][tonum('.join([Emitter().emit_expr(i).output_buffer for i in mem_ref.indexes]))
            self.output(')]')
            return
        
        raise Exception('Invalid reference')
    
    def emit_assignment(self, assign: Assignment):
        if not self.symbol_known(assign.memory_ref.name):
            self.add_symbol(assign.memory_ref.name)
            if self.subroutine:
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
            self.output(f'for {arr_assign.loc_ref.counter_name}=tonum(')
            self.emit_expr(arr_assign.loc_ref.start_expr)
            self.output('),tonum(')
            self.emit_expr(arr_assign.loc_ref.stop_expr)
            self.output(') do\n')
            self.emit_memory_ref(arr_assign.loc_ref.array_loc_ref)
            self.output(f'={vname}[{arr_assign.loc_ref.counter_name}]\n')
            self.output('end\n')
            return
        
        if isinstance(arr_assign.loc_ref, VariableRef):
            iname = f'ASSIGN_I{self.get_unique_id()}'
            self.output(f'for {iname}=1,{len(arr_assign.value_exprs)} do\n')
            self.output(f'{arr_assign.loc_ref.name}[{iname}]={vname}[{iname}]\n')
            self.output('end\n')
            return
        
        self.error('Invalid array assignment reference')
    
    def emit_for_loop(self, forloop: ForLoop, continue_id=None):
        if continue_id is None:
            continue_id = self.get_unique_id()
        self.continue_id_stack.append(continue_id)
        self.output(f'{forloop.counter_name}=stringsub(')
        self.emit_expr(forloop.start_expr)
        self.output(',"1")\n')
        forloop_id = self.get_unique_id()
        self.output(f'::c{continue_id.zfill(5)}::\n')
        self.output(f'{forloop.counter_name} = stringadd({forloop.counter_name},"1")\n')
        self.output(f'if tonum({forloop.counter_name}) > tonum(')
        self.emit_expr(forloop.stop_expr)
        self.output(f') then goto f{forloop_id.zfill(5)} end\n')
        for body_stmt in forloop.body_stmts:
            self.emit_statement(body_stmt)
        self.output(f'goto c{continue_id.zfill(5)}\n')
        self.output(f'::f{forloop_id.zfill(5)}::\n')
        self.continue_id_stack.pop()
    
    def emit_call(self, call: CallSubroutine):
        if call.name == 'IFILE': return

        for arg in call.args:
            if isinstance(arg, VariableRef) and not self.symbol_known(arg.name):
                self.emit_assignment(Assignment(VariableRef(arg.name), 0))
        
        if call.args:
            self.output(', '.join([a.name if getattr(a, 'name', None) else '_' for a in call.args]))
            self.output(' = ')
            self.output('unpack(')
        self.output(call.name)
        self.output(f'({",".join([Emitter().emit_expr(a).output_buffer for a in call.args])})')
        if call.args:
            self.output(')')
        self.output('\n')

    def emit_read(self, read: ReadStatement):
        vname = f'READ_VALUES{self.get_unique_id()}'
        types = ','.join([f'"{f.type}"' for f in read.formats])
        units = ','.join([f'{f.units or 1}' for f in read.formats])
        self.output(f'{vname}=FORTRAN_READ(' + '{' + types + '},{' + units + '})\n')
        iname = f'WRITE_I{self.get_unique_id()}'
        self.output(f'{iname}="1"\n')

        for mem_ref in read.memory_refs:
            if (
                isinstance(mem_ref, VariableRef)
                or isinstance(mem_ref, ArrayRef)
            ):
                self.emit_memory_ref(mem_ref)
                self.output(f'={vname}[tonum({iname})]\n')
                self.output(f'{iname} = stringadd({iname},"1")\n')
                continue
            if isinstance(mem_ref, ArrayRefRange):
                self.output(f'for {mem_ref.counter_name}=tonum(')
                self.emit_expr(mem_ref.start_expr)
                self.output('),tonum(')
                self.emit_expr(mem_ref.stop_expr)
                self.output(') do\n')
                self.output(f'if tonum({vname}[tonum({iname})]) == nil and #{vname}[tonum({iname})] == "0" then {vname}[tonum({iname})] = " " end\n')
                self.emit_memory_ref(mem_ref.array_loc_ref)
                self.output(f'={vname}[tonum({iname})]\n')
                self.output(f'{iname} = stringadd({iname},"1")\n')
                self.output('end\n')
                return
            
            self.error(f'Reference not supported')
    
    def emit_write(self, write: TypeStatement):
        if (
            len(write.value_list) == 1
            and isinstance(write.value_list[0], ArrayRefRange)
        ):
            array_ref_range: ArrayRefRange = write.value_list[0]
            self.output(f'for {array_ref_range.counter_name}=tonum(')
            self.emit_expr(array_ref_range.start_expr)
            self.output('),tonum(')
            self.emit_expr(array_ref_range.stop_expr)
            self.output(') do\nFORTRAN_WRITE(')
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
        if fn.name == 'SHIFT': return

        self.output(f'function {fn.name}({",".join(fn.params)})\n')

        if fn.name == 'GETIN':
            if not PICO8:
                self.output("""
    
    if #unit_test > 0 then
        input = unit_test[1]
        deli(unit_test, 1)
        FORTRAN_WRITE(input .. "\\n")
    else
        input = sub(io.read(), 1, 20)
    end
    input = upper(input)
    local words = {}
    for word in input:gmatch("%w+") do add(words, word) end
    local twow, firstw, secondw_ext, secondw
    if #words > 0 then
        firstw = sub(words[1], 1, 5)
        if #words > 1 then
            twow = "1"
            secondw = sub(words[2], 1, 5)
            secondw_ext = sub(words[2], 6, 20)
            if #secondw_ext == 0 then secondw_ext = ' ' end
        else
            twow = "0"
            secondw = ' '
            secondw_ext = ' '
        end
    end
    return {twow, firstw, secondw, secondw_ext}
end\n
""")
            else:
                self.output("""
    
-- Render screen
    DRAW_SCREEN()

    local input = ''
    if #unit_test > 0 then
        input = unit_test[1]
        deli(unit_test, 1)
        FORTRAN_WRITE(input .. "\\n")
    else
        kb_chars_alnum = "ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890"
        BACKSPACE_SCANCODE = 42
        SPACE_SCANCODE = 44
        ENTER_SCANCODE = 88

        t = ''
        key_states = {}
        enter_pressed = false
        while true do
            pressed_key = 0

            -- Update enter keypress
            local enter_was_pressed = enter_pressed
            local enter_pressed = stat(31) == "\\r"
            if enter_pressed and not enter_was_pressed then
                pressed_key = 88
            else
                -- Update alphanum pressed statuses
                for scancode = 4, 256, 1 do
                    local was_pressed = key_states[scancode]
                    local pressed = stat(28, scancode)
                    key_states[scancode] = pressed

                    -- if pressed then print(scancode, 1, 1, 11) end

                    -- Initial press only
                    if pressed and not was_pressed then
                        pressed_key = scancode
                        break
                    end
                end
            end

            -- Manage input line
            if pressed_key >= 4 and pressed_key <= 39 and #t < 20 then
                t = t .. sub(kb_chars_alnum, pressed_key - 3, pressed_key - 3)
            elseif pressed_key == SPACE_SCANCODE and sub(t, #t, #t) ~= " " then
                t = t .. " "
            elseif pressed_key == BACKSPACE_SCANCODE and #t > 0 then
                t = sub(t, 1, #t - 1)
            elseif pressed_key == ENTER_SCANCODE then
                break
            end

            -- Draw user input
            rectfill(0, 6 * (#SCREEN_TEXT), 127,6 * (#SCREEN_TEXT + 1), 0)
            local show_cursor = time() % 1 < 0.5
            local cursor = ""
            if show_cursor then cursor = "_" else show_cursor = " " end
            print(">" .. t .. cursor .. "                                      ", 0, 6 * (#SCREEN_TEXT), 11)
            flip()

            -- https://www.lexaloffle.com/bbs/?tid=41855
            poke(0x5f30, 1) -- prevents the p character or the enter key from calling the menu.
        end
        input = sub(t, 1, 20)
    end
    FORTRAN_WRITE(sub("\\n>" .. input .. "                                      ",1,21) .. "\\n\\n")
    --print(input)
    local words = split(input, " ", false)
    local twow, firstw, secondw_ext, secondw
    if #words > 0 then
        firstw = sub(words[1], 1, 5)
        if #words > 1 then
            twow = 1
            secondw = sub(words[2], 1, 5)
            secondw_ext = sub(words[2], 6, 20)
            if #secondw_ext == 0 then secondw_ext = ' ' end
        else
            twow = "0"
            secondw = ' '
            secondw_ext = ' '
        end
    end
    return { twow, firstw, secondw, secondw_ext }

end\n
""")
            return

        self.subroutine = True
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
                self.global_vars.append(n.name)
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
            if isinstance(n, Stop) or isinstance(n, ExitProgram): self.output('os.exit()\n' if not PICO8 else 'stop()\n'); continue
            if isinstance(n, Pause): self.output(f'PAUSE("{n.msg}")\n'); continue
            if isinstance(n, TypeStatement): self.emit_write(n); continue
            if isinstance(n, Subroutine): self.emit_subroutine(n); continue
            if isinstance(n, Accept): self.output(f'{n.array_ref_range.array_loc_ref.name} = READ_KEY()\n'); continue
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
    
def export_cartridge(ast, datfilename):
    emitter = Emitter(ast, [datfilename], output='cca' + ('.p8.lua' if PICO8 else '.lua'))
    header = ''
    unit_tests = """
run_tests = true
unit_test = {}
if run_tests then
    srand(12345)

    unit_test = {
        -- STARTING THE GAME
        'CONTINUE',
        'N',
        -- GETTING INTO THE CAVE
        'BUILDING',
        'TAKE KEYS',
        'TAKE LAMP',
        'EXIT',
        'S', 'SOUTH', 'DOWN',
        'OPEN GRATE',
        'DOWN',
        'WEST',
        'TAKE CAGE',
        'W',
        'LAMP ON',
        'TAKE ROD',
        'XYZZY',
        'XYZZY',
        'W',
        'DROP ROD',
        'W',
        'TAKE BIRD',
        'EAST',
        'TAKE ROD',
        'WEST',
        'WEST',
        'D',
        'D',
        -- LEVEL 1 - SNAKES AND PLUGHS
        'DROP BIRD',
        'DROP ROD',
        'TAKE BIRD',
        'TAKE ROD',
        'W', 'TAKE COINS',
        'BACK',
        'S', 'TAKE JEWELS',
        'BACK',
        'N', 'TAKE SILVER',
        'N', 'PLUGH',
        'DROP COINS',
        'DROP JEWELS',
        'DROP SILVER',
        'DROP KEYS',
        'PLUGH',
        'S', 'D', 'W', 'D',
        'W', 'SLAB', 'S', 'E',
    }
end
"""
    if PICO8:
        header = """
-- https://www.lexaloffle.com/bbs/?pid=101378
-- add 2 numeric strings
function stringadd(a, b)
    return tostr(tonum(a .. "", 2) + tonum(b .. "", 2), 2)
end
-- subtract 2 numeric strings
function stringsub(a, b)
    return tostr(tonum(a .. "", 2) - tonum(b .. "", 2), 2)
end
-- multiply 2 numeric strings
function stringmul(a, b)
    return tostr(tonum(a .. "", 2) * (tonum(b .. "", 2) << 16), 2)
end
-- divide 2 numeric strings
function stringdiv(a, b)
    return tostr(tonum(a .. "", 2) / (tonum(b .. "", 2) << 16), 2)
end
-- modulo 2 numeric strings
-- modulo 2 numeric strings
function stringmod(a, b)
    return stringsub(a,stringmul(b,stringdiv(a, b)))
end
-- negate numeric string
function stringneg(a)
    if sub(a,1,1) == "-" then return sub(a,2)
    else return "-" .. a end
end

-- https://www.lexaloffle.com/bbs/?pid=43636
-- converts anything to string, even nested tables
function tostring(any)
    if type(any)=="function" then 
        return "function" 
    end
    if any==nil then 
        return "nil" 
    end
    if type(any)=="string" then
        return any
    end
    if type(any)=="boolean" then
        if any then return "true" end
        return "false"
    end
    if type(any)=="table" then
        local str = "{ "
        for k,v in pairs(any) do
            str=str..tostring(k).."->"..tostring(v).." "
        end
        return str.."}"
    end
    if type(any)=="number" then
        return ""..any
    end
    return "unkown" -- should never show
end
cls()

poke(0x5f2d, 1) -- Enable keyboard/mouse

-- https://www.lexaloffle.com/bbs/?tid=41798
function cat(t)
    local s = ''
    for i = 1, #t, 1 do
        s = s .. t[i]
    end
    return s
end

local basedictcompress = {}
local basedictdecompress = {}
for i = 0, 255 do
    local ic, iic = chr(i), chr(i, 0)
    basedictcompress[ic] = iic
    basedictdecompress[iic] = ic
end

local function dictAddB(str, dict, a, b)
    if a >= 256 then
        a, b = 0, b + 1
        if b >= 256 then
            dict = {}
            b = 1
        end
    end
    dict[chr(a, b)] = str
    a = a + 1
    return dict, a, b
end

local function decompress(input)
    if type(input) ~= "string" then
        error("string expected, got " .. type(input))
    end

    if #input < 1 then
        error("invalid input - not a compressed string")
    end

    local control = sub(input, 1, 1)
    if control == "u" then
        return sub(input, 2)
    elseif control ~= "c" then
        error("invalid input - not a compressed string")
    end
    input = sub(input, 2)
    local len = #input

    if len < 2 then
        error("invalid input - not a compressed string")
    end

    local dict = {}
    local a, b = 0, 1

    local result = {}
    local n = 1
    local last = sub(input, 1, 2)
    result[n] = basedictdecompress[last] or dict[last]
    n = n + 1
    for i = 3, len, 2 do
        local code = sub(input, i, i + 1)
        local lastStr = basedictdecompress[last] or dict[last]
        if not lastStr then
            error("could not find last from dict. Invalid input?")
        end
        local toAdd = basedictdecompress[code] or dict[code]
        if toAdd then
            result[n] = toAdd
            n = n + 1
            dict, a, b = dictAddB(lastStr .. sub(toAdd, 1, 1), dict, a, b)
        else
            local tmp = lastStr .. sub(lastStr, 1, 1)
            result[n] = tmp
            n = n + 1
            dict, a, b = dictAddB(tmp, dict, a, b)
        end
        last = code
    end
    return cat(result)
end

-- https://stackoverflow.com/a/18694774
function utf8_from(t)
    local bytearr = {}
    for i = 1, #t, 1 do
        add(bytearr, chr(t[i]))
        --if i < 40 then print(chr(t[i]),1 + 4 * (i - 1),1) end
    end
    return cat(bytearr)
end

-- __gfx__ + __map__ --
READ_UTF8_DATA = {}
for i = 0, 0x2fff, 1 do
    add(READ_UTF8_DATA, peek(i))
end

-- __sfx__ --
for i = 0x3200, 0x3200 + 843 - 1, 1 do
    add(READ_UTF8_DATA, peek(i))
end
--print(tostr(#READ_UTF8_DATA),1,9)
COMPRESSED = utf8_from(READ_UTF8_DATA)
DECOMPRESSED = decompress(COMPRESSED)
--print(sub(DECOMPRESSED,#DECOMPRESSED - 20,#DECOMPRESSED),1,18)

READ_LINES = split(DECOMPRESSED, "|", false)

--cstore(0x3200, 0x0000, 4096)

function INIT_ARR1(size)
    local a = {}
    for i = 1, size do
        a[i] = "0"
    end
    return a
end

function INIT_ARR2(size1, size2)
    local a = {}
    for i = 1, size1 do
        a[i] = {}
        for j = 1, size2 do
            a[i][j] = "0"
        end
    end
    return a
end

READ_LINE_IDX = 1

function FORTRAN_READ(types, units)
    local line = READ_LINES[READ_LINE_IDX]
    local result = {}
    for i = 1, #types, 1 do
        local t = types[i]
        local u = units[i]
        for j = 1, u, 1 do
            if t == "G" then
                local v = tonum(sub(line, 1, 5))
                if v == nil or v == '' then
                    v = "0"
                else
                    v = tostr(v)
                end
                add(result, v)
                line = sub(line, 6, #line)
            elseif t == "A5" then
                local v = sub(line, 1, 5)
                if v == nil or v == '' then
                    v = ' '
                end
                add(result, v)
                line = sub(line, 6, #line)
            else
                error("Unsupported format type " .. t)
            end
        end
    end
    READ_LINE_IDX = READ_LINE_IDX + 1
    return result
end

SCREEN_TEXT = { '' }
MAX_SCREEN_WIDTH = 32
MAX_SCREEN_LINES = 20
function FORTRAN_WRITE(text)
    -- Add new text to buffer with wordwrap
    for c = 1, #text, 1 do
        if sub(text, c, c) == "\\n" then
            add(SCREEN_TEXT, '')
        else
            if #SCREEN_TEXT[#SCREEN_TEXT] == MAX_SCREEN_WIDTH then
                add(SCREEN_TEXT, '')
            end
            SCREEN_TEXT[#SCREEN_TEXT] = SCREEN_TEXT[#SCREEN_TEXT] .. sub(text, c, c)
        end

        while #SCREEN_TEXT > MAX_SCREEN_LINES do
            st = {}
            for r = 2, #SCREEN_TEXT, 1 do
                add(st, SCREEN_TEXT[r])
            end
            SCREEN_TEXT = st
        end
    end
end
function DRAW_SCREEN()
    -- Clear screen
    cls()

    -- Draw game text
    for r = 1, #SCREEN_TEXT, 1 do
        for c = 1, #SCREEN_TEXT[r], 1 do
            print(SCREEN_TEXT[r], 0, (r - 1) * 6, 11)
        end
    end
end

function PAUSE(msg)
    FORTRAN_WRITE(msg .. "\\n")
    DRAW_SCREEN()
    GETIN(_, _, _, _)
end
"""
        header += unit_tests
    else:
        header += """

srand = math.randomseed
unpack = table.unpack
sub = string.sub
add = table.insert
tonum = tonumber
tostr = tostring
deli = table.remove
upper = string.upper

-- add 2 numeric strings
function stringadd(a, b)
    return tostr(tonum(a .. "") + tonum(b .. ""))
end
-- subtract 2 numeric strings
function stringsub(a, b)
    return tostr(tonum(a .. "") - tonum(b .. ""))
end
-- multiply 2 numeric strings
function stringmul(a, b)
    return tostr(tonum(a .. "") * tonum(b .. ""))
end
-- divide 2 numeric strings
function stringdiv(a, b)
    return tostr(tonum(a .. "") // tonum(b .. ""))
end
-- modulo 2 numeric strings
function stringmod(a, b)
    return stringsub(a,stringmul(b,stringdiv(a, b)))
end
-- negate numeric string
function stringneg(a)
    if sub(a,1,1) == "-" then return sub(a,2)
    else return "-" .. a end
end
"""
        header += unit_tests
        header += """
-- http://lua-users.org/wiki/FileInputOutput

-- see if the file exists
function FILE_EXISTS(file)
    local f = io.open(file, "rb")
    if f then f:close() end
    return f ~= nil
end

-- get all lines from a file, returns an empty
-- list/table if the file does not exist
function LINES_FROM(file)
    if not FILE_EXISTS(file) then return {} end
    local lines = {}
    for line in io.lines(file) do
        lines[#lines + 1] = line
    end
    return lines
end

-- tests the functions above
READ_LINES = LINES_FROM('formatted-cca.dat')

function INIT_ARR1(size)
    local a = {}
    for i = 1, size do
        a[i] = "0"
    end
    return a
end

function INIT_ARR2(size1, size2)
    local a = {}
    for i = 1, size1 do
        a[i] = {}
        for j = 1, size2 do
            a[i][j] = "0"
        end
    end
    return a
end

function PAUSE(msg)
    print(msg)
    GETIN(_,_,_,_)
end

READ_LINE_IDX = 1

function FORTRAN_READ(types, units)
    local line = READ_LINES[READ_LINE_IDX]
    local result = {}
    for i=1,#types,1 do
        local t = types[i]
        local u = units[i]
        for j=1,u,1 do
            if t == "G" then
                local v = tonum(sub(line, 1, 5))
                if v == nil or v == '' then
                    v = "0"
                else
                    v = tostr(v)
                end
                add(result, v)
                line = sub(line, 6, #line)
            elseif t == "A5" then
                local v = sub(line, 1, 5)
                if v == nil or v == '' then
                    v = ' '
                end
                add(result, v)
                line = sub(line, 6, #line)
            else
                error("Unsupported format type " .. t)
            end
        end
    end
    READ_LINE_IDX = READ_LINE_IDX + 1
    return result
end

function FORTRAN_WRITE(text)
    io.write(text)
end
"""

    lua = emitter.emit_lua(header)
    pass