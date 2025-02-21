#include "walker.hpp"

string printOperation(const operation* op, map<string_view, int>* vars) {
  string out = "";
  int32_t opType = op->VpiOpType();

  out += "(";
  if(unaryOp.find(opType) != unaryOp.end()) {
    // unary operations
    out += unaryOp.find(opType)->second;
    out += printExpr(op->Operands()->at(0), vars);
  }
  else if(binaryOp.find(opType) != binaryOp.end()) {
    // binary oprations
    out += printExpr(op->Operands()->at(0), vars);
    out += " " + binaryOp.find(opType)->second + " ";
    out += printExpr(op->Operands()->at(1), vars);
  }
  else {
    // other operations
    switch(opType) {
      case vpiConditionOp: {
        out += printExpr(op->Operands()->at(0), vars);
        out += " ? ";
        out += printExpr(op->Operands()->at(1), vars);
        out += " : ";
        out += printExpr(op->Operands()->at(2), vars);
        break;
      }

      case vpiConcatOp: {
        out += "{";
        bool first = true;
        for(auto opr : *op->Operands()) {
          if(!first)
            out += ", ";
          first = false;
          out += printExpr(opr, vars);
        }
        out += "}";
        break;
      }

      case vpiMultiConcatOp: {
        out += "{";
        out += printExpr(op->Operands()->at(0), vars);
        out += "{" + printExpr(op->Operands()->at(1), vars) + "}";
        out += "}";
        break;
      }

      case vpiInsideOp: {
        out += printExpr(op->Operands()->at(0), vars);
        out += " inside {";
        for (uint32_t i = 1; i < op->Operands()->size(); i++) {
          if(i != 1)
            out += ", ";
          out += printExpr(op->Operands()->at(i), vars);
        }
        out += "}";
        break;
      }

      case vpiCastOp: {
        out += printExpr(op->Operands()->at(0), vars);
        break;
      }

      default: walker_error("unknown operation type: " << opType);
    }
  }
  out += ")";

  return out;
}

string printExpr(const any* ex, map<string_view, int>* vars) {
  cout << "------------printExpr-----------" << endl;

  ExprEval eval;
  cout << eval.prettyPrint(ex) << endl;

  cout << "name: " << ex->VpiName() << endl;
  cout << "type: " << ex->VpiType() << endl;
  cout << "uhdmtype: " << ex->UhdmType() << endl;

  string out = "";
  switch(ex->VpiType()) {
    case vpiIntegerVar: {
      //return on a running variable match
      const integer_var* iv = any_cast<integer_var*>(ex);
      if(vars != nullptr && vars->find(iv->VpiFullName()) != vars->end())
        out += to_string(vars->find(iv->VpiFullName())->second);
      else
        walker_error("Unknown integer variable!");
      break;
    }

    case vpiConstant: {
      const constant* c = any_cast<constant*>(ex);
      out.append(c->VpiDecompile());
      break;
    }

    case vpiEnumConst: {
      const enum_const* c = any_cast<enum_const*>(ex);
      out.append(c->VpiDecompile());
      break;
    }

    case vpiParameter: {
      const parameter* p = any_cast<parameter*>(ex);
      if(vars != nullptr && vars->find(p->VpiFullName()) != vars->end())
        out += to_string(vars->find(p->VpiFullName())->second);
      else
        out.append(p->VpiFullName());
      break;
    }

    case vpiLogicNet:
    case vpiStructNet: {
      const nets* n = any_cast<nets*>(ex);
      out.append(n->VpiFullName());
      break;
    }

    case vpiEnumVar:
    case vpiLogicVar:
    case vpiStructVar: {
      const variables* v = any_cast<variables*>(ex);
      out.append(v->VpiFullName());
      break;
    }

    case vpiOperation: {
      const operation* op = any_cast<operation*>(ex);
      out += printOperation(op, vars);
      break;
    }

    case vpiRefObj: {
      const ref_obj* ro = any_cast<ref_obj*>(ex);
      if(ro->Actual_group())
        out += printExpr(ro->Actual_group(), vars);
      else if(!ro->VpiFullName().empty())
        out += ro->VpiFullName();
      else
        walker_error("No fullname on ref_obj: " << ro->VpiName());
      break;
    }

    case vpiTypespecMember: {
      const typespec_member* tm = any_cast<typespec_member*>(ex);
      out.append(tm->VpiName());
      break;
    }

    case vpiHierPath: {
      const hier_path* hp = any_cast<hier_path*>(ex);
      bool first = true;
      for(auto el : *hp->Path_elems()) {
        if(first)
          out += printExpr(el, vars);
        else {
          string member = printExpr(el, vars);
          out += ".";
          if(member.back() == ']') {
            out += ltrim(rtrim(member, '[', true), '.', false);
            out += "[";
            out += ltrim(member, '[', true);
          }
          else
            out += ltrim(member, '.', false);
        }
        first = false;
      }
      break;
    }

    case vpiBitSelect: {
      const bit_select* bs = any_cast<bit_select*>(ex);
      string base = printExpr(bs->VpiParent(), vars);
      out += (base.back() == ']') ? rtrim(base, '[', false) : base;
      out += "[" + printExpr(bs->VpiIndex(), vars) + "]";
      break;
    }

    case vpiPartSelect: {
      const part_select* ps = any_cast<part_select*>(ex);
      string base = printExpr(ps->VpiParent(), vars);
      out += (base.back() == ']') ? rtrim(base, '[', false) : base;
      out += "[" + printExpr(ps->Left_range(), vars);
      out += ":";
      out += printExpr(ps->Right_range(), vars) + "]";
      break;
    }

    case vpiIndexedPartSelect: {
      const indexed_part_select* ips = any_cast<indexed_part_select*>(ex);
      string base = printExpr(ips->VpiParent(), vars);
      out += (base.back() == ']') ? rtrim(base, '[', false) : base;
      out += "[" + printExpr(ips->Base_expr(), vars);
      out += (ips->VpiIndexedPartSelectType() == vpiPosIndexed) ? "+:" : "-:";
      out += printExpr(ips->Width_expr(), vars) + "]";
      break;
    }

    case vpiSysFuncCall: {
      const tf_call* tf = any_cast<tf_call*>(ex);
      out.append(tf->VpiName());
      out += "(";
      bool first = true;
      for(auto arg : *tf->Tf_call_args()) {
        if(!first)
          out += ", ";
        out += printExpr(arg, vars);
        first = false;
      }
      out += ")";
      break;
    }

    default: walker_error("unknown print expr type: " << ex->VpiType());
  }

  cout << "print: " << out << endl;
  return out;
}

