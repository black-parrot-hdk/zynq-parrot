#include <functional>
#include <iostream>
#include <list>
#include <map>
#include <tuple>
#include <fstream>
#include <unordered_map>
#include <unordered_set>
#include <cstdlib>
#include <cassert>
#include <Surelog/surelog.h>
#include <Surelog/Common/FileSystem.h>
#include <typeinfo>
#include <string_view>
#include <vector>
#include <string>
#include <walker.hpp>

// global variables
// TODO DO NOT PARALLELLIZE WITHOUT MUTEX FOR THIS
bool global_always_ff_flag = false;

// global data structures
map <string, int> paramsAll, params; // for params, needed for supplanting in expressions expansions


filesystem::path outputDir;

/*
   1. We are ignoring part_sel/bit_sel at LHS
   2. Assignments with multiple muxes miss out on inner muxes:
   assign a0 = c1? a1 : c2? a2 : a3; 
   This only captures c1, not c2. To capture c2, 
   determine if (c2 ? a2 : a3) is a mux by checking for operation type.
   Best solution is to only record wire/net to assignment mapping,
   not if an lhsActual is muxOutput
   3. For registers, due to having conditional assignments,
   where conditions will be captured as part of regular parsing
   will be implicit
   4. 
 */

map <string, int> running_const;

unordered_map <string, data_structure> module_ds_map; // MAJOR TODO record only names and compute fullNames

void mapNetsToIO(vpiHandle,
    data_structure &
    );
void parseAssigns(vpiHandle assign,
    data_structure &ds,
    bool isProcedural
    );
void parseAlways(vpiHandle always,
    data_structure &ds
    );
void printOperandsInExpr(vpiHandle h, unordered_set<string> *out, bool print);
void findMuxesInOperation(vpiHandle h, list <string> &buffer);

// this populates the data_structure
void parse_module(vpiHandle module, vpiHandle p_in, bool genScope = false, string useThisForGenScope = "") {

  // TODO -- use defName for efficiency; full instance name repeats parse_modules unnecessarily
  const char *name;
  if(!useThisForGenScope.empty()) {
    if(!genScope)
      walker_error("Name explicitly given despite not being genScope");

    name = useThisForGenScope.c_str();
  } else {
    if(vpi_get(vpiTop, module) == 1) {
      debug("Top module, saving with name\n");
      name = vpi_get_str(vpiName, module);
    } else
      name = vpi_get_str(vpiFullName, module);
  }

  if(name == NULL) {
    walker_error("Name can't be found\n");
  }

  //if already parsed, do not parse again
  if(!genScope && module_ds_map.find(name) != module_ds_map.end()) {
    debug("Module already parsed, so returing\n");
    return;
  }

  debug("\n\nparse_module: " << name << endl);

  data_structure ds;
  ds.parent = p_in;

  // params resolution
  if(vpiHandle pai = vpi_iterate(vpiParameter, module)) {
    debug("Found params\n");
    while(vpiHandle p = vpi_scan(pai)) {
      s_vpi_value value;
      vpi_get_value(p, &value);

      if(value.format) {
        debug("Parameter:\n\t" << vpi_get_str(vpiFullName, p) << " = " << value.value.integer << endl);
        params.insert({vpi_get_str(vpiFullName, p), value.value.integer});
      }
    }
  } else { debug("No params found in current module\n"); }

  if(vpiHandle pai = vpi_iterate(vpiParamAssign, module)) {
    debug("Found paramAssign\n");
    visitParamAssignment(pai);
  } else { debug("No paramAssign found in current module\n"); }

  debug("\nFinal list of params:\n");
  for (map<string, int>::iterator pitr = params.begin(); pitr != params.end(); ++pitr)
    debug(pitr->first << " = " << pitr->second << endl);

  // submodIn_net mapping
  // net_submodOut mapping
  if(vpiHandle m = vpi_iterate(vpiModule, module)) {
    debug("List of submodules in " << name << ":\n");
    while (vpiHandle h = vpi_scan(m)) {
      string submod_name = vpi_get_str(vpiName, h);
      debug("\t<<  " << submod_name << endl);
      ds.modSubmodMap.insert({name, submod_name});

      mapNetsToIO(h, ds);
    }
  }

  debug("Module-Submodule map:\n"); 
  debug(name << endl);
  for (auto const &s : ds.modSubmodMap) {
    debug("\\_" << s.second << endl);
  }

  // save module inputs
  if(vpiHandle ports = vpi_iterate(vpiPort, module)) {
    while (vpiHandle p = vpi_scan(ports)) {
      if(vpi_get(vpiDirection, p) == 1) {
        vpiHandle low_conn = vpi_handle(vpiLowConn, p);
        char *portName = vpi_get_str(vpiFullName, low_conn);
        if(portName) {
          debug("Found input port; saving " << portName << endl);
          ds.moduleInputs.push_front(portName);
        } else {
          debug("Port name not found\n");
        }
      }
    }
  }

  // driver mapping
  if(vpiHandle assigns = vpi_iterate(vpiContAssign, module)) {
    debug("Parsing module assigns\n");
    while (vpiHandle a = vpi_scan(assigns)) {
      parseAssigns(a, ds, false);
    }
  }

  // parse always blocks
  if(vpiHandle proc_blks = vpi_iterate(vpiProcess, module)) {
    while(vpiHandle a = vpi_scan(proc_blks)) {
      global_always_ff_flag = (vpi_get(vpiAlwaysType, a) == 3 || vpi_get(vpiAlwaysType, a) == 1);
      debug("\n\n\nParsing always block | Type: " << (global_always_ff_flag ? "Procedural" : "Continuous") << endl);
      debug("File: " << string(vpi_get_str(vpiFile, a)) << ":" << to_string(vpi_get(vpiLineNo, a)) << endl);
      parseAlways(a, ds);
      assert(ds.running_cond_str.size() == 0);
      vpi_release_handle(a);
    }
  }

  // genScopeArrays (if/for blocks outside of always blocks)
  if(vpiHandle ga = vpi_iterate(vpiGenScopeArray, module)) {
    while (vpiHandle h = vpi_scan(ga)) {
      debug("Iterating genScopeArray\n");
      vpiHandle g = vpi_iterate(vpiGenScope, h);
      while (vpiHandle gi = vpi_scan(g)) {
        debug("Iterating genScope\n");
        // save the parent_scope_name so everything gets associated with the module
        parse_module(gi, p_in, true, name);
        vpi_release_handle(gi);
      }
      vpi_release_handle(g);
      vpi_release_handle(h);
    }
    vpi_release_handle(ga);
  }  

  // save the data structure in the map
  // for gen scope arrays, associate ds with parent module instance
  if(module_ds_map.find(name) == module_ds_map.end()) {
    debug("Inserting freshly into module_ds_map[" << name << "]\n");
    module_ds_map.insert({name, ds});
  } else {
    debug("Appending into each ds in module_ds_map[" << name << "] individually\n");
    module_ds_map[name].modSubmodMap.insert(ds.modSubmodMap.begin(), ds.modSubmodMap.end());  // multimap
    module_ds_map[name].net_submodOut.insert(ds.net_submodOut.begin(), ds.net_submodOut.end()); // unordered_map
    module_ds_map[name].submodIn_net.insert(ds.submodIn_net.begin(), ds.submodIn_net.end()); // multimap
    module_ds_map[name].moduleInputs.insert(module_ds_map[name].moduleInputs.end(), ds.moduleInputs.begin(), ds.moduleInputs.end()); //list
    module_ds_map[name].regs.insert(module_ds_map[name].regs.end(), ds.regs.begin(), ds.regs.end()); //list
    for(auto const& k : ds.net2driver)
      for(auto const& v : k.second)
        module_ds_map[name].net2driver[k.first].insert(v);

    for(auto const& k : ds.net2sel)
      for(auto const& v : k.second)
        module_ds_map[name].net2sel[k.first].insert(v);
  }

  print_ds(outputDir / name, ds);
}

