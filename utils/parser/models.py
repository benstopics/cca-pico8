
from typing import List


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

class ArithmeticExpr:
    def __init__(self, lterm, op, rterm, paren=False):
        self.lterm = lterm
        self.op = op
        self.rterm = rterm
        self.paren = paren

class RelationalExpr:
    def __init__(self, lterm, op, rterm, paren=False):
        self.lterm = lterm
        self.op = op
        self.rterm = rterm
        self.paren = paren

class LogicalExpr:
    def __init__(self, lterm, op, rterm, paren=False):
        self.lterm = lterm
        self.op = op
        self.rterm = rterm
        self.paren = paren

class LogicalIfStatement:
    def __init__(self, cond, stmt):
        self.cond = cond
        self.stmt = stmt

class ArithmeticIfStatement:
    def __init__(self, cond, neg_stmt_id, zero_stmt_id, pos_stmt_id):
        self.cond = cond
        self.neg_stmt_id = neg_stmt_id
        self.zero_stmt_id = zero_stmt_id
        self.pos_stmt_id = pos_stmt_id

class Statement:
    def __init__(self, id, nodes):
        self.id = id
        if nodes is not None:
            self.nodes = nodes if isinstance(nodes, list) else [nodes]
        else:
            self.nodes = []

class VariableRef:
    def __init__(self, name):
        self.name = name

class ArrayRef:
    def __init__(self, name, indexes):
        self.name = name
        self.indexes = indexes

class NegateExpr:
    def __init__(self, expr):
        self.expr = expr

class Goto:
    def __init__(self, stmt_ids, multiplexer_expr=0):
        self.stmt_ids = stmt_ids
        self.multiplexer_expr = multiplexer_expr

class Assignment:
    def __init__(self, memory_ref, value_expr):
        self.memory_ref = memory_ref
        self.value_expr = value_expr

class ArrayRefRange:
    def __init__(self, array_loc_ref: ArrayRef, start_idx, stop_idx, counter_name):
        self.array_loc_ref = array_loc_ref
        self.start_expr = start_idx
        self.stop_expr = stop_idx
        self.counter_name = counter_name

class ArrayAssignment:
    def __init__(self, loc_ref: ArrayRefRange, values: List):
        self.loc_ref = loc_ref
        self.value_exprs = values

class ForLoop:
    def __init__(self, counter_name, start_expr, stop_expr, body_stmts):
        self.counter_name = counter_name
        self.start_expr = start_expr
        self.stop_expr = stop_expr
        self.body_stmts = body_stmts

class CallSubroutine:
    def __init__(self, name, args):
        self.name = name
        self.args = args

class FormatPattern:
    def __init__(self, units=None, type=None):
        self.units = units
        self.type = type

class ReadStatement:
    def __init__(self, device_id, formats: List[FormatPattern], memory_refs):
        self.device_id = device_id
        self.formats = formats
        self.memory_refs = memory_refs

class TypeStatement:
    def __init__(self, formats, value_list):
        self.formats = formats
        self.value_list = value_list

class Modulo:
    def __init__(self, quotient, divisor):
        self.quotient = quotient
        self.divisor = divisor

class Continue: pass

class Pause:
    def __init__(self, msg):
        self.msg = msg

class Stop: pass

class RandExpr: pass

class ExitProgram: pass

class ReturnSubroutine: pass

class Accept:
    def __init__(self, formats: List[FormatPattern], array_ref_range: ArrayRefRange):
        self.formats = formats
        self.array_ref_range = array_ref_range

class Subroutine:
    def __init__(self, name, params, body_stmts):
        self.name = name
        self.params = params
        self.body_stmts = body_stmts