void netsInExpr(const any* ex, unordered_set<string>* nets, unordered_set<string>* conds, map<string_view, int>* vars) {
  cout << "-----------netsInExpr----------" << endl;

  if(ex == nullptr)
    walker_error("NULL expression!");

  ExprEval eval;
  cout << eval.prettyPrint(ex) << endl;

  cout << "name: " << ex->VpiName() << endl;
  cout << "type: " << ex->VpiType() << endl;
  cout << "uhdmtype: " << ex->UhdmType() << endl;

  switch(ex->VpiType()) {
    case vpiIntegerVar:
    case vpiParameter:
    case vpiConstant:
    case vpiEnumConst: {
      //IGNORE
      break;
    }

    case vpiLogicNet:
    case vpiStructNet: {
      const UHDM::nets* n = any_cast<UHDM::nets*>(ex);
      cout << "NET: " << n->VpiFullName() << endl;
      nets->insert(string(n->VpiFullName()));
      break;
    }

    case vpiArrayVar:
    case vpiPackedArrayVar:
    case vpiEnumVar:
    case vpiLogicVar:
    case vpiStructVar: {
      const variables* v = any_cast<variables*>(ex);
      cout << "VAR: " << v->VpiFullName() << endl;
      nets->insert(string(v->VpiFullName()));
      break;
    }

    case vpiOperation: {
      const operation* op = any_cast<operation*>(ex);
      cout << "OPERATION: " << op->VpiOpType() << endl;

      if(op->Operands() != nullptr) {
        if(op->VpiOpType() == vpiConditionOp) {
          string opCondStr = printExpr(op->Operands()->front(), vars);
          cout << "MUX TERNARY: " << opCondStr << endl;
          if(conds != nullptr)
            conds->insert(opCondStr);

          for (uint32_t i = 1; i < op->Operands()->size(); i++)
            netsInExpr(op->Operands()->at(i), nets, conds, vars);
        }
        else {
          for(auto opr : *op->Operands())
            netsInExpr(opr, nets, conds, vars);
        }
      }
      break;
    }

    case vpiRefObj: {
      const ref_obj* ro = any_cast<ref_obj*>(ex);
      cout << "REF_OBJ: " << ro->VpiFullName() << endl;
      if(ro->Actual_group() != nullptr)
        netsInExpr(ro->Actual_group(), nets, conds, vars);
      else if(!ro->VpiFullName().empty())
        nets->insert(string(ro->VpiFullName()));
      else
        walker_error("No fullname on ref_obj: " << ro->VpiName());
      break;
    }

    case vpiHierPath: {
      const hier_path* hp = any_cast<hier_path*>(ex);
      string full = printExpr(hp, vars);
      cout << "HierPath: " << full << endl;
      netsInExpr(hp->Path_elems()->front(), nets, conds, vars);
      break;
    }

    case vpiBitSelect:
    case vpiPartSelect:
    case vpiIndexedPartSelect: {
      cout << "Select: " << endl;
      unordered_set<string>* sel_nets = new unordered_set<string>();
      netsInExpr(ex->VpiParent(), sel_nets, conds, vars);
      for(auto sel_net : *sel_nets)
        nets->insert((sel_net.back() == ']') ? rtrim(sel_net, '[', false) : sel_net);
      break;
    }

    case vpiVarSelect: {
      const var_select* vs = any_cast<var_select*>(ex);
      nets->insert(string(vs->VpiFullName()));
      break;
    }

    case vpiTaggedPattern: {
      const tagged_pattern* tp = any_cast<tagged_pattern*>(ex);
      netsInExpr(tp->Pattern(), nets, conds, vars);
      break;
    }

    case vpiSysFuncCall: {
      const tf_call* tf = any_cast<tf_call*>(ex);
      cout << "Task/Function Call: " << tf->VpiName() << endl;
      for(auto arg : *tf->Tf_call_args())
        netsInExpr(arg, nets, conds, vars);
      break;
    }

    default: walker_error("unknown expr type: " << ex->VpiType());
  }
}