void parseAlways(vpiHandle always, data_structure &ds) {
  debug("Node type: " << UHDM::UhdmName((UHDM::UHDM_OBJECT_TYPE)((const uhdm_handle *)always)->type) << endl);
  switch(((const uhdm_handle *)always)->type) {
    case UHDM::uhdmalways : {
      // always necessarily has a statement
      if(vpiHandle s = vpi_handle(vpiStmt, always)) {
        parseAlways(s, ds);
      } else {
        debug("No statement found in always block\n");
      }
      break;
    }
    /* can be any of:        
       \_begin:               recurse()
       \_named_begin:         recurse()
       \_event_control:       recurse()
       \_for_stmt:            recurse()
       \_assignment:          visitAssign 
       \_case_stmt:           visitCase
       \_if_stmt:             visitIfElse
       \_if_else:             visitIfElse
       else_stmt necessarily appears as a child to if_else
       else_stmt can have if_stmt (to produce an effective `else if`
       \_immediate_assert:    ignore
     */
    case UHDM::uhdmassignment:
    case UHDM::uhdmcont_assign: { 
      // cont_assign doesn't really occur here; check again!
      // if there's an assignment, then it's guaranteed to be the sole assignment
      // otherwise there will be a begin
      debug("Parsing assignment\n");
      parseAssigns(always, ds, global_always_ff_flag);
      break;
    }
    case UHDM::uhdmif_stmt:
    case UHDM::uhdmif_else: {
      vpiHandle condition = vpi_handle(vpiCondition, always);
      bool constOnly;
      list <string> cond_str = visitExpr(condition, true, constOnly);
      if(cond_str.size() != 1)
        walker_error("visitExpr is returning not just one element list");
      // push condition str
      if(!constOnly)
        ds.running_cond_str.push_front("(" + cond_str.front() + ")");
      // can have single assignment, for_stmt, or begin
      vpiHandle s = vpi_handle(vpiStmt, always);
      parseAlways(s, ds);

      if(vpiHandle s_else = vpi_handle(vpiElseStmt, always)) {
        debug("Node type: else_stmt\n");
        parseAlways(s_else, ds);
      }

      if(!constOnly)
        ds.running_cond_str.pop_front();
      break;
    }
    case UHDM::uhdmcase_stmt: {
      bool constOnly;
      list <string> cond_str;
      int width;
      if(vpiHandle c = vpi_handle(vpiCondition, always)) {
        cond_str = visitExpr(c, true, constOnly);
        std::cout << "Fetching width of condition\n";
        UHDM::any* op_obj = (UHDM::any *)(((uhdm_handle *)c)->object);
        UHDM::ExprEval k;
        bool inv;
        if(op_obj) {
          std::cout << "UhdmType: " << op_obj->UhdmType() << std::endl;
          width = k.size(op_obj, inv, op_obj, op_obj, false, false);
          std::cout << "Width: " << width << " | inv: " << inv << std::endl;
        }
      } else
        walker_error("No condition found in case_stmt");

      //if(width != 0 && width <8) // this ignores "instr" (32b) and const case conditions.
      //  ds.running_cond_str.push_front("/*CASE[" + to_string(width) + "]*/ " + cond_str.front());

      debug("Finding case_items\n");
      list <string> matches;
      if(vpiHandle items = vpi_iterate(vpiCaseItem, always)) {
        while(vpiHandle item = vpi_scan(items)) {
          debug("Case item processing\n");
          // the below is for (case_cond == case_item_expr)
          // MAJOR TODO -- like running_cond_str, create a running_case_str which shouldn't be running, but rather a single compare expression 
          if(vpiHandle exprs = vpi_iterate(vpiExpr, item)) {
            while(vpiHandle expr = vpi_scan(exprs)) {
              debug("Case item expression found\n");
              list <string> match;
              bool dummy;
              if(((const uhdm_handle *)expr)->type == UHDM::uhdmoperation) {
                tie(dummy, match) = visitOperation(expr); // rcs used dummily
              } else {
                match = visitExpr(expr, true, dummy); // rcs used dummily
              }
              if(!constOnly) {
                // the && ! is because when using fall through case-items, the running condition string will be wrong
                matches.push_front(match.front());
                debug("Case item expression added\n");
              }
            }
          }
          string equation;
          bool cond_active;
          while(!matches.empty()) {
            equation += " ( ";
            equation += cond_str.front();
            equation += " == ";
            equation += matches.back();
            matches.pop_back();
            equation += ")";
            if(!matches.empty())
              equation += " || ";
            cond_active = true;
          }
          ds.running_cond_str.push_front(equation);

          // will usually be an assignment
          debug("running_cond_str: " << (!ds.running_cond_str.empty() ? ds.running_cond_str.front() : "NIL"));
          parseAlways(item, ds);
          if(cond_active)
            ds.running_cond_str.pop_front();
        }
      }
      break;
    }
    case UHDM::uhdmfor_stmt: {
      // TODO: consider the initial condition, don't assume 0
      string itr;
      int limit = 0;
      if(vpiHandle l = vpi_handle(vpiCondition, always)) {
        if(vpiHandle ops = vpi_iterate(vpiOperand, l)) {
          vpiHandle lhs = vpi_scan(ops);
          itr = vpi_get_str(vpiName, lhs);
          vpiHandle rhs = vpi_scan(ops);
          bool dummy;
          debug("Param: " <<  visitExpr(rhs, true, dummy).front() << endl);
          limit = stoi(evalOperation(rhs));
          debug("Condition for ForLoop: " << itr << " : " <<  limit << endl);
        }
      }

      if(vpiHandle stmt = vpi_handle(vpiStmt, always)) {
        for(int i = 0; i <= limit; i++) {
          debug("Running iteration:  " << itr << " : " << i  << endl);
          running_const.insert({itr, i});
          parseAlways(stmt, ds);
          running_const.erase(itr);
        }
      } else
        walker_error("Stmt not found in for_stmt");
      break;
    }
    case UHDM::uhdmbegin : 
    case UHDM::uhdmnamed_begin : 
    case UHDM::uhdmevent_control :
    default : {
      if(vpiHandle stmt = vpi_handle(vpiStmt, always)) {
        debug("Stmt found\n");
        parseAlways(stmt, ds);
      } else if(vpiHandle stmt = vpi_iterate(vpiStmt, always)) {
        debug("Stmt iterable found\n");
        while(vpiHandle s = vpi_scan(stmt)) {
          parseAlways(s, ds);
        }
      } else
        { debug("Stmt not found; UNKNOWN_NODE\n"); }
    }
  }

}