void evalStmt(module_t* out, const any* st, const any* inst, unordered_set<string>* conds, map<string_view, int>* vars) {
  if(conds == nullptr)
    conds = new unordered_set<string>();

  if(vars == nullptr)
    vars = new map<string_view, int>();

  switch(st->VpiType()) {
    case vpiNamedBegin: {
      cout << "STMT: NamedBegin" << endl;
      const UHDM::named_begin* nb = any_cast<UHDM::named_begin*>(st);
      for(auto s : *nb->Stmts())
        evalStmt(out, s, inst, conds, vars);
      break;
    }

    case vpiBegin: {
      cout << "STMT: Begin" << endl;
      const UHDM::begin* bg = any_cast<UHDM::begin*>(st);
      for(auto s : *bg->Stmts())
        evalStmt(out, s, inst, conds, vars);
      break;
    }

    case vpiEventControl: {
      cout << "STMT: EventControl" << endl;
      const event_control* ec = any_cast<event_control*>(st);
      if(ec->Stmt() != nullptr)
        evalStmt(out, ec->Stmt(), inst, conds, vars);
      break;
    }

    case vpiAssignment: {
      cout << "STMT: Assignment" << endl;
      const assignment* as = any_cast<assignment*>(st);
      cout << "\tBlocking: " << as->VpiBlocking() << endl;
      const expr* lhs = as->Lhs();
      const any* rhs = as->Rhs();
      unordered_set<string>* lhsNets = new unordered_set<string>();
      unordered_set<string>* rhsNets = new unordered_set<string>();
      unordered_set<string>* rhsConds = new unordered_set<string>();

      netsInExpr(lhs, lhsNets, nullptr, vars);
      netsInExpr(rhs, rhsNets, rhsConds, vars);
      rhsConds->insert(conds->begin(), conds->end());

      for(auto lhsNet : *lhsNets)
        out->addNet(lhsNet, rhsNets, rhsConds, !as->VpiBlocking());
      break;
    }

    case vpiIf: {
      const if_stmt* is = any_cast<if_stmt*>(st);
      string isCondStr = printExpr(is->VpiCondition(), vars);
      cout << "MUX IF: " << isCondStr << endl;
      conds->insert(isCondStr);

      if(is->VpiStmt() != nullptr)
        evalStmt(out, is->VpiStmt(), inst, conds, vars);

      conds->erase(isCondStr);
      break;
    }

    case vpiIfElse: {
      const if_else* ie = any_cast<if_else*>(st);
      string ieCondStr = printExpr(ie->VpiCondition(), vars);
      cout << "MUX IF_ELSE: " << ieCondStr << endl;
      conds->insert(ieCondStr);

      if(ie->VpiStmt() != nullptr)
        evalStmt(out, ie->VpiStmt(), inst, conds, vars);

      if(ie->VpiElseStmt() != nullptr)
        evalStmt(out, ie->VpiElseStmt(), inst, conds, vars);

      conds->erase(ieCondStr);
      break;
    }

    case vpiCase: {
      cout << "STMT: Case" << endl;
      const case_stmt* cs = any_cast<case_stmt*>(st);
      string csCondStr = printExpr(cs->VpiCondition(), vars);

      for(auto ci : *cs->Case_items()) {
        string caseCond = "(" + csCondStr + " inside {";
        bool first = true;
        if(ci->VpiExprs() != nullptr) {
          for(auto ex : *ci->VpiExprs()) {
            string ciCondStr = printExpr(ex, vars);

            if(!first)
              caseCond += ", ";
            caseCond += ciCondStr;
            first = false;
          }
          caseCond += "})";
          cout << "MUX CASE: " << caseCond << endl;
          conds->insert(caseCond);
        }

        if(ci->Stmt() != nullptr)
          evalStmt(out, ci->Stmt(), inst, conds, vars);

        if(ci->VpiExprs() != nullptr)
          conds->erase(caseCond);
      }
      break;
    }

    case vpiFor: {
      cout << "STMT: For" << endl;
      const for_stmt* fs = any_cast<for_stmt*>(st);
      const assign_stmt* fs_init = any_cast<assign_stmt*>(fs->VpiForInitStmts()->at(0));
      const operation* fs_cond = any_cast<operation*>(fs->VpiCondition());
      const any* fs_st = fs->VpiStmt();
      const any* fs_inc = fs->VpiForIncStmts()->at(0);

      if(fs_init == nullptr || fs_cond == nullptr || fs_st == nullptr || fs_inc == nullptr)
        walker_error("Unhandled for statement!");

      if((fs->VpiForInitStmts()->size() > 1) || (fs->VpiForIncStmts()->size() > 1))
        walker_error("Unhandled for statement with multiple iterators!");

      ExprEval eval;
      bool invalidValue = false;

      //init
      const integer_var* itr_var = any_cast<integer_var*>(fs_init->Lhs());
      string_view itr_name = itr_var->VpiFullName();
      int itr_val = eval.get_uvalue(invalidValue, eval.reduceExpr(fs_init->Rhs(), invalidValue, inst, fs_init));
      int cond_val = eval.get_uvalue(invalidValue, eval.reduceExpr(fs_cond->Operands()->at(1), invalidValue, inst, fs_cond));
      if(invalidValue)
        walker_error("Unhandled for init/condition value!");

      while(true) {
        //condition
        bool cond;
        switch(fs_cond->VpiOpType()) {
          case vpiGtOp: {cond = (itr_val > cond_val); break;}
          case vpiGeOp: {cond = (itr_val >= cond_val); break;}
          case vpiLtOp: {cond = (itr_val < cond_val); break;}
          case vpiLeOp: {cond = (itr_val <= cond_val); break;}
          default: walker_error("Unknown for condition type: " << fs_cond->VpiOpType());
        }
        if(!cond)
          break;

        //execute
        cout << "For itr: " << itr_name << ": " << itr_val << endl;
        vars->insert({itr_name, itr_val});
        evalStmt(out, fs_st, inst, conds, vars);
        vars->erase(itr_name);

        //update
        int32_t incType;
        switch(fs_inc->VpiType()) {
          case vpiAssignment: {incType = any_cast<operation*>(any_cast<assignment*>(fs_inc)->Rhs())->VpiOpType(); break;}
          case vpiOperation: {incType = any_cast<operation*>(fs_inc)->VpiOpType(); break;}
          default: walker_error("Unknown for update type: " << fs_inc->VpiType());
        }

        switch(incType) {
          case vpiAddOp:
          case vpiPostIncOp:
          case vpiPreIncOp: {itr_val++; break;}
          case vpiSubOp:
          case vpiPostDecOp:
          case vpiPreDecOp: {itr_val--; break;}
          default: walker_error("Unknown for update op: " << incType);
        }
      }
      break;
    }

    case vpiSysFuncCall:
    case vpiImmediateAssert: {
      //IGNORE
      break;
    }

    default: walker_error("Unknown statement type: " << st->VpiType());
  }
}