void parseAssigns(vpiHandle assign, 
    data_structure &ds,
    bool isProcedural
    ) {
  // if LHS is like a[i], or {a,...} what to do?
  debug("\nWalking " << (isProcedural ? "Procedural" : "Cont.") <<  " assignment | " << vpi_get_str(vpiFile, assign) << ":" << vpi_get(vpiLineNo, assign) << endl);
  if(vpiHandle rhs = vpi_handle(vpiRhs, assign)) {
    /* In BlackParrot (at least), RHS in an assignment can only be:
     * Type: bit_select
     * Type: constant
     * Type: hier_path
     * Type: indexed_part_select    
     * Type: part_select
     * Type: ref_obj
     * Type: var_select
     * Type: operation           
     */
    UHDM::UHDM_OBJECT_TYPE rhs_type = (UHDM::UHDM_OBJECT_TYPE)((const uhdm_handle *)rhs)->type;
    debug("Walking RHS | Type: " << UHDM::UhdmName(rhs_type) << endl);

    unordered_set<string> rhsOps;
    printOperandsInExpr(rhs, &rhsOps, false); // updates rhsOperands
    debug("Got RHS\n");

    if (vpiHandle lhs = vpi_handle(vpiLhs, assign)) {
      /* In BP, LHS can only be:
       * Type: bit_select                
       * Type: logic_net
       * Type: hier_path                 
       * Type: indexed_part_select       
       * Type: part_select               
       * Type: ref_obj                   
       * Type: var_select  
       * Type: operation                 
       */
      UHDM::UHDM_OBJECT_TYPE lhsType = (UHDM::UHDM_OBJECT_TYPE)((const uhdm_handle *)lhs)->type;
      debug("Walking LHS | Type: " << UHDM::UhdmName(lhsType) << endl);

      unordered_set <string> lhsStr;
      //if (vpiHandle lhsActual = vpi_handle(vpiActual, lhs)) {
      //  debug("lhsActual exists\n");
      //  if ((UHDM::UHDM_OBJECT_TYPE)((const uhdm_handle *)lhsActual)->type == UHDM::uhdmstruct_net) {
      //    debug("Found struct on lhs of assignment\n");
      //    // TODO special case, handle carefully
      //  }
      //}
      if (lhsType == UHDM::uhdmoperation) {
        // if LHS is an operation, it's a concat operation
        assert((const int)vpi_get(vpiOpType, lhs) == vpiConcatOp);
        printOperandsInExpr(lhs, &lhsStr, false);
      } else {
        assert(
            lhsType == UHDM::uhdmref_obj ||
            lhsType == UHDM::uhdmbit_select ||
            lhsType == UHDM::uhdmpart_select ||
            lhsType == UHDM::uhdmlogic_net ||
            lhsType == UHDM::uhdmindexed_part_select ||
            lhsType == UHDM::uhdmhier_path ||
            lhsType == UHDM::uhdmvar_select);
        bool constOnly;
        list tmp = visitExpr(lhs, false, constOnly);
        if(constOnly)
          walker_error("Assigning to a const??");
        assert(tmp.size() <= 1);
        lhsStr.insert(tmp.front());
        // when you search for a variable that has been part-assigned
        // you will not succeed in the search, so trraverse function needs to look for base names
        // not true with upcoming trraverse fn change
      }

      for (const auto& lhsEl : lhsStr) {
        // mionor TODO we are potentially misrepresenting relationships for various lhs operands in case of operation on lhs

        // insert into regs
        if(isProcedural) {
          ds.regs.push_front(lhsEl);
        } 

        // insert into net2sel in case of ternaries in assigns (includes if/case conditions AND'd to them)
        list <string> select_sigs;
        if(rhs_type == UHDM::uhdmoperation) {
          findMuxesInOperation(rhs, select_sigs);
          if(!select_sigs.empty()) {
            for(auto const& sel : select_sigs) {
              // TODO choose between carrying the AND of nested signals or just individual signals
              debug("Composing running string with sel: " << sel << endl);
              string running_cond = compose_running_str(sel, ds);
              debug("Composed running string " << running_cond << endl);
              ds.net2sel[lhsEl].insert(running_cond);
              debug(lhsEl << " ?? " << running_cond << endl);
            }
          } // else debug("LHS is not muxOutput\n");
        } 
        // insert into net2sel if inside if/case statements regardless of rhs being an expr
        else if(!ds.running_cond_str.empty()) {
          // this signals the assignment is inside an if/case condition
          debug("Composed running string not because tern\n");
          ds.net2sel[lhsEl].insert(compose_running_str("", ds));
        }

        // insert into net2driver
        for (const auto& rhsStr: rhsOps) {
          auto it = find(select_sigs.begin(), select_sigs.end(), rhsStr);
          if(it != select_sigs.end()) {
            // no need to add select_signals as drivers
            continue;
          } else {
            ds.net2driver[lhsEl].insert(rhsStr);
            debug(lhsEl << (isProcedural ? " <- " : " <= ") << rhsStr << endl);
          }
        }
      }

      vpi_release_handle(lhs);
    } // else debug("Assignment without LHS handle\n");
    vpi_release_handle(rhs);
  } // else debug("Assignment without RHS handle\n");
}

void mapNetsToIO(vpiHandle submodule,
    data_structure &ds
    ) {
  string submodule_name = vpi_get_str(vpiName, submodule);
  if(vpiHandle ports = vpi_iterate(vpiPort, submodule)) {
    debug("Parsing submod ports\n");
    while (vpiHandle p = vpi_scan(ports)) {
      if(vpiHandle low_conn = vpi_handle(vpiLowConn, p)) {
        // low conn can never be operation, has to be a ref_obj
        string low_conn_name = vpi_get_str(vpiFullName, low_conn);
        if(vpiHandle high_conn = vpi_handle(vpiHighConn, p)) {
          //vpiHandle actual_high = vpi_handle(vpiActual, high_conn);
          //if(actual_high)
          //  high_conn = actual_high;
          debug("HighConn type: " << UHDM::UhdmName(((const uhdm_handle *)high_conn)->type) << endl);
          if(((const uhdm_handle *)high_conn)->type == UHDM::uhdmoperation) {
            // if the port's high_conn is an operation
            /* vpiOpType : type
             * 36 : empty
             */
            if(vpi_get(vpiOpType, high_conn) == 36) {
              // unconnected output port -- so ignore; technically you should have known this from DCE
            } else {
              unordered_set <string> l;
              printOperandsInExpr(high_conn, &l, false);
              for (auto const& el : l) {
                // 2 -> output port
                // 1 -> input port
                if(vpi_get(vpiDirection, p) == 2) {
                  ds.net_submodOut.insert({el, make_tuple(low_conn_name, submodule)});
                  debug("MappingOut: " << el << " <> " << low_conn_name << endl);
                } else {
                  ds.submodIn_net.insert({low_conn_name, el}); // can be a multimap
                  debug("MappingIn: " << low_conn_name << " <> " << el << endl);
                }
              }
            }
          } else {
            //if(!(
            //    ((const uhdm_handle *)high_conn)->type == UHDM::uhdmref_obj ||
            //    ((const uhdm_handle *)high_conn)->type == UHDM::uhdmlogic_net ||
            //    ((const uhdm_handle *)high_conn)->type == UHDM::uhdmlogic_var ||
            //    ((const uhdm_handle *)high_conn)->type == UHDM::uhdmconstant ||
            //    ((const uhdm_handle *)high_conn)->type == UHDM::uhdmhier_path || 
            //    ((const uhdm_handle *)high_conn)->type == UHDM::uhdmindexed_part_select  ||
            //    ((const uhdm_handle *)high_conn)->type == UHDM::uhdmpart_select ||
            //    ((const uhdm_handle *)high_conn)->type == UHDM::uhdmbit_select)) 
            //  walker_warn("HighConn none of the above?");
            bool constOnly;
            list tmp = visitExpr(high_conn, true, constOnly);
            string hc = tmp.front();
            if(constOnly)
              hc = "IGNORED";

            if(!tmp.empty()) {
              if(vpi_get(vpiDirection, p) == 2) {
                ds.net_submodOut.insert({hc, make_tuple(low_conn_name, submodule)});
                debug("MappingOut: " << hc << " <> " << low_conn_name << endl);
              } else {
                ds.submodIn_net.insert({low_conn_name, hc}); // can be a multimap
                debug("MappingIn: " << low_conn_name << " <> " << hc  << endl);
              }
            }
          }
        }
      }
    }
  }
}

// PS: traverse is purely string-based; the inst is used only when needing to recurse into the submodule or supermodule
/* 
   MAJOR TODO : new traverse_funcrion
   traverse(net, psel) -- net = strcat(net, psel), psel = ""
   1. search for net, if found jump to found
   2. search for net.* / net[*], if found jump to found
   3. {net, psel} = shiftleft(net, psel);
   4. search for net, if found jump to found, if not jump to 3
found: get drivers and traverse
 */

map <string, string> blacklist = { 
  // module defName            sel input
  {"work@bsg_mux2_gatestack",  "i2"},
  {"work@bsg_mux_bitwise",     "sel_i"},
  {"work@bsg_mux_butterfly",   "sel_i"},
  {"work@bsg_muxi2_gatestack", "i2"},
  {"work@bsg_mux_one_hot",     "sel_one_hot_i"},
  {"work@bsg_mux_segmented",   "sel_i"},
  {"work@bsg_mux",             "sel_i"},
  {"work@bsg_scan",            ""}
};

bool findDriver (data_structure &ds, string net) {
  return ds.net2driver.find(net) != ds.net2driver.end();
}
bool findSource (data_structure &ds, string net) {
  auto source = ds.net_submodOut.find(net);
  return source != ds.net_submodOut.end();
}
bool findIfInput(data_structure &ds, string net) {
  return find(ds.moduleInputs.begin(), ds.moduleInputs.end(), net) != ds.moduleInputs.end();
}

unordered_set<string> global_visited;

void traverse(string pnet, 
    //string psel,
    vpiHandle inst, int depth, unordered_set<string> &visited, unordered_set<pair<string, int>, PairHash> &covs, string indent = "") {

  // some nets can be directly avoided -- clk, reset (but I don't think we ever get clk).
  // for resets, I think since we avoid parsing the select signal, it should also be automatically taken care of

  //string net = pnet + psel;
  string net = pnet;

  // retrieve the data_structure
  bool topModule = vpi_get(vpiTop, inst);
  string name = topModule ? vpi_get_str(vpiName, inst) : vpi_get_str(vpiFullName, inst);
  // module_ds_map[name] is already manually populated prior to first call
  data_structure ds = module_ds_map[name];

  // if module input and topModule, exit cleanly
  bool isInput = findIfInput(ds, net);
  debug(indent << (isInput ? "Net is an input port" : "Net is not an input port") << endl);
  if (topModule && isInput) {
    debug(indent << "*** Success!! ***\n");
    return;
  } // if not topmodule, handled within source-finding routine

  if(net == "IGNORED") {
    debug(indent << "Constant found; ignoring\n");
    return;
  }

  // if already traversed as a parent, return, otherwise also save to visited
  if(visited.find(net) != visited.end()) {
    debug(indent << "\tPreviously traversed within same subtree\n");
    return;
  } else {
    visited.insert(net);
  }

  if(global_visited.find(net + "," + to_string(depth)) != global_visited.end()) {
    debug(indent << "\tPreviously traversed at same depth\n");
    return;
  } else {
    global_visited.insert(net+ "," + to_string(depth));
  }

  debug(indent << "Parsing: " << net << " | depth=" << depth << " | inst: "<< name << endl);

  // assume we have nothing
  bool noDriver = true;
  bool noSource = true;
  bool noSupermod = true;

  // iterators for different ds
  auto source = ds.net_submodOut.find(net);

  // check if blacklisted module
  string defName = vpi_get_str(vpiDefName, inst);
  for (auto const& bl : blacklist)
    if(bl.first == defName) {
      debug(indent << "Blacklisted module\n");
      string sel = vpi_get_str(vpiFullName, inst);
      sel = sel + "." + bl.second;
      debug(indent << "Inserting: " << sel << " @depth=" << depth << endl);
      covs.insert({sel, depth});

      // skip to the input ports of the module (avoid the select signal inputs)
      //vpiHandle supermodule = vpi_handle(vpiParent, inst);
      vpiHandle supermodule = ds.parent;
      debug(indent << "Input port candidates to jump to:\n");
      //for(auto const& in : module_ds_map[name].moduleInputs)
      //  debug(indent << "[in]: " << in << endl);

      for(auto const& in : module_ds_map[name].moduleInputs) { // in -- low_conn
        debug(indent << "submodIn_net candidates:\n");
        //for(auto const& super_in : module_ds_map[(vpi_get_str(vpiFullName, supermodule))].submodIn_net)
        //  debug(indent << super_in.first << endl);

        char *pname = vpi_get(vpiTop, ds.parent) ? vpi_get_str(vpiName, ds.parent) : vpi_get_str(vpiFullName, ds.parent); // topModule's ds.parent is nullptr
        for(auto const& super_in : module_ds_map[pname].submodIn_net) {
          if(in == super_in.first) {
            debug("Shorting to the input port: " << super_in.second << endl);
            if(in.find(bl.second) == string::npos) {
              debug(indent << "Not a select input, traversing\n");
              //string new_indent = indent.substr(0, indent.length() - 2);
              traverse(super_in.second, supermodule, depth, visited, covs, indent + "| ");
            } else { 
              debug(indent << "This is the select input, ignoring\n"); 
            }
          }
        }
      }

      visited.erase(net);
      debug(indent << "Exiting\n");
      return;
    }

  // if muxOutput, add to covs at this depth
  if(ds.net2sel.find(net) == ds.net2sel.end()) {
    debug(indent << "Net is not mux-output\n");
  } 
  else {
    debug(indent << "Net is mux-output\n");
    unordered_set sels = ds.net2sel[net];
    for (auto const& it : sels) {
      covs.insert({it, depth});
      debug(indent << "\t\\_" << it << ", " << depth << endl);
    }
  }

  // find the assignment where net is lhs 
  //   and recurse into each of the operands
  if(ds.net2driver.find(net) == ds.net2driver.end()) {
    debug(indent << "Net has no registered driver\n");
  }
  else {
    noDriver = false;
    debug(indent << "Driver candidates:\n");
    for (auto const it : ds.net2driver[net]) {
      debug(indent << "[d]: " << it << endl);
    }

    for (auto const it : ds.net2driver[net]) {
      auto findReg = find(ds.regs.begin(), ds.regs.end(), net);
      bool isReg = findReg != ds.regs.end();
      if(isReg) {
        // increment depth
        debug(indent << "Reg driver = " << it << endl);
        traverse(it, inst, depth + 1, visited, covs, indent + "| ");
      } else {
        debug(indent << "Wire driver = " << it << endl);
        traverse(it, inst, depth, visited, covs, indent + "| ");
      }
    }
    //visited.erase(net);
    //debug(indent << "Exiting\n");
    //return;
  }

  // or a module instance where net is the output pin, 
  //   and recurse into each of the operands
  if(source == ds.net_submodOut.end()) {
    debug(indent <<"Net has no registered source\n");
    //for(auto const& el : ds.net_submodOut)
    //  debug("Help: " << el.first << " <- " << get<0>(el.second) << endl);
  } else {
    noSource = false;
    assert(source->first == net);
    debug(indent << "Source = " << get<0>(source->second) << endl);

    vpiHandle submodule = get<1>(source->second);
    if(submodule) {
      debug(indent << "Found submodule handle\n");
      parse_module(submodule, inst);
      debug(indent << "Traversing with submodule handle\n");
      traverse(get<0>(source->second), submodule, depth, visited, covs, indent + "| ");
      //visited.erase(net);
      //debug(indent << "Exiting\n");
      //return;
    } else
      walker_error("Submodule handle not found");
  }

  // if module input and !topModule, recurse back into the super-module
  if(!topModule && isInput) {
    noSupermod = false;
    debug(indent << "Net has a source from supermodule\n");
    if(ds.parent) {
      debug(indent << "Name of supermodule: " << vpi_get_str(vpiName, ds.parent) << endl);
      char *pname = vpi_get(vpiTop, ds.parent) ? vpi_get_str(vpiName, ds.parent) : vpi_get_str(vpiFullName, ds.parent); // topModule's ds.parent is nullptr
      if(pname) {
        data_structure ds_par = module_ds_map[pname];
        auto range = ds_par.submodIn_net.equal_range(net);
        if(range.first == range.second) {
          debug("Supermodule " << pname << " net corresponding to input " << net << " not found!");
          walker_error("Supermodule net not found!");
        }
        debug(indent << "Supermodule net candidates:\n");
        for (auto it = range.first; it != range.second; ++it) {
          debug(indent << "[sup]: " << it->second << endl);
        }
        for (auto it = range.first; it != range.second; ++it) {
          debug(indent << "Traversing into supermodule\n");
          //string new_indent = indent.substr(0, indent.length() - 2);
          traverse(it->second, ds.parent, depth, visited, covs, indent + "| ");
        }
        //visited.erase(net);
        //debug(indent << "Exiting\n");
        //return;
      } else walker_error( "Unable to determine name of supermodule");
    } else walker_error("Parent of current module not found!");
  } else {
    // either not an input port OR is topModule
    debug(indent << "Net has no supermodule source\n");
  }

  // struct fix: 
  // first find net.* or net[*]
  debug(indent << "Finding matches for " << net << ".* or [*]" << endl);
  vector <string> matches = findMatchingStrings(ds, net, indent);
  if(!matches.empty()) {
    for(auto const& el : matches) {
      traverse(el,
          //psel,
          inst, depth, visited, covs, indent + "| ");
    }
    visited.erase(net);
    debug(indent << "Exiting\n");
    return;
  }

  // if not found in either net2driver or net_submodOut do nothing and returrn
  if (noSource && noDriver && noSupermod) {
    // Debug why source or driver couldn't be found

    // struct fix:
    // else try left shifting
    debug(indent << "Failed to match net.* / [*]" << endl);
    string new_net, new_psel;
    string cumul_psel = "";
    string check_net = net;
    while(true) {
      bool r = removeLastWordOrSel(check_net, new_net, new_psel);
      debug(indent << "Finding match for: " << check_net << endl);
      if(r && new_net != name) {
        if((findDriver(ds, new_net) || findSource(ds, new_net) || findIfInput(ds, new_net))) {
          // dealing with either a struct or part/bitsel here
          debug(indent << "Found match for parent: " << new_net << endl);
          traverse(new_net, 
              //new_psel,
              inst, depth, visited, covs, indent + "| ");
          visited.erase(net);
          debug(indent << "Exiting\n");
          return;
        } else {
          check_net = new_net;
          cumul_psel += new_psel;
        }
      } else {
        walker_warn(indent + "DEBUG this node: " + net);
        break;
      }
    }
  }

  visited.erase(net);
  debug(indent << "Exiting\n");
  return;
}