void evalParam(module_t* out, const param_assign* pass, const any* inst) {
  ExprEval eval;
  bool invalidValue = false;

  const parameter* lhs = any_cast<parameter*>(pass->Lhs());
  const any* rhs = pass->Rhs();

  expr* reduced = eval.reduceExpr(rhs, invalidValue, inst, pass);
  uint64_t val = eval.get_uvalue(invalidValue, reduced);
  string name = string(lhs->VpiFullName());

  parameter_t* param = new parameter_t();
  param->name = name;
  param->val = val;
  out->params->insert({param->name, param});
}

void evalPort(module_t* out, const port* p) {
  int32_t direction = p->VpiDirection();
  const any* lowConn = p->Low_conn();
  const any* highConn = p->High_conn();

  port_t* port = new port_t();

  if(direction == vpiOutput)
    port->isOutput = true;
  else if(direction == vpiInput)
    port->isOutput = false;
  else walker_error("unknown port type");

  if(lowConn) {
    unordered_set<string>* lowConnNets = new unordered_set<string>();
    netsInExpr(lowConn, lowConnNets, nullptr, nullptr);

    if(lowConnNets->size() != 1)
      walker_error("Multiple low conns on: " << p->VpiName());

    port->name = *lowConnNets->begin();
  }
  else walker_error("No low conn on: " << p->VpiName());

  if(highConn) {
    unordered_set<string>* highConnNets = new unordered_set<string>();
    unordered_set<string>* highConnConds = new unordered_set<string>();
    netsInExpr(highConn, highConnNets, highConnConds, nullptr);
    for(auto highConnNet : *highConnNets)
      port->highConns->insert(highConnNet);
    for(auto highConnCond : *highConnConds)
      port->conds->insert(highConnCond);
  }

  out->ports->insert({port->name, port});
}