string visitbit_sel(vpiHandle h) {
  string out = "";
  debug("Walking bit select\n");
  if(vpiHandle par = vpi_handle(vpiParent, h)) {
    bool constOnly;
    out += visitExpr(par, true, constOnly).front();
  } else {
    walker_error("Parent to bit_select not found\n");
  }
  /* change by anoop -- last minute -- reverify if works for all
  if(const char *s = vpi_get_str(vpiFullName, h)) {
    out += s;
    debug("FullName at bit_sel: " << s << endl);
  } else {
    vpiHandle par = vpi_handle(vpiParent, h);
    if(!par) {
      walker_error("Couldn't find parent of bit_sel!");
    } else {
      bool constOnly;
      out += visitExpr(par, true, constOnly).front();
    }
  }
  */
  out += "[";
  vpiHandle ind = vpi_handle(vpiIndex, h);
  if(ind) {
    // TODO progressive coverage
    if(vpiHandle m = vpi_handle(vpiActual, ind))
      ind = m;

    if((((const uhdm_handle *)ind)->type) == UHDM::uhdmlogic_var ||
        (((const uhdm_handle *)ind)->type) == UHDM::uhdmlogic_net ||
        (((const uhdm_handle *)ind)->type) == UHDM::uhdmhier_path
      ) {
      bool constOnly;
      out += (visitExpr(ind, true, constOnly)).front();
    } else {
      out += evalOperation(ind);
    }
  } else 
    walker_error("Index not availble");
  out += "]";
  debug("Final bit_sel: " << out << endl);
  return out;
}

string visitindexed_part_sel(vpiHandle h) {
  string out = "";
  debug("Walking indexed part select\n");
  vpiHandle par = vpi_handle(vpiParent, h);
  bool constOnly;
  if(!par)  {debug("Couldn't find parent\n"); }
  else out += visitExpr(par, true, constOnly).front();
  out += "[";
  if(vpiHandle b = vpi_handle(vpiBaseExpr, h)) {
    debug("Base expression found\n");
    out += evalOperation(b);
    vpi_release_handle(b);
  }
  out += "+:";
  if(vpiHandle w = vpi_handle(vpiWidthExpr, h)) {
    debug("Width expression found\n");
    out += evalOperation(w);
    vpi_release_handle(w);
  }
  out += "]";
  return out;
}

// MAJOR TODO -- var_select doesn't have actual,
// so var_sel declared outside, but assigned inside a genBlk will have the genBlk in its path
// which is wrong
string visitvar_sel(vpiHandle h) {
  string out = "";
  debug("Walking var select\n");
  out += vpi_get_str(vpiName, h);

  bool constOnly;
  if(vpiHandle indh = vpi_iterate(vpiIndex, h)) {
    while(vpiHandle ind = vpi_scan(indh)) {
      out += "[";
      out += "0";
      // out += (visitExpr(ind, true, constOnly)).front(); // MAJOR TODO recent Surelog commit fixes this
      out += "]";
    }
    vpi_release_handle(indh);
  } else { debug("Indices not found" << endl); }
  return out;
}

string visitpart_sel(vpiHandle h) {
  string out = "";
  debug("Walking part select\n");
  vpiHandle par = vpi_handle(vpiParent, h);
  bool constOnly;
  if(!par) { debug("Couldn't find parent\n"); }
  else out += visitExpr(par, true, constOnly).front();
  out += "[";
  vpiHandle lrh = vpi_handle(vpiLeftRange, h);
  if(lrh) {
    out += evalOperation(lrh);
  }
  else { debug("Left range not found); type: " << UHDM::UhdmName((UHDM::UHDM_OBJECT_TYPE)(((const uhdm_handle *)lrh)->type)) << endl); }
  out += ":";
  vpiHandle rrh = vpi_handle(vpiRightRange, h);
  if(rrh) {
    out += evalOperation(rrh);
  }
  else { debug("Right range not found); type: " << UHDM::UhdmName((UHDM::UHDM_OBJECT_TYPE)(((const uhdm_handle *)rrh)->type)) << endl); }
  out += "]";
  vpi_release_handle(rrh);
  vpi_release_handle(lrh);
  return out;
}

list <string> visitExpr(vpiHandle h, bool retainConsts, bool& constOnly) {
  debug("In visitExpr; type: " << UHDM::UhdmName((UHDM::UHDM_OBJECT_TYPE)((const uhdm_handle *)h)->type) << endl);
  constOnly = false; // init
  list <string> out;
  switch(((const uhdm_handle *)h)->type) {
    case UHDM::uhdmoperation : {
      // TODO might have to do something based on retain const
      debug("Operation at visitExpr\n");
      tie(constOnly, out) = visitOperation(h);
      break;
    }
    case UHDM::uhdmlogic_net :
    case UHDM::uhdmlogic_var :
    case UHDM::uhdmstruct_var :
    case UHDM::uhdmenum_var :
    case UHDM::uhdmpacked_array_var :
    case UHDM::uhdmstruct_net : {
      debug("Found fullname " << vpi_get_str(vpiFullName, h) << endl);
      out.push_back(vpi_get_str(vpiFullName, h));
      break;
    }
    case UHDM::uhdmtypespec_member : {
      out.push_back(vpi_get_str(vpiName, h));
      break;
    }
    case UHDM::uhdmenum_typespec : {
      //FARZAM: no break? what is this type?
    }
    case UHDM::uhdmenum_const :
    case UHDM::uhdmconstant :
    case UHDM::uhdminteger_var :
    case UHDM::uhdmparameter : {
      constOnly = true;
      if(retainConsts) {
        //TODO evalExpr might mess up constants that might be like 24'h2002
        bool found;
        int tmp = evalExpr(h, found);
        if(found)
          out.push_back(to_string(tmp));
        else if(const char *fullName = vpi_get_str(vpiFullName, h))
          out.push_back(fullName);
        else if(const char *fullName = vpi_get_str(vpiName, h))
          out.push_back(fullName);
        else 
          walker_error("Unable to identify constant");

      } else {
        debug("Ignoring\n");
        out.push_back("IGNORED");
      }
      break;
    }
    case UHDM::uhdmref_obj : {
      if(vpiHandle actual = vpi_handle(vpiActual, h)) {
        debug("Actual type of ref obj: " << UHDM::UhdmName((UHDM::UHDM_OBJECT_TYPE)((const uhdm_handle *)actual)->type) << endl);
        out = visitExpr(actual, retainConsts, constOnly);
      }
      else {
        debug("Ref object at leaf\n");

        debug("Walking reference object); type: " << UHDM::UhdmName((UHDM::UHDM_OBJECT_TYPE)((const uhdm_handle *)h)->type) << endl);
        if (const char* s = vpi_get_str(vpiFullName, h)) {
          debug("FullName available " << s << endl);
          out.push_back(s);
        } else if(const char *s = vpi_get_str(vpiName, h)) {
          debug("FullName unavailable\n");
          out.push_back(s);
        } else walker_error("Neither FullName, nor Name available");
      }
      break;
    }
    case UHDM::uhdmbit_select : {
      debug("Bit select at leaf\n");
      string tmp = visitbit_sel(h);
      out.push_back(tmp);
      break;
    }
    case UHDM::uhdmpart_select : {
      debug("Part select at leaf\n");
      string tmp = visitpart_sel(h);
      out.push_back(tmp);
      break;
    }
    case UHDM::uhdmvar_select : {
      debug("Var select at leaf\n");
      string tmp = visitvar_sel(h);
      out.push_back(tmp);
      break;
    }
    case UHDM::uhdmindexed_part_select : {
      debug("Indexed part select at leaf\n");
      string tmp = visitindexed_part_sel(h);
      out.push_back(tmp);
      break;
    }
    case UHDM::uhdmhier_path : { 
      string tmp = visithier_path(h);
      debug("Struct at leaf: " << tmp << endl);
      out.push_back(tmp);
      break;
    }
    case UHDM::uhdmint_typespec : {
      debug("Typespec at leaf\n");
      s_vpi_value value;
      vpi_get_value(h, &value);
      if (value.format)
        out.push_back(to_string(value.value.integer));
      else {
        if(const char *s = vpi_get_str(vpiFullName, h))
          out.push_back(s);
        else if (const char* s = vpi_get_str(vpiName, h))
          out.push_back(s);
        else {
          walker_error("UNKNOWN int_typespec");
        }
      }
      break;
    }
    case UHDM::uhdmsys_func_call : {
      string fname = vpi_get_str(vpiName, h);
      debug("function call: " << fname << endl);
      if(retainConsts) {
        string tmp = fname + "(";
        if(vpiHandle itr = vpi_iterate(vpiArgument, h)) {
          bool first = true;
          while(vpiHandle i = vpi_scan(itr)) {
            if(!first)
              tmp += ",";
            tmp += (visitExpr(i, retainConsts, constOnly)).front();
            first = false;
          }
        }
        tmp += ")";
        out.push_back(tmp);
      } else {
        if (fname == "$signed" || fname == "$unsigned") {
          if(vpiHandle itr = vpi_iterate(vpiArgument, h))
            while(vpiHandle i = vpi_scan(itr))
              out.push_back(visitExpr(i, retainConsts, constOnly).front());
        } else {
          debug("Ignoring\n");
          out.push_back("IGNORED");
        }
      }
      break;
    }
    case UHDM::uhdmtagged_pattern : {
      vpiHandle pat = vpi_handle(vpiPattern, h);
      out = visitExpr(pat, retainConsts, constOnly);
      break;
    }
    default :
      /*if(char *c = vpi_get_str(vpiFullName, h))
        out.push_back(c);
      else*/ walker_error("UNKNOWN node at leaf; type: " +
          UHDM::UhdmName((UHDM::UHDM_OBJECT_TYPE)((const uhdm_handle *)h)->type));
      break;
  }
  if(out.size() > 1) {
    walker_error("visitExpr gave multiple elelments\n");
  }
  return out;
}

string visithier_path(vpiHandle soph) {
  string out = "";
  debug("Walking hierarchical path\n");

  if(vpiHandle it = vpi_iterate(vpiActual, soph)) {
    bool first = true;
    while(vpiHandle itx = vpi_scan(it)) {
      bool bitsel = ((const uhdm_handle *)itx)->type == UHDM::uhdmbit_select;
      debug("Found ref object; type: " << UHDM::UhdmName((UHDM::UHDM_OBJECT_TYPE)((const uhdm_handle *)itx)->type) << endl);

      if(!first)
        out += ".";

      if(bitsel && first) {
        debug("Walking base (bitsel)\n");
        if(vpiHandle expr = vpi_handle(vpiExpr, soph)) {
          bool constOnly;
          string base = (visitExpr(expr, true, constOnly)).front();
          debug("Base: " << base << endl);

          if(vpiHandle ind = vpi_handle(vpiIndex, itx) ) {
            base += "[";
            base += evalOperation(ind);
            base += "]";
            out += base;
          } else walker_error("Index of bitsel at hier_path not found");
        } else if(const char *fullName = vpi_get_str(vpiFullName, itx)) {
          out += string(fullName);

        } else if(vpiHandle parent = vpi_handle(vpiParent, itx)) {
          if(const char *fullName = vpi_get_str(vpiFullName, parent)) {
            out += string(fullName);
          } else {
            walker_error("Parent of bitsel in hierpath first, doesn't have fullname");
          }

        } else
          walker_error("Cannot find bitsel base");

        debug("Full bitsel: " << out << endl);
      } else {
        if(first) {
          debug("Walking base \n");
          if(vpiHandle actual = vpi_handle(vpiActual, itx)) {
            debug("Actual found\n");
            bool constOnly;
            out += (visitExpr(actual, true, constOnly)).front();
          } else
            walker_error("Actual not found");
        } else {
          debug("Walking member hierarchy\n");
          //out += vpi_get_str(vpiName, itx);
          bool constOnly;
          out += getLastWord((visitExpr(itx, true, constOnly)).front());

        }
      }
      first = false;
      debug("Extracted at this point: " << out << endl);
    }
  } else { debug("Couldn't iterate through member actuals\n"); }
  return out;
}

tuple <bool, list <string>> visitOperation(vpiHandle h) {
  vpiHandle ops = vpi_iterate(vpiOperand, h);
  list <string> current;
  string out = "";
  bool constantsOnly = true;

  const int type = vpi_get(vpiOpType, h);
  debug("Operation type: " << UHDM::UhdmName((UHDM::UHDM_OBJECT_TYPE)type) << "(" << to_string(type) << ")" << endl);
  string symbol = "";
  switch(type) {
    // some of the operations cannot appear
    // within control expressions; and so are not included here
    case 3  : symbol += " !  "; break;
    case 4  : symbol += " ~  "; break;
    case 5  : symbol += " &  "; break;
    case 7  : symbol += " |  "; break;
    case 11 : symbol += " -  "; break;
    case 12 : symbol += " /  "; break;
    case 14 : symbol += " == "; break;
    case 15 : symbol += " != "; break;
    case 16 : symbol += " === "; break;
    case 17 : symbol += " !== "; break;
    case 18 : symbol += " >  "; break;
    case 19 : symbol += " >= "; break;
    case 20 : symbol += " <  "; break;
    case 21 : symbol += " <= "; break;
    case 22 : symbol += " << "; break;
    case 23 : symbol += " >> "; break;
    case 24 : symbol += " +  "; break;
    case 25 : symbol += " *  "; break;
    case 26 : symbol += " && "; break;
    case 27 : symbol += " || "; break;
    case 28 : symbol += " &  "; break;
    case 29 : symbol += " |  "; break;
    case 30 : symbol += " ^  "; break;
    case 32 : symbol += " :  "; break; 
    case 33 : symbol += " ,  "; break; //concat
    case 34 : symbol += "  { "; break;
    case 41 : symbol += " <<< "; break;
    case 42 : symbol += " >>> "; break;
    case 67 : symbol += " '( "; break;
    case 71 : symbol += " ,  "; break; //streaming left to right
    case 72 : symbol += " ,  "; break; //streaming right to left
    case 95 : symbol += " ,  "; break; 
    default : walker_error(" UNKNOWN_OP(" + to_string(type) + ") "); break;
  }

  debug("Found symbol\n");
  if(ops) {
    int opCnt = 0;
    //opening operand, if any
    if(type == 33)
      out += "{";
    else if(type == 71)
      out += "{>>{";
    else if(type == 72)
      out += "{<<{";
    else if(type == 3 || type == 4 || type == 5 || type == 7)
      out += symbol;

    //operation body
    while(vpiHandle oph = vpi_scan(ops)) {
      debug("Walking on operands\n");
      if(opCnt == 0) {
        if(type == 67) {
          debug("Finding typespec\n");
          bool constOnly;
          out += (visitExpr(oph, true, constOnly)).front();
        } 

        if(((const uhdm_handle *)oph)->type == UHDM::uhdmoperation) {
          out += "(";
          list <string> tmp;
          bool k_tmp;
          tie(k_tmp, tmp) = visitOperation(oph);
          out += tmp.front();
          out += ")";

          constantsOnly &= k_tmp; //Depends on whether subop is constantsOnly
        } else {
          bool conly;
          string tmp = (visitExpr(oph, true, conly)).front(); // true because we want to retain or resolve consts
          out += tmp;
          constantsOnly &= conly;
        }
        opCnt++;
      } else {
        if(opCnt == 1) {
          if(type == 32)
            out += " ? ";
          else if(type == 95)
            out += " inside { ";
          else out += symbol;
        }
        else {
          out += symbol;
        }
        opCnt++;

        if(((const uhdm_handle *)oph)->type == UHDM::uhdmoperation) {
          out += "(";
          list <string> tmp;
          bool k_tmp;
          tie(k_tmp, tmp) = visitOperation(oph);
          out += tmp.front();
          out += ")";
          constantsOnly &= k_tmp;
        } else {
          bool conly;
          string tmp = (visitExpr(oph, true, conly)).front();
          out += tmp;
          constantsOnly &= conly;
        }
      }

      vpi_release_handle(oph);
    }
    //closing operand
    if(type == 33 ||
        type == 34 || 
        type == 95 || 
        type == 71 || 
        type == 72)
      out += " }";

    if(constantsOnly)
      walker_warn("Operation is constants-only: " << out << endl);

    debug("Inserting Operation\n");
    current.push_front(out);

  } else {
    walker_error("Couldn't iterate on operands! Iterator type: " <<  UHDM::UhdmName((UHDM::UHDM_OBJECT_TYPE)((const uhdm_handle *)ops)->type) << endl);
  }

  vpi_release_handle(ops);
  return make_tuple(constantsOnly, current);
}