void evalContAssign(module_t* out, const cont_assign* cass, map<string_view, int>* vars) {
  const expr* lhs = cass->Lhs();
  const expr* rhs = cass->Rhs();
  unordered_set<string>* lhsNets = new unordered_set<string>();
  unordered_set<string>* rhsNets = new unordered_set<string>();
  unordered_set<string>* rhsConds = new unordered_set<string>();

  netsInExpr(lhs, lhsNets, nullptr, vars);
  netsInExpr(rhs, rhsNets, rhsConds, vars);

  for(auto lhsNet : *lhsNets)
    out->addNet(lhsNet, rhsNets, rhsConds, false);
}

void evalProcessBlock(module_t* out, const process_stmt* pr, const any* inst, map<string_view, int>* vars) {
  cout << "Process type: " << pr->VpiType() << endl;
  if(pr->VpiType() == vpiAlways) {
    const always* al = any_cast<always*>(pr);
    int32_t alwaysType = al->VpiAlwaysType();
    const any* st = al->Stmt();

    bool always_ff;
    switch(alwaysType) {
      case vpiAlways: {
        //TODO: ignore
        always_ff = false;
        break;
      }

      case vpiAlwaysComb: {
        always_ff = false;
        break;
      }
      case vpiAlwaysFF: {
        //TODO: dff here
        always_ff = true;
        break;
      }
      default: walker_error("Unknown always type: " << alwaysType);
    }

    evalStmt(out, st, inst, nullptr, vars);
  }
}

void evalGenStmt(module_t* out, const gen_stmt* gs, const any* inst, map<string_view, int>* vars) {
  if(gs->VpiType() == vpiGenIf) {
    const gen_if* gi = any_cast<gen_if*>(gs);
    cout << "GEN_IF: " << gi->VpiName() << endl;
    //TODO: MUX here?(probably only param)
    const expr* giCond = gi->VpiCondition();

    const any* giStmt = gi->VpiStmt();
    evalStmt(out, giStmt, inst, nullptr, vars);
  }
  else walker_error("Unknown gen statement type: " << gs->VpiType());
}

void evalGenScopeArray(module_t* out, const gen_scope_array* ga, unordered_set<string_view>* locals, map<string_view, int>* vars) {
  if(locals == nullptr)
    locals = new unordered_set<string_view>();

  if(vars == nullptr)
    vars = new map<string_view, int>();

  // temporary generate block data structure
  module_t* gm = new module_t();

  if(ga->Gen_scopes()->size() != 1)
    walker_error("Multiple gen scopes in: " << ga->VpiFullName());

  // go through gen scopes
  // record local signal definitions(params, nets, variables)
  for (auto gs : *ga->Gen_scopes()) {
    cout << "GEN_SCOPE: " << gs->VpiFullName() << endl;
  
    // local parameters are added as temporary variables
    cout << "Parsing params..." << endl;
    if(gs->Parameters() != nullptr) {
      for(auto p : *gs->Parameters()) {
        const parameter* pr = any_cast<parameter*>(p);
        if(pr != nullptr) {
          int val = stoi(ltrim(string(pr->VpiValue()), ':', false));
          cout << "Adding var: " << pr->VpiFullName() << " " << val << endl;
          vars->insert({pr->VpiFullName(), val});
        }
      }
    } else walker_warn("No params in: " << gs->VpiFullName());

    // local parameter assigns
    cout << "Parsing param assigns..." << endl;
    if(gs->Param_assigns() != nullptr) {
      for(auto pass : *gs->Param_assigns()) {
        evalParam(gm, pass, gs);
        locals->insert(any_cast<parameter*>(pass->Lhs())->VpiFullName());
      }
    } else walker_warn("No param assigns in: " << gs->VpiFullName());
 
    // local nets
    if(gs->Nets() != nullptr) {
      for(auto n : *gs->Nets()) {
        locals->insert(n->VpiFullName());
      }
    }

    // local variables
    if(gs->Variables() != nullptr) {
      for(auto v : *gs->Variables()) {
        locals->insert(v->VpiFullName());
      }
    }

    // continuous assignments
    cout << "Parsing cont assigns..." << endl;
    if(gs->Cont_assigns() != nullptr) {
      for(auto cass: *gs->Cont_assigns()) {
        evalContAssign(gm, cass, vars);
      }
    } else walker_warn("No continuous assignments in: " << gs->VpiFullName());
  
    // always blocks
    cout << "Parsing always blocks..." << endl;
    if(gs->Process() != nullptr) {
      for(auto pr: *gs->Process()) {
        evalProcessBlock(gm, pr, gs, vars);
      }
    } else walker_warn("No always blocks in: " << gs->VpiFullName());
  
    // genscope arrays
    cout << "Parsing genscope arrays..." << endl;
    if(gs->Gen_scope_arrays() != nullptr) {
      for(auto gsa : *gs->Gen_scope_arrays()) {
        evalGenScopeArray(gm, gsa, locals, vars);
      }
    } else walker_warn("No genscope arrays in: " << gs->VpiFullName());
  
    // submodules
    if(gs->Modules() != nullptr) {
      for(auto mi : *gs->Modules()) {
        module_t* inst = new module_t();
        inst->highmod = gm;
        gm->submods->insert({string(mi->VpiFullName()), inst});
        evalModule(inst, mi, vars);
      }
    } else walker_warn("No submodules in: " << gs->VpiFullName());

    // remove temporary variables
    if(gs->Parameters() != nullptr) {
      for(auto p : *gs->Parameters()) {
        const parameter* pr = any_cast<parameter*>(p);
        if(pr != nullptr)
          vars->erase(pr->VpiFullName());
      }
    }
  }

  cout << "Fixing: " << ga->VpiFullName() << endl;
  // copy from temporary to original module data structure
  // copy params as is
  for(auto p : *gm->params) {
    out->params->insert({p.first, p.second});
    cout << "Copying: " << p.first << p.second->val << endl;
  }

  // copy submodules and point to original module
  for(auto sm : *gm->submods) {
    sm.second->highmod = out;
    out->submods->insert({sm.first, sm.second});
  }

  // copy nets and fix non-local net names
  for(auto n : *gm->nets) {
    string name = genScopeNetFix(n.first, ga->VpiFullName(), ga->VpiName(), locals);

    unordered_set<string>* rhs = new unordered_set<string>();
    for(auto rhsNet : *n.second->rhs)
      rhs->insert(genScopeNetFix(rhsNet, ga->VpiFullName(), ga->VpiName(), locals));

    unordered_set<string>* conds = new unordered_set<string>();
    for(auto cond : *n.second->conds)
      conds->insert(genScopeExprFix(cond, ga->VpiFullName(), ga->VpiName(), locals));

    out->addNet(name, rhs, conds, n.second->isReg);
  }
}