bool isOpTernary(vpiHandle h) {
  const int n = vpi_get(vpiOpType, h);
  if (n == vpiConditionOp) {
    return true;
  }
  return false;
}
void findMuxesInOperation(vpiHandle h, list <string> &buffer) {
  if (isOpTernary(h)) {
    debug("Ternary found in RHS\n");
    visitTernary(h, buffer);
  } else {
    if(vpiHandle operands = vpi_iterate(vpiOperand, h)) {
      while(vpiHandle operand = vpi_scan(operands)) {
        debug("Walking operand | Type: " << UHDM::UhdmName((UHDM::UHDM_OBJECT_TYPE)((uhdm_handle *)operand)->type) << endl);
        if(((uhdm_handle *)operand)->type == UHDM::uhdmoperation) {
          debug("\nOperand is an operation; recursing" << endl);
          findMuxesInOperation(operand, buffer);
        }
        vpi_release_handle(operand);
      }
      vpi_release_handle(operands);
    }
  }
}

// takes any RHS of an assignment and prints out operands
void printOperandsInExpr(vpiHandle h, unordered_set<string> *out, bool print=false) {
  assert(vpi_get(vpiType, h) == vpiExpr);
  UHDM::UHDM_OBJECT_TYPE h_type = (UHDM::UHDM_OBJECT_TYPE)((const uhdm_handle *)h)->type;
  debug("printOperandsInExpr | Type: " << UHDM::UhdmName(h_type) << endl);
  switch(((const uhdm_handle *)h)->type) {
    case UHDM::uhdmoperation :  { // need this despite having visitExpr 
      if(vpiHandle i = vpi_iterate(vpiOperand, h))
        while (vpiHandle op = vpi_scan(i))
          if(vpiHandle actual_op = vpi_handle(vpiActual, op)) 
            printOperandsInExpr(actual_op, out, print);
          else 
            printOperandsInExpr(op, out, print);
      else
        walker_error("No operands found for operation!");
      break;
    }
    case UHDM::uhdmtagged_pattern : {
      vpiHandle pat = vpi_handle(vpiPattern, h);
      bool constOnly;
      list <string> tmp = visitExpr(pat, false, constOnly);
      assert(tmp.size() <= 1);
      if(tmp.size() == 1) {
        out->insert(tmp.front());
        debug(tmp.front() << endl);
      }
      break;
    }
    default: {
      //if(vpiHandle actual_h = vpi_handle(vpiActual, h)) 
      //  h = actual_h;
      bool constOnly;
      list <string> tmp = visitExpr(h, false, constOnly);
      assert(tmp.size() <= 1);
      if(tmp.size() == 1) {
        out->insert(tmp.front());
        debug(tmp.front() << endl);
      }
      break;
    }
  }
  if(print) {
    debug("Operands in given expression:" << endl);
    for (auto const& ops: *out)
      { debug("\t" << ops << endl); }
  }
  return;
}

//
// takes in an operation and produces a list of strings
void visitTernary(vpiHandle h, list<string> &current) {
  //list <unordered_set <string>> csv; // has to be a list to preserve hierarchical parental order, for progressive coverage
  debug("Analysing ternary operation\n");
  bool first = true;
  if(vpiHandle i = vpi_iterate(vpiOperand, h)) {
    while (vpiHandle op = vpi_scan(i)) {
      debug("Walking "  << (first ? "condition" : "second/third") << " operand | Type: "  << ((const uhdm_handle *)op)->type << endl);

      switch(((const uhdm_handle *)op)->type) {
        case UHDM::uhdmoperation :
          {
            debug("Operation found in ternary\n");
            if(isOpTernary(op)) {
              visitTernary(op, current);
            }
            if(first) {
              list <string> out;
              bool k;
              tie(k, out) = visitOperation(op);
              // minor TODO  based on k, return a string (of the choice made in the tern)
              current.insert(current.end(), out.begin(), out.end());

              // this is for progressive coverage
              //UHDM::any* op_obj = (UHDM::any *)(((uhdm_handle *)op)->object);
              //debug("Finding dependenciesStr of an Expr:" << UHDM::vPrint(op_obj) << endl);
              //unordered_set <string> operands;
              //printOperandsInExpr(op, &operands, true);

              //unordered_set<string> depsSet;
              //for (auto &ref : operands) {
              //  debug("\tDependency on Operand: " << ref << endl);
              //  printRecursiveDependents(ref, &depsSet, true);
              //}
              //csv.push_back(depsSet);

              first = false;
            }
            break;
          }
        case UHDM::uhdmref_obj :
        case UHDM::uhdmpart_select :
        case UHDM::uhdmbit_select :
        case UHDM::uhdmconstant : 
        case UHDM::uhdmhier_path :
        case UHDM::uhdmparameter :
          if(first) {
            debug("Leaf found in ternary\n");
            /* For now, the below has the following issues that need to be fixed by Surelog:
             * Parameter values are not printed despite being resolved at this point
             * (Some) variables used within genBlk that are defined outside of the genBlk have genBlk in thier hier paths
             * Not all wires and logics print their fullNames
             * But once these are fixed, vPrint would be a far cleaner efficient way to print these
             */
            //UHDM::any* op_obj = (UHDM::any *)(((uhdm_handle *)op)->object);
            //current.push_back(UHDM::vPrint(op_obj));
            bool constOnly;
            list <string> tmp = visitExpr(op, true, constOnly);
            current.insert(current.end(), tmp.begin(), tmp.end());


            // TODO Do this for hier path (not operations) 
            //assert(tmp.size() == 1);
            //debug("Checking dependents on " << tmp.front() << endl);
            //unordered_set <string> depsSet;
            //printRecursiveDependents(tmp.front(), &depsSet, true);

            //// insert the ternary expression list, dependenciesStr will have been added if available
            //csv.push_back(depsSet);

            first = false;
          }
          break;
        default: 
          if(first) {
            walker_error("UNKNOWN type in ternary");
            first = false;
          }
          break;
      }
      vpi_release_handle(op);
    }
    vpi_release_handle(i);
  } else
    { debug("Couldn't iterate through operands" << endl); }

  debug("Saving ternaries...\n");
  return;
}

int evalExpr(vpiHandle h, bool& found) {
  debug("In evalExpr | type: " << UHDM::UhdmName((UHDM::UHDM_OBJECT_TYPE)((const uhdm_handle *)h)->type) << endl);

  // check in running constants
  if(char *c = vpi_get_str(vpiName, h)) {
    debug("Looking up: " << c << endl);
    auto range = running_const.find(c);
    if(range != running_const.end()) {
      debug("Found running_const\n");
      debug(c << " was found to be " << range->second << endl);
      found = true;
      return range->second;
    } else { debug("Not found in running_const\n"); }
  }

  // check in params
  if(char *c = vpi_get_str(vpiFullName, h)) {
    debug("Looking up: " << c << endl);
    auto range = params.find(c);
    if(range != params.end()) {
      debug("Found param\n");
      debug(c << " was found to be " << range->second << endl);
      found = true;
      return range->second;
    } else { debug("Not found in param\n"); }
  }

  // check for actual obj
  if(vpiHandle actual = vpi_handle(vpiActual, h)) {
    debug("Found actual; recursing" << endl);
    return evalExpr(actual, found);
  }

  // evaluate number
  if(const char *tmp = vpi_get_str(vpiDecompile, h)) {
    debug("Found decompile " << tmp << endl);
    s_vpi_value value;
    vpi_get_value(h, &value);
    found = true;
    if(value.format) {
      return value.value.integer;
    } else {
      //FARZAM: check this
      walker_warn("using decompile string: " << tmp << endl);
      return stoi(string(tmp));
    }
  }
  else {
    walker_error("No decompile!");
  }

  walker_error("Unable to resolve consant");
}