void evalModule(module_t* out, module_inst* m, map<string_view, int>* vars) {

  out->name = m->VpiName();
  out->fname = m->VpiFullName();
  out->dname = m->VpiDefName();
  out->isTop = m->VpiTopModule();
  cout << "MODULE: " << out->fname << endl;

  // parameters
  cout << "Parsing params..." << endl;
  if(m->Param_assigns() != nullptr) {
    for(auto pass : *m->Param_assigns()) {
      evalParam(out, pass, m);
    }
  } else walker_warn("No params in: " << m->VpiFullName());

  // ports
  cout << "Parsing ports..." << endl;
  if(m->Ports() != nullptr) {
    for(auto p : *m->Ports()) {
      evalPort(out, p);
    }
  } else walker_warn("No ports in: " << m->VpiFullName());

  // continuous assignments
  cout << "Parsing cont assigns..." << endl;
  if(m->Cont_assigns() != nullptr) {
    for(auto cass: *m->Cont_assigns()) {
      evalContAssign(out, cass, vars);
    }
  } else walker_warn("No continuous assignments in: " << m->VpiFullName());

  // always blocks
  cout << "Parsing always blocks..." << endl;
  if(m->Process() != nullptr) {
    for(auto pr: *m->Process()) {
      evalProcessBlock(out, pr, m, vars);
    }
  } else walker_warn("No always blocks in: " << m->VpiFullName());

  // gen if statements
  cout << "Parsing gen if statements..." << endl;
  if(m->Gen_stmts() != nullptr) {
    for(auto gs : *m->Gen_stmts()) {
      evalGenStmt(out, gs, m, vars);
    }
  } else walker_warn("No gen statements in: " << m->VpiFullName());

  // genscope arrays
  cout << "Parsing genscope arrays..." << endl;
  if(m->Gen_scope_arrays() != nullptr) {
    for(auto ga : *m->Gen_scope_arrays()) {
      evalGenScopeArray(out, ga, nullptr, vars);
    }
  } else walker_warn("No genscope arrays in: " << m->VpiFullName());

  // submodules
  if(m->Modules() != nullptr) {
    for(auto mi : *m->Modules()) {
      module_t* inst = new module_t();
      inst->highmod = out;
      out->submods->insert({string(mi->VpiFullName()), inst});
      evalModule(inst, mi, vars);
    }
  } else walker_warn("No submodules in: " << m->VpiFullName());
}

void traverseNet(module_t* m, string net, int depth, unordered_set<string>* visited, unordered_set<cov_t, covHash>* covs) {
  // return on input port of top module
  auto pit = m->ports->find(net);
  if(pit != m->ports->end() && !pit->second->isOutput && m->isTop)
    return;

  // return on a visited net, otherwise update visited nets
  if(visited->find(net) != visited->end())
    return;
  else
    visited->insert(net);

  // return on a globally visited net at the same depth(?)
  if(global_visited->find(cov_t(net, depth)) != global_visited->end())
    return;
  else
    global_visited->insert(cov_t(net, depth));

  // check blacklist modules(?)

  // check local drivers, submodules, and supermodules
  bool isLocal = (m->nets->find(net) != m->nets->end());
  bool isSupermod = !m->isTop && (m->ports->find(net) != m->ports->end()) && !m->ports->find(net)->second->isOutput;
  bool isSubmodOut = false;

  module_t* submod;
  port_t* submodPort;
  for(auto sm : *m->submods) {
    for(auto p : *sm.second->ports) {
      isSubmodOut = p.second->isOutput && (p.second->highConns->find(net) != p.second->highConns->end());
      if(isSubmodOut) {
        submod = sm.second;
        submodPort = p.second;
        break;
      }
    }
    if(isSubmodOut)
      break;
  }

  // traverse net drivers
  if(isLocal) {
    // MUX selects
    for(auto cond : *m->nets->find(net)->second->conds)
      covs->insert(cov_t(cond, depth));
    // updated depth on DFF
    int depth_n = m->nets->find(net)->second->isReg ? (depth + 1) : depth;
    // traverse drivers
    for(auto rhs : *m->nets->find(net)->second->rhs) {
      traverseNet(m , rhs, depth_n, visited, covs);
    }
  }
  else if(isSupermod) {
    // MUX selects
    for(auto cond : *m->ports->find(net)->second->conds)
      covs->insert(cov_t(cond, depth));
    // traverse supermodule drivers
    for(auto hc : *m->ports->find(net)->second->highConns)
      traverseNet(m->highmod, hc, depth, visited, covs);
  }
  else if(isSubmodOut) {
    // traverse submodule port
    traverseNet(submod, submodPort->name, depth, visited, covs);
  }
  else walker_error("No driver found for: " << net);

  visited->erase(net);
}

void traverseModule(module_t* m, unordered_set<cov_t, covHash>* covs) {
  cout << "Travese module: " << m->fname << endl;
  for(auto p : *m->ports) {
    if(p.second->isOutput) {
      cout << "Traverse port: " << p.second->name << endl;
      traverseNet(m, p.second->name, 0, new unordered_set<string>(), covs);
    } 
  }
}

int main(int argc, const char** argv) {
  // Read command line, compile a design, use -parse argument
  unsigned int code = 0;
  SURELOG::SymbolTable* symbolTable = new SURELOG::SymbolTable();
  SURELOG::ErrorContainer* errors = new SURELOG::ErrorContainer(symbolTable);

  SURELOG::CommandLineParser* clp =
    new SURELOG::CommandLineParser(errors, symbolTable, false, false);
  clp->noPython();
  clp->setParse(true);
  clp->setwritePpOutput(true);
  clp->setCompile(true);
  clp->setElaborate(true);  // Request Surelog instance tree Elaboration
  clp->setElabUhdm(true);  // Request UHDM Uniquification/Elaboration

  bool success = clp->parseCommandLine(argc, argv);
  errors->printMessages(clp->muteStdout());
  vpiHandle the_design = 0;
  SURELOG::scompiler* compiler = nullptr;
  if (success && (!clp->help())) {
    compiler = SURELOG::start_compiler(clp);
    the_design = SURELOG::get_uhdm_design(compiler);
    auto stats = errors->getErrorStats();
    code = (!success) | stats.nbFatal | stats.nbSyntax | stats.nbError;
  }

  debug("UHDM Elaboration...\n");
  UHDM::Serializer serializer;
  UHDM::ElaboratorListener* listener = new UHDM::ElaboratorListener(&serializer, false);
  listener->listenDesigns({the_design});
  delete listener;
  debug("Listener in place\n");

  // Browse the UHDM Data Model using the IEEE VPI API.
  // See third_party/Verilog_Object_Model.pdf

  // Either use the
  // - C IEEE API, (See third_party/UHDM/tests/test_helper.h)
  // - or C++ UHDM API (See third_party/UHDM/headers/*.h)
  // - Listener design pattern (See third_party/UHDM/tests/test_listener.cpp)
  // - Walker design pattern (See third_party/UHDM/src/vpi_visitor.cpp)

  SURELOG::FileSystem* const fileSystem = SURELOG::FileSystem::getInstance();
  filesystem::path outputDir = fileSystem->toPlatformAbsPath(clp->getOutputDirId());

  if (the_design) {
    UHDM::design* udesign = nullptr;
    if (vpi_get(vpiType, the_design) == vpiDesign) {
      // C++ top handle from which the entire design can be traversed using the
      // C++ API
      udesign = UhdmDesignFromVpiHandle(the_design);
      debug("Design name (C++): " << udesign->VpiName() << "\n");
    }
    // Example demonstrating the classic VPI API traversal of the folded model
    // of the design Flat non-elaborated module/interface/packages/classes list
    // contains ports/nets/statements (No ranges or sizes here, see elaborated
    // section below)
    debug("Design name (VPI): " + string(vpi_get_str(vpiName, the_design)) + "\n");

    for (auto m : *udesign->TopModules()) {
      cout << "Top Module: " << m->VpiFullName() << endl;
      module_t* top = new module_t();
      evalModule(top, m, nullptr);
      top->print();

      unordered_set<cov_t, covHash>* covs = new unordered_set<cov_t, covHash>();
      traverseModule(top, covs);

      ofstream f(outputDir / (ltrim(top->dname, '@', true) + ".sigs"));
      for(auto c : *covs)
        f << c.name << ": " << c.depth << endl;
      f.close();
    }
  } else { debug("No design found!\n"); }

  cout << "\n\n\n*** Parsing Complete!!! ***\n\n\n";

  // Do not delete these objects until you are done with UHDM
  SURELOG::shutdown_compiler(compiler);
  delete clp;
  delete symbolTable;
  delete errors;
  return code;
}