string evalOperation(vpiHandle h) {
  //Some supported evaluatable operations we support
  debug("In evalOperation | type: " << UHDM::UhdmName((UHDM::UHDM_OBJECT_TYPE)((const uhdm_handle *)h)->type) << endl);
  int result;
  int ops[3];
  int *op = ops;
  bool found;
  if((((const uhdm_handle *)h)->type) == UHDM::uhdmoperation) {
    if(vpiHandle opi = vpi_iterate(vpiOperand, h)) {
      while(vpiHandle oph = vpi_scan(opi)) {
        switch(((const uhdm_handle *)oph)->type) {
          case UHDM::uhdmoperation: 
            *op = stoi(evalOperation(oph));
            op++;
            break;
          case UHDM::uhdmsys_func_call:
            //FARZAM: fix this, maybe just call visitExpr on the entire op?
            walker_error("function call in evalOperation");
            op++;
            break;
          default:
            *op = evalExpr(oph, found);
            if(!found)
              walker_error("Did not evaluate the operation");
            op++;
            break;
        }
      }
      vpi_release_handle(opi);
    } else walker_error("Couldn't iterate on operands");

    const int type = vpi_get(vpiOpType, h);
    debug("Operation type in eval: " << UHDM::UhdmName((UHDM::UHDM_OBJECT_TYPE)type) << "(" << to_string(type) << ")" << endl);
    switch(type) {
      case 11 : result = ops[0] - ops[1];   break;
      case 12 : result = ops[0] / ops[1];   break;
      case 13 : result = ops[0] % ops[1];   break;
      case 14 : result = ops[0] == ops[1];  break;
      case 18 : result = ops[0] > ops[1];  break;
      case 19 : result = ops[0] >= ops[1];  break;
      case 20 : result = ops[0] < ops[1];  break;
      case 21 : result = ops[0] <= ops[1];  break;
      case 22 : result = ops[0] << ops[1];  break;
      case 23 : result = ops[0] >> ops[1];  break;
      case 24 : result = ops[0] + ops[1];   break;
      case 25 : result = ops[0] * ops[1];   break;
      case 26 : result = ops[0] && ops[1];   break;
      case 27 : result = ops[0] || ops[1];   break;
      case 32 : result = ops[0] ? ops[1] : ops[2]; break;
      default : walker_error("ERROR: new operation not evaluatable"); break;
    }
  } else if((((const uhdm_handle *)h)->type) == UHDM::uhdmsys_func_call) {
    bool constOnly;
    return (visitExpr(h, true, constOnly)).front();
  } else {
    result = evalExpr(h, found);
    if(!found)
      walker_error("Did not evaluate the operation");
  }
  debug("Done evaluating operation\n");

  return to_string(result);
}
// find the parameter/paramAssign name (not full name), and value (at elaboration)
// and store them in map params for later retrieval
void visitParameters(vpiHandle pi) {
  while (vpiHandle ps = vpi_scan(pi)) {
    if(const char *s = vpi_get_str(vpiName, ps)) {
      string pname = s;
      const UHDM::parameter *op_obj = (const UHDM::parameter *)(((uhdm_handle *)ps)->object);
      string_view pval = op_obj->VpiValue();

      int pstr = atoi(ltrim(pval, ':').data());
      params.insert(pair<string, int>(pname, pstr));
    }
  }
}

void visitParamAssignment(vpiHandle p) {
  while(vpiHandle h = vpi_scan(p)) {
    //debug("Found a handle " << ((const uhdm_handle *)h)->type << "\n");
    string name = "";
    if(vpiHandle l = vpi_handle(vpiLhs, h)) {
      name = vpi_get_str(vpiFullName, l);
      debug("\t" << name << endl);
      vpi_release_handle(l);
    } else {
      walker_error("Unable to find name of param\n");
    }
    if(vpiHandle r = vpi_handle(vpiRhs, h)) {
      //debug("Found a handle " << ((const uhdm_handle *)r)->type << "\n");
      switch(((const uhdm_handle *)r)->type) {
        case UHDM::uhdmconstant: {
          s_vpi_value value;
          vpi_get_value(r, &value);
          if(value.format) {
            debug("\t\tFound const assignment: " << to_string(value.value.integer) << endl);
            params.insert(pair<string, int>(name, value.value.integer));
          } else
            { walker_error("Unable to resolve constant\n"); }
          break;
        } 
        case UHDM::uhdmparameter: {
          map <string, int>::iterator it;
          it = params.find(name);
          if(it == params.end()) {
            walker_warn("Can't find definition of param: " << name << endl);
            params.insert(pair<string, int>(name, 0));
          } else {
            debug("Found existing param: " << it->second << endl);
            params.insert(pair<string, int>(name, it->second));
          }
          break;
        }
        case UHDM::uhdmoperation:  {
          walker_error("Unexpected operation in parameter assignment\n");
          break;
        }
        default: {
          walker_error("Didn't find a constant of param in param assignment\n");
          break;
        }
      }
      vpi_release_handle(r);
    } else {
      walker_error("Didn't find RHS of param assignment!!\n");
    }
  }
  return;
}


void visitTopModules(vpiHandle ti) {
  debug("Exercising iterator\n");
  while(vpiHandle th = vpi_scan(ti)) {
    debug("Top module handle obtained\n");
    if (vpi_get(vpiType, th) != vpiModule) {
      walker_error("Not a module\n");
      return;
    }

    //lambda for module visit
    function<void(vpiHandle, string)> visit =
      [&visit](vpiHandle mh, string depth) {

        string out_f;
        string defName;
        string objectName;
        if (const char* s = vpi_get_str(vpiDefName, mh)) {
          defName = s;
        }
        if (const char* s = vpi_get_str(vpiName, mh)) {
          if (!defName.empty()) {
            defName += " ";
          }
          objectName = string("(") + s + string(")");
        }
        string file = "";
        if (const char* s = vpi_get_str(vpiFile, mh))
          file = s;
        debug("Walking module: " + defName + objectName + "\n");// + 
        debug("\t File: " + file + ", line:" + to_string(vpi_get(vpiLineNo, mh)) + "\n");

        debug("****************************\n");
        debug("**** Precision coverage ****\n");
        debug("****************************\n");
        parse_module(mh, nullptr);
        // module_ds_map now has a struct with all the data structures
        debug("Done parsing module\n");

        unordered_set<string> parents;
        unordered_set<pair<string, int>, PairHash> covs;
        if(vpiHandle ports = vpi_iterate(vpiPort, mh)) {
          debug("**************\n");
          debug("Parsing ports:\n");
          debug("**************\n");
          while (vpiHandle p = vpi_scan(ports)) {
            if(vpi_get(vpiDirection, p) == 2) { // ignoring inout
              char *portName = vpi_get_str(vpiName, p);
              // ports have no fullName (perhaps because these are just pins?)
              if(portName) {
                cout << "Found output port " << portName << "; traversing...\n";
                vpiHandle lowConn = vpi_handle(vpiLowConn, p);
                string low_conn_full_name = vpi_get_str(vpiFullName, lowConn);
                cout << "Traverse function start:\n";

                traverse(low_conn_full_name, mh, 0, parents, covs, "");
              }
            }
          }
          debug("*** End of precision coverage ***\n");
          debug("Precision coverage dump:\n");
          print_unordered_set(covs, true, outputDir / "cp.csv");
        }

        // Accumulate variables:
        paramsAll.insert(params.begin(), params.end());
        params.clear();

        return;
      };
    visit(th, "");
    vpi_release_handle(th);
  }
  vpi_release_handle(ti);
  return;
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

  string out = "";

  debug("UHDM Elaboration...\n");
  UHDM::Serializer serializer;
  UHDM::ElaboratorListener* listener =
    new UHDM::ElaboratorListener(&serializer, false);
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
  outputDir = 
    fileSystem->toPlatformAbsPath(clp->getOutputDirId());
  debug("Output dir for *.sigs: "<< outputDir << endl);

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
    // Flat Module list:
    debug("Module List:\n");
    //      topmodule -- instance scope
    //        allmodules -- assign (ternares), always (if, case, ternaries)

    vpiHandle ti = vpi_iterate(UHDM::uhdmtopModules, the_design);
    if(ti) {
      debug("Walking uhdmtopModules\n");
      // The walk
      visitTopModules(ti);
    } else { debug("No uhdmtopModules found!\n"); }
  } else { debug("No design found!\n"); }

  cout << "\n\n\n*** Parsing Complete!!! ***\n\n\n";


  // Do not delete these objects until you are done with UHDM
  SURELOG::shutdown_compiler(compiler);
  delete clp;
  delete symbolTable;
  delete errors;
  return code;
}
