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

// UHDM
#include <uhdm/ElaboratorListener.h>
#include <uhdm/uhdm.h>
#include <uhdm/VpiListener.h>
#include <uhdm/vpi_uhdm.h>
#include <uhdm/ExprEval.h>

using namespace std;

#define DEBUG_PRINT 1

#if DEBUG_PRINT
#define debug(x) cout << x;
#else
#define debug(x)
#endif

void walker_warn(string s) {
  debug("WARN: " << s << endl);
}

void walker_error(string s) {
  cout << "ERROR: " << s << endl;
  exit(0);
}

// functions declarations
string visitbit_sel(vpiHandle);
string visithier_path(vpiHandle);
string visitindexed_part_sel(vpiHandle);
string visitpart_sel(vpiHandle);
list <string> visitCond(vpiHandle);
list <string> visitExpr(vpiHandle h, bool retainConsts, bool& constOnly);
tuple <bool, list <string>> visitOperation(vpiHandle);
void findTernaryInOperation(vpiHandle);
//void visitAssignmentForDependencies(vpiHandle, bool);
void visitAssignment(vpiHandle);
void visitBlocks(vpiHandle);
void visitTernary(vpiHandle, list<string> &);
void visitTopModules(vpiHandle);
void visitParamAssignment(vpiHandle);

string evalOperation(vpiHandle);
int evalExpr(vpiHandle, bool&);

// global variables
bool saveVariables = true; 
bool expand = true;
bool global_always_ff_flag = false;

// global data structures
list <unordered_set <string>> csvs;
list <string> all, ternaries, cases, ifs;  // for storing specific control expressions (see definition in main README.md)
list <int> nTernaries, nCases, nIfs; // incremental numbers for dbg
map <string, int> 
paramsAll, params; // for params, needed for supplanting in expressions expansions

unordered_set<string>
rhsOperands;
unordered_map<string, unordered_set<string>>
dependenciesStr;

//list of variables that are mux outputs;
unordered_map<string, string>
muxOutput;

// lhs2rhsMultiMap is map of lhsActual to all associated rhsActulOperands
multimap<string, string>
lhs2rhsMultiMap;

// set of registers or wires (supercedes nets, netsAll)
unordered_set<string>
regSet, wireSet;


// Define a hash function for pair
struct PairHash {
  template <class T1, class T2>
    size_t operator()(const pair<T1, T2>& p) const {
      auto hash1 = hash<T1>{}(p.first);
      auto hash2 = hash<T2>{}(p.second);
      return hash1 ^ hash2; // Combine the hash values
    }
};

filesystem::path outputDir;


// ancillary functions
static string_view ltrim(string_view str, char c) {
  auto pos = str.find(c);
  if (pos != string_view::npos) str = str.substr(pos + 1);
  return str;
}

// prints out discovered control expressions to file or stdout
void print_unordered_set(unordered_set<pair<string, int>, PairHash> &map, bool std = false, string fileName = "") {
  ofstream file;
  file.open(fileName, ios_base::out);
  if(file) {
    for (const auto& item : map) {
      if(std) {
        debug(item.first << " @depth= " << item.second << endl);
      }

      file << item.first << ", " << item.second << endl;
    }
  }
  return;
}

void print_list(unordered_map<string, unordered_set<string>> &map, bool f = false, string fileName = "", bool std = false) {
  ofstream file;
  if(f)
    file.open(fileName, ios_base::out);

  for (const auto& pair : map) {
    if(std) { debug(pair.first << ": " << endl); }
    if(f) file << pair.first << ": " << endl;;
    for (const string& item : pair.second) {
      if(std) { debug("\t" << item << endl); }
      if(f) file << "\t" << item << endl;
    }
  }

  if(f)
    file.close();

  return;
}

void print_list(unordered_set<string> &list, bool f = false, string fileName = "", bool std = false) {
  ofstream file;
  if(f)
    file.open(fileName, ios_base::out);

  for (auto const &i: list) {
    if(std)
      { debug(i << endl); }
    if(f)
      file << i << endl;
  }

  if(f)
    file.close();

  return;
}

void print_list(list<string> &list, bool f = false, string fileName = "", bool std = false) {
  ofstream file;
  if(f)
    file.open(fileName, ios_base::out);

  for (auto const &i: list) {
    if(std)
      { debug(i << endl); }
    if(f)
      file << i << endl;
  }

  if(f)
    file.close();

  return;
}

char* getAllButLastWord(const string& input) {
  // Convert the input string to a C-string
  char* tempStr = new char[input.length() + 1];
  strcpy(tempStr, input.c_str());

  // Find the last occurrence of '.'
  char* lastDot = strrchr(tempStr, '.');
  if (!lastDot) {
    debug("The input string does not contain '.'" << endl);
    delete[] tempStr;
    return nullptr;
  }

  // Terminate the string at the last dot to exclude the last word
  *lastDot = '\0';

  // Create a copy of the resulting string to return
  char* result = new char[strlen(tempStr) + 1];
  strcpy(result, tempStr);

  // Free the temporary string
  delete[] tempStr;

  return result;
}

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

// Farzam's coverage
struct data_structure {
  multimap <string, string>          modSubmodMap;
  unordered_map <string, tuple<string, vpiHandle>>
    net_submodOut; // search with net, gives submodOut
  multimap <string, string>          submodIn_net;
  // multimap because submodIn can be driven by an operation of nets
  unordered_map<string, unordered_set<string>> net2driver;
  unordered_map<string, unordered_set<string>> net2sel; // net to select signal (implies net is a muxOutput)
  list <string>                           moduleInputs;
  list <string>                           regs;
  list <string>                           running_cond_str;
  vpiHandle                                         parent;

};

map <string, int>           running_const;

void print_ds(string fileName, data_structure& ds) {
  ofstream file;
  file.open(fileName, ios_base::app);
  for (auto const& i : ds.modSubmodMap)
    file << i.first << " -- " << i.second << endl;

  for (auto const& i : ds.net_submodOut)
    file << i.first << " <> " << get<0>(i.second) << endl;

  for (auto const& i : ds.submodIn_net)
    file << i.first << " <> " << i.second << endl;

  for (auto const& i : ds.net2driver) {
    file << i.first << " <-\n";
    for (auto const& el : i.second)
      file << "\t" << el << endl;
  }

  for (auto const& i : ds.net2sel) {
    file << i.first << " ??\n";
    for (auto const& el : i.second)
      file << "\t" << el << endl;
  }

  for (auto const& i : ds.regs)
    file << "Reg:" << i << endl;

  for (auto const& i : ds.moduleInputs)
    file << "Input:" << i << endl;

  return;
}



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

  if(name == nullptr)
    walker_error("Name can't be found\n");

  //if already parsed, do not parse again
  if(!genScope && module_ds_map.find(name) != module_ds_map.end()) {
    debug("Module already parsed, so returing\n");
    return;
  }

  debug("\n\nparse_module: " << name << endl);

  data_structure ds;
  ds.parent = p_in;
  // params resolutoin
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

  //debug("\nFinal list of params:\n");
  //map<string, int>::iterator pitr;
  //for (pitr = params.begin(); pitr != params.end(); ++pitr)
  //  debug(pitr->first << " = " << pitr->second << endl);

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
      if(vpiHandle c = vpi_handle(vpiCondition, always)) {
        cond_str = visitExpr(c, true, constOnly);
      } else
        walker_error("No condition found in case_stmt");

      ds.running_cond_str.push_front(cond_str.front());
      debug("Finding case_items\n");
      if(vpiHandle items = vpi_iterate(vpiCaseItem, always)) {
        while(vpiHandle item = vpi_scan(items)) {
          bool rcs_active = false, dummy; // running_cond_str active
          debug("Case item processing\n");
          // the below is for (case_cond == case_item_expr)
          // MAJOR TODO -- like running_cond_str, create a running_case_str which shouldn't be running, but rather a single compare expression 
          //if(vpiHandle exprs = vpi_iterate(vpiExpr, item)) {
          //  while(vpiHandle expr = vpi_scan(exprs)) {
          //    debug("Case item expression found\n");
          //    list <string> match;
          //    if(((const uhdm_handle *)expr)->type == UHDM::uhdmoperation) {
          //      tie(dummy, match) = visitOperation(expr); // rcs used dummily
          //    } else {
          //      match = visitExpr(expr, true, dummy); // rcs used dummily
          //    }
          //    if(!constOnly && !rcs_active) { 
          //      // the && ! is because when using fall through case-items, the running condition string will be wrong
          //      ds.running_cond_str.push_front(" ( " + cond_str.front() + " == " + match.front() + " ) ");
          //      debug("Case item expression added\n");
          //      rcs_active = true;
          //    }
          //    else rcs_active = false;
          //  }
          //}

          // will usually be an assignment
          debug("running_cond_str: " << (!ds.running_cond_str.empty() ? ds.running_cond_str.front() : "NIL"));
          parseAlways(item, ds);
          //if(rcs_active)
          //  ds.running_cond_str.pop_front();
        }
      }
      // remove this if you're changing case-cond representation
      ds.running_cond_str.pop_front();
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

string compose_running_str(string s, data_structure &ds) {
  string result;
  bool first = true;
  if(!ds.running_cond_str.empty())
    for(auto const& el : ds.running_cond_str) {
      if(first)
        first = false;
      else 
        result += " & ";
      result += el;
    }
  else return s;

  if(!s.empty())
    result += " & " + s;

  return result;
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

string getLastWord(const string &input) {
  // Find the position of the last '.'
  size_t lastDotPos = input.rfind('.');

  // If there is no '.' in the string, return the original string
  if (lastDotPos == string::npos) {
    return input;
  }

  // Return the substring up to (but not including) the last '.'
  return input.substr(lastDotPos+1, input.length());
}

bool removeLastWordOrSel(const string &input, string &parent, string &last) {
  //debug("Removing last word from " << input << endl);
  // find the position of the last '.'
  size_t posDot = input.find_last_of('.');
  size_t posBracket = input.find_last_of('[');
  size_t pos;
  if(posDot != string::npos && posBracket != string::npos)
    pos = max(posDot, posBracket);
  else if (posDot != string::npos) 
    pos = posDot;
  else if (posBracket != string::npos)
    pos = posBracket;
  else {
    // if there is no '.' or '[' in the string, return the original string
    debug("No '.' or '[' in the string\n");
    return false; // parent and last are empty
  }

  // return the substring up to (but not including) the last '.'
  parent = input.substr(0, pos);
  last = input.substr(pos+1, input.length());
  //debug("Removed; result: " << parent << endl);
  return true;
}

// Function to find the penultimate word in a string separated by '.'
char* getPenultimateWord(const string& input) {
  // Convert the input string to a C-string
  char* tempStr = new char[input.length() + 1];
  strcpy(tempStr, input.c_str());

  // Find the first occurrence of '.' from the end
  char* lastDot = strrchr(tempStr, '.');
  if (!lastDot) {
    debug("The input string does not have enough words separated by '.'" << endl);
    delete[] tempStr;
    return nullptr;
  }

  // Terminate the string at the last dot
  *lastDot = '\0';

  // Find the second last occurrence of '.'
  char* secondLastDot = strrchr(tempStr, '.');
  char* penultimateWord = secondLastDot ? secondLastDot + 1 : tempStr;

  // Free the temporary string
  delete[] tempStr;

  return penultimateWord;
}

//string fetchSuperModuleNet(vpiHandle parent, string submodIn) {
//  assert((UHDM::UHDM_OBJECT_TYPE)((const uhdm_handle *)parent)->type == UHDM::uhdmmodule_inst);
//  if(char * name = vpi_get_str(vpiName, parent)) {
//    data_structure ds = module_ds_map[name];
//    // TOD make this nested lookup -- might not help
//    auto range = ds.submodIn_net.equal_range(submodIn);
//    if(range.first == range.second)
//      debug("Supermodule net corresponding to input not found!\n");
//    for (auto it = range.first; it != range.second; ++it) {
//
//      debug("Did not find the connection to the input port in the supermodule\n");
//      assert (false);
//    }
//  } else 
//    debug("Unable to determine name of parent\n");
//  return "DNF";
//}

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

inline bool matchesPattern(const string& test, const string& prefix) {
  // Check if the text starts with the prefix
  if (test.substr(0, prefix.size()) == prefix) {
    // Check if the character immediately following the prefix is '.' or '['
    char nextChar = test[prefix.size()];
    if (nextChar == '.' || nextChar == '[') {
      return true;
    }
  }
  return false;
}

vector<string> findMatchingStrings(const data_structure &ds, const string &prefix, string indent) {
  vector<string> matchingValues;

  for (const auto &pair : ds.net_submodOut) {
    if (matchesPattern(pair.first, prefix)) {
      debug(indent << "\tMatching source for: " << pair.first << " <- " << get<0>(pair.second) << endl);
      matchingValues.push_back(pair.first);
    }
  }

  for (const auto &pair : ds.net2driver) {
    if (matchesPattern(pair.first, prefix)) {
      debug(indent << "\tMatching driver for: " << pair.first << endl);
      debug(indent << "\tCandidates:\n");
      for (const auto& i : pair.second) {
        debug(indent << "\t\t" << i << endl);
        matchingValues.push_back(i);
      }
    }
  }

  return matchingValues;
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
    unordered_set sels = ds.net2sel[net]; // resume from here
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

    //char *inst_name = getPenultimateWord(source->second);
    //string inst_name = get<1>(source->second);
    //debug(indent << "Net's source is from module: " << inst_name << endl);
    //char* cstrManual = new char[inst_name.size() + 1]; // +1 for the null terminator
    //strcpy(cstrManual, inst_name.c_str());
    //vpiHandle submodule = vpi_handle_by_name(cstrManual, inst);
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

// visitor functions for different node types
//string visitref_obj(vpiHandle h) {
//  string out = "";
//  if(vpiHandle actual = vpi_handle(vpiActual, h)) {
//    debug("Actual type of ref_obj: " << 
//      UHDM::UhdmName((UHDM::UHDM_OBJECT_TYPE)((const uhdm_handle *)actual)->type) << endl;
//    switch(((const uhdm_handle *)actual)->type) {
//      case UHDM::uhdmparameter : 
//        out = (visitExpr(actual, true)).front(); //TODO
//        break;
//      case UHDM::uhdmconstant:
//      case UHDM::uhdmenum_const :
//      case UHDM::uhdmenum_var :
//      default :
//        debug("Default actual object\n");
//        if (const char* s = vpi_get_str(vpiFullName, actual))
//          out += s;
//        else if(const char *s = vpi_get_str(vpiName, actual))
//          out += s;
//        else out += "UNKNOWN";
//        debug("(Full)Name: " << out << endl);
//        break;
//    }
//  } else {
//    debug("Walking not actual reference object); type: " << 
//      UHDM::UhdmName((UHDM::UHDM_OBJECT_TYPE)((const uhdm_handle *)h)->type) << endl;
//    if (const char* s = vpi_get_str(vpiFullName, h)) {
//      debug("FullName available " << s << endl);
//      out += s;
//    } else if(const char *s = vpi_get_str(vpiName, h)) {
//      debug("FullName unavailable\n");
//      out += s;
//    } else debug("Neither FullName, nor Name available\n");
//
//  }
//  return out;
//}

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
      if(char *c = vpi_get_str(vpiFullName, h))
        out.push_back(c);
      else walker_error("UNKNOWN node at leaf; type: " +
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

/*
   int search_width(vpiHandle h) {
   switch(((const uhdm_handle *)h)->type) {
   case UHDM::uhdmbit_select: return 1;
   case UHDM::uhdmpart_select: {
   int left=0, right=0;
   vpiHandle lrh = vpi_handle(vpiLeftRange, h);
   if(lrh) {
   left = evalExpr(lrh, found);
   } else debug("Left range UNKNOWN); type: " <<
   UHDM::UhdmName((UHDM::UHDM_OBJECT_TYPE)(((const uhdm_handle *)lrh)->type)) << endl;
   vpiHandle rrh = vpi_handle(vpiRightRange, h);
   if(rrh) {
   right = evalExpr(rrh, found);
   } else debug("Right range UNKNOWN); type: " <<
   UHDM::UhdmName((UHDM::UHDM_OBJECT_TYPE)(((const uhdm_handle *)rrh)->type)) << endl;
   vpi_release_handle(rrh);
   vpi_release_handle(lrh);
   debug("Operand width: " << to_string(right-left));
   return right - left;
   }
   case UHDM::uhdmhier_path:
   case UHDM::uhdmref_obj: {
   string name = visitref_obj(h);
   debug("Finding width of " << name << endl);
   auto match = find_if(netsCurrent.cbegin(), netsCurrent.cend(),
   [&] (const vars& s) {
   return s.name == name;
   });
   if(match != netsCurrent.cend()) {
   debug("Operand width: " << *(match->width) << endl);
   return *(match->width);
   } else {
   debug("Couldn't find the width of: " << name << endl);
   return -1;
   }
   }
   case UHDM::uhdmconstant:
   case UHDM::uhdmparameter:
   return -1;
   default: 
   debug("Operand width: UNKNOWN\n");
   debug("Operand type: " <<  UHDM::UhdmName((UHDM::UHDM_OBJECT_TYPE)(((const uhdm_handle *)h)->type)) << endl);
   return -1;
   }
   return -1;
   }
 */

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
    default : symbol += " UNKNOWN_OP(" + to_string(type) + ") " ; break;
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
          //if(vpiHandle actual = vpi_handle(vpiActual, oph))
          //  if(((const uhdm_handle *)actual)->type != UHDM::uhdmparameter &&
          //      ((const uhdm_handle *)actual)->type != UHDM::uhdmconstant)
          //    constantsOnly = false;
          //if(((const uhdm_handle *)oph)->type != UHDM::uhdmparameter &&
          //    ((const uhdm_handle *)oph)->type != UHDM::uhdmconstant) {
          //  constantsOnly = false;
          //}
        }
        opCnt++;
      } else {
        if(opCnt == 1) 
          if(type == 32)
            out += " ? ";
          else if(type == 95)
            out += " inside { ";
          else out += symbol;
        else    
          out += symbol;
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
          //if(vpiHandle actual = vpi_handle(vpiActual, oph))
          //  if(((const uhdm_handle *)actual)->type != UHDM::uhdmparameter &&
          //      ((const uhdm_handle *)actual)->type != UHDM::uhdmconstant)
          //    constantsOnly &= false;

          //if(((const uhdm_handle *)oph)->type != UHDM::uhdmparameter &&
          //    ((const uhdm_handle *)oph)->type != UHDM::uhdmconstant) {
          //  constantsOnly &= false;
          //}
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
      { debug("Operation is constants-only: " << out << endl); }
    debug("Inserting Operation\n");
    current.push_front(out);

  } else {
    debug("Couldn't iterate on operands! Iterator type: " <<  UHDM::UhdmName((UHDM::UHDM_OBJECT_TYPE)((const uhdm_handle *)ops)->type) << endl);
  }

  vpi_release_handle(ops);
  return make_tuple(constantsOnly, current);
}

//list <string> visitCond(vpiHandle h) {
//  /* Condition can be any of:
//     \_bit_select:
//     \_constant:             // ignore
//     \_hier_path:
//     \_indexed_part_select:  // perhaps only in case conditions
//     \_operation:
//     \_ref_obj:
//   */
//
//  debug("Walking condition); type: " << 
//    UHDM::UhdmName((UHDM::UHDM_OBJECT_TYPE)((const uhdm_handle *)h)->type) << endl;
//  list <string> current;
//  switch(((const uhdm_handle *)h)->type) {
//    case UHDM::uhdmpart_select :
//    case UHDM::uhdmindexed_part_select :
//    case UHDM::uhdmbit_select :
//    case UHDM::uhdmref_obj :
//    case UHDM::uhdmconstant :
//    case UHDM::uhdmparameter : 
//    case UHDM::uhdmhier_path :
//      debug("Leafs found\n");
//      bool constOnly;
//      current = visitExpr(h, true, constOnly); //need to retain constants so condition gets printed fully
//      break;
//    case UHDM::uhdmoperation :
//      debug("Operation found\n");
//      bool k;
//      tie(k, current) = visitOperation(h);
//      break;
//    default: 
//      debug("UNKNOWN type found\n");
//      break;
//  }
//  return current;
//}
//
//void visitIfElse(vpiHandle h) {
//  list <string> out;
//  debug("Found IfElse/If\n");
//  if(vpiHandle c = vpi_handle(vpiCondition, h)) {
//    debug("Found condition\n");
//    out = visitCond(c);
//    vpi_release_handle(c);
//  } else debug("No condition found\n");
//  debug("Saving to list: \n");
//  print_list(out);
//
//  list <string> tmp(out);
//  ifs.insert(ifs.end(), out.begin(), out.end());
//  all.insert(all.end(), tmp.begin(), tmp.end());
//
//  if(vpiHandle s = vpi_handle(vpiStmt, h)) {
//    debug("Found statements\n");
//    visitBlocks(s);
//    vpi_release_handle(s);
//  } else debug("Statements not found\n");
//  return;
//}
//
//void visitCase(vpiHandle h) {
//  list <string> out;
//  if(vpiHandle c = vpi_handle(vpiCondition, h)) {
//    debug("Found condition\n");
//    out = visitCond(c);
//    vpi_release_handle(c);
//  } else debug("No condition found!\n");
//  cases.insert(cases.end(), out.begin(), out.end());
//  all.insert(all.end(), out.begin(), out.end());
//  debug("Parsing case item); type: " << 
//    UHDM::UhdmName((UHDM::UHDM_OBJECT_TYPE)((const uhdm_handle *)h)->type) << endl;
//  vpiHandle newh = vpi_iterate(vpiCaseItem, h);
//  if(newh) {
//    while(vpiHandle sh = vpi_scan(newh)) {
//      debug("Found case item); type: " << 
//        UHDM::UhdmName((UHDM::UHDM_OBJECT_TYPE)((const uhdm_handle *)sh)->type) << endl;
//      visitBlocks(sh);
//      vpi_release_handle(sh);
//    }
//    vpi_release_handle(newh);
//  } else debug("Statements not found\n");
//  return;
//}

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

//void visitAssignmentForDependencies(vpiHandle h, bool isProcedural = false) {
//  // TODO: if LHS is like a[i], or {a,...} what to do?
//
//  // clear rhsOperands -- once per assignment
//  rhsOperands.clear();
//
//  debug("Walking assignment for dependency generation\n");
//  if(vpiHandle rhs = vpi_handle(vpiRhs, h)) {
//    /* In BlackParrot (at least), RHS in an assignment can only be:
//     * Type: bit_select
//     * Type: constant
//     * Type: hier_path
//     * Type: indexed_part_select    
//     * Type: part_select
//     * Type: ref_obj
//     * Type: var_select
//     * Type: operation           
//     */
//    UHDM::UHDM_OBJECT_TYPE rhs_type = (UHDM::UHDM_OBJECT_TYPE)((const uhdm_handle *)rhs)->type;
//    debug("Walking RHS | Type: "
//      << UHDM::UhdmName(rhs_type) << endl;
//
//    printOperandsInExpr(rhs, &rhsOperands); // updates rhsOperands
//
//    if (vpiHandle lhs = vpi_handle(vpiLhs, h)) {
//      /* In BP, LHS can only be:
//       * Type: bit_select                
//       * Type: logic_net
//       * Type: hier_path                 
//       * Type: indexed_part_select       
//       * Type: part_select               
//       * Type: ref_obj                   
//       * Type: var_select                
//       * Type: operation                 
//       */
//      debug("Walking LHS | Type: "
//        << UHDM::UhdmName((UHDM::UHDM_OBJECT_TYPE)((const uhdm_handle *)lhs)->type) << endl;
//      string lhsStr;
//      int lhsType = (UHDM::UHDM_OBJECT_TYPE)((const uhdm_handle *)lhs)->type;
//      if (lhsType == UHDM::uhdmoperation) {
//        // if LHS is an operation, it's a concat operation
//        assert((const int)vpi_get(vpiOpType, lhs) == vpiConcatOp);
//        // TODO how to use this?
//      } else {
//        if(((uhdm_handle *)lhs)->type == UHDM::uhdmhier_path)
//          lhsStr = visithier_path(lhs);
//        else {
//          assert(
//              lhsType == UHDM::uhdmbit_select ||
//              lhsType == UHDM::uhdmpart_select ||
//              lhsType == UHDM::uhdmlogic_net ||
//              lhsType == UHDM::uhdmindexed_part_select ||
//              lhsType == UHDM::uhdmref_obj ||
//              lhsType == UHDM::uhdmvar_select);
//          list <string> tmp = visitExpr(lhs);
//          assert(tmp.size() == 1);
//          lhsStr = tmp.front();
//          // TODO when you search for a variable that has been part-assigned
//          // you will not succeed in the search
//          // Should you instead save the variable without the part_sel?
//        }
//
//        // PS: this is for progressive coverage only 
//        // TODO move that to lhs2rhsMultiMap
//        dependenciesStr.emplace(lhsStr, rhsOperands);
//        debug("Dependencies:"<< endl << lhsStr << endl);
//
//        // TODO we are potentially misrepresenting (on lhs):
//        //   part-sel, bit-sel, etc. (Retain hier map?)
//        //   They probably cannot be matched with variable names later
//        for (const auto& value: rhsOperands) {
//          lhs2rhsMultiMap.insert({lhsStr, value});
//          debug("\t<< " << value << endl);
//        }
//
//        if(isProcedural) {
//          regSet.insert(lhsStr);
//          debug("LHS is procedural\n");
//        } else {
//          wireSet.insert(lhsStr);
//          debug("LHS is continuous\n");
//        }
//
//        if(rhs_type == UHDM::uhdmoperation) {
//          // TODO function to return mux select string based on assignment
//          list <string> select_sigs;
//          findMuxesInOperation(rhs, select_sigs);
//          if(!select_sigs.empty()) {
//            debug("LHS is muxOutput\n");
//            for(auto const& el : select_sigs)
//              muxOutput.insert({lhsStr, el});
//          } else debug("LHS is not muxOutput\n");
//        } else {
//          debug("Not found operation in assigment\n");
//        }
//
//        rhsOperands.clear();
//      }
//      vpi_release_handle(lhs);
//    } else
//      debug("Assignment without LHS handle\n");
//
//    vpi_release_handle(rhs);
//  } else 
//    debug("Assignment without RHS handle\n");
//}
//
//void visitAssignment(vpiHandle h) {
//  // both vpiContAssign and vpiAssign
//  debug("Walking assignment | file: "
//    << vpi_get_str(vpiFile, h) << ":" << vpi_get(vpiLineNo, h) << endl;
//  if(vpiHandle rhs = vpi_handle(vpiRhs, h)) {
//    debug("Walking RHS | Type: "
//      << UHDM::UhdmName((UHDM::UHDM_OBJECT_TYPE)((const uhdm_handle *)rhs)->type) << endl;
//    if(((uhdm_handle *)rhs)->type == UHDM::uhdmoperation) {
//      debug("Walking operation" << endl);
//      list <string> buffer;
//      findMuxesInOperation(rhs, buffer);
//    } else
//      debug("Not an operation on the RHS" << endl);
//
//    vpi_release_handle(rhs);
//  } else {
//    debug("No RHS handle on the assignment" << endl);
//  }
//  return;
//}
//
//void visitBlocks(vpiHandle h) {
//  // always_ff, always_comb, always and possibly others are all recognized here
//  debug("Block type: " 
//    << UHDM::UhdmName((UHDM::UHDM_OBJECT_TYPE)((const uhdm_handle *)h)->type) << endl;
//  switch(((const uhdm_handle *)h)->type) {
//    case UHDM::uhdmcase_items : 
//    case UHDM::uhdmbegin : {
//      vpiHandle i;
//      i = vpi_iterate(vpiStmt,h);
//      while (vpiHandle s = vpi_scan(i) ) {
//        visitBlocks(s);
//        vpi_release_handle(s);
//      }
//      vpi_release_handle(i);
//      break;
//    }
//    case UHDM::uhdmstmt :
//      if(((const uhdm_handle *)h)->type == UHDM::uhdmevent_control)  {
//        debug("Found event control\n");
//        visitBlocks(h);
//      } else
//        debug("UNRECOGNIZED uhdmstmt type: " << UHDM::UhdmName((UHDM::UHDM_OBJECT_TYPE)((const uhdm_handle *)h)->type) << endl);
//      break;
//    case UHDM::uhdmcase_stmt :
//      debug("Case statement found\n");
//      visitCase(h);
//      break;
//    case UHDM::uhdmif_stmt :
//    case UHDM::uhdmelse_stmt : 
//    case UHDM::uhdmif_else :
//      debug("If/IfElse statement found\n");
//      visitIfElse(h);
//      if(vpiHandle el = vpi_handle(vpiElseStmt, h)) {
//        debug("Else statement found\n");
//        visitIfElse(el);
//      } else debug("Didn't find else statement\n");
//      break;
//    case UHDM::uhdmalways : {
//      vpiHandle newh = vpi_handle(vpiStmt, h);
//      visitBlocks(newh);
//      vpi_release_handle(newh);
//      break;
//    }
//    case UHDM::uhdmassignment : {
//      // uses the same visitor for contAssign
//      debug("Assignment found | Type: " << (global_always_ff_flag ? "Procedural" : "Continuous") << endl);
//      //visitAssignmentForDependencies(h, global_always_ff_flag); // this helps distinguish reg assignment from always_comb's wire assignment
//      visitAssignment(h);
//      break;
//    }
//    default :
//      if(vpiHandle newh = vpi_handle(vpiStmt, h)) {
//        debug("UNKNOWN type; but statement found inside\n");
//        visitBlocks(newh);
//      } else {
//        debug("UNKNOWN type; skipping processing this node\n");
//        //Accommodate all cases eventually
//      }
//      break;
//  }
//  return;
//}
//
//void findTernaryInOperation(vpiHandle h) {
//  string out = "";
//  debug("Checking if operand is ternary\n");
//  if(((uhdm_handle *)h)->type == UHDM::uhdmoperation) {
//    const int nk = vpi_get(vpiOpType, h);
//    //debug("Type " << UHDM::UhdmName((UHDM::UHDM_OBJECT_TYPE)nk) << "\n");
//    if(nk == 32) {
//      debug("An operand is ternary\n");
//      list <string> buffer;
//      visitTernary(h, buffer); // TODO WRONG
//    }
//
//  }
//  return;
//}

//void printRecursiveDependents(string ref, unordered_set<string> *out, bool print=false) {
//  if (dependenciesStr.find(ref) != dependenciesStr.end()) {
//    unordered_set <string> deps = dependenciesStr[ref];
//    for (auto const& it: deps) {
//      debug("\t\t<< " << it << endl);
//      printRecursiveDependents(it, out);
//    }
//    out->insert(deps.begin(), deps.end());
//  } else
//    debug("\t\tDependents not found for: " << ref << endl);
//
//  out->insert(ref);
//
//  if(print)
//    for (auto const& it: *out)
//      debug("\t\tSo, final list of dependents: " << it << endl);
//  return;
//}
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
  print_list(current);
  ternaries.insert(ternaries.end(), current.begin(), current.end());
  //csvs.insert(csvs.end(), csv.begin(), csv.end());
  all.insert(all.end(), current.begin(), current.end());
  return;
}

int evalExpr(vpiHandle h, bool& found) {
  debug("In evalExpr | type: " << UHDM::UhdmName((UHDM::UHDM_OBJECT_TYPE)((const uhdm_handle *)h)->type) << endl);

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

  if(vpiHandle actual = vpi_handle(vpiActual, h)) {
    debug("Found actual; recursing" << endl);
    return evalExpr(actual, found);
  }
  else  {
    if(const char *tmp = vpi_get_str(vpiDecompile, h)) {
      debug("Found non-actual " << tmp << endl);
      s_vpi_value value;
      vpi_get_value(h, &value);
      found = true;
      if(value.format) {
        return value.value.integer;
      } else
        return stoi(string(tmp));
    }
    else {
      //walker_error("Actual doesn't exists, no decompile"); // MAJOR TODO happens when parsing pipe_mem 
      // "~/zynq-farm/zynq-parrot/cosim/import/black-parrot/bp_common/src/v/bp_tlb.sv" +211
      return 0;
    }
  }

  walker_error("Unable to resolve consant");
  return 0;
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
          case UHDM::uhdmsys_func_call :
            *op = 0; //TODO fix this
            op++;
            break;
          default:
            *op = evalExpr(oph, found);
            if(!found) {
              //walker_error("Did not really evaluate the function, check `found`");
            }
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
      walker_error("Did not really evaluate the function, check `found`");
  }
  debug("Done evaluating operation\n");

  return to_string(result);
}

//int width(vpiHandle h, int *ptr) {
//  //debug("Calculating width\n");
//  vpiHandle ranges;
//  string out;
//  int dims=0;
//  int *w;
//  w = ptr;
//  if((ranges = vpi_iterate(vpiRange, h))) {
//    //debug("Range found\n");
//    while (vpiHandle range = vpi_scan(ranges) ) {
//      if(dims < 4) {
//        //debug("New dimension\n");
//        dims++;
//        vpiHandle lh = vpi_handle(vpiLeftRange, range);
//        vpiHandle rh = vpi_handle(vpiRightRange, range);
//        *w = evalExpr(lh) - evalExpr(rh) + 1;
//        debug("\t\tRange: " << *w << endl);
//        w++;
//        vpi_release_handle(lh);
//        vpi_release_handle(range);
//      } else walker_error("Dimension overflow!");
//    }
//  } else {
//    //meaning either a bit or an unknown range
//    debug("\t\tRange: 1\n");
//    *w = 1;
//    dims++;
//  }
//  vpi_release_handle(ranges);
//  return dims;
//}
//
//void visitPorts(vpiHandle h) {
//  debug("Walking ports\n");
//  while (vpiHandle p = vpi_scan(h)) {
//    debug(vpi_get_str(vpiName, p) << endl);
//    if(vpi_get(vpiDirection, p) == 2) {
//      debug("\tOutput port\n");
//      vpiHandle lowConn = vpi_handle(vpiLowConn, p);
//      debug("\t\tLow conn name: " << vpi_get_str(vpiFullName, lowConn) << endl);
//      vpiHandle highConn = vpi_handle(vpiHighConn, p);
//      unordered_set<string> parents;
//      // LowConn is always ref_obj (IO port)
//      if(highConn) {
//        debug("\t\tHigh conn type: " << UHDM::UhdmName((UHDM::UHDM_OBJECT_TYPE)((const uhdm_handle *)highConn)->type));
//        if(((const uhdm_handle *)highConn)->type == UHDM::uhdmref_obj) {
//          debug(" | Ref name: " << vpi_get_str(vpiFullName, highConn));
//        } else if(((const uhdm_handle *)highConn)->type == UHDM::uhdmoperation) {
//          const int type = vpi_get(vpiOpType, highConn);
//          debug(" | Op type: " << UHDM::UhdmName((UHDM::UHDM_OBJECT_TYPE)type) << "(" << to_string(type) << ")");
//        }
//      }
//      debug(endl);
//      traverse(lowConn, 0, parents, covs);
//    } else if(vpi_get(vpiDirection, p) == 1) {
//      debug("\tInput port; ignored\n");
//      // TODO check if this is included in vpiVaribales/vpiNet
//    }
//  }
//}

//void visitNets(vpiHandle i, bool net) {
//  debug("Walking variables\n");
//  while (vpiHandle h = vpi_scan(i)) {
//    string out = "";
//    switch(((const uhdm_handle *)h)->type) {
//      case UHDM::uhdmstruct_var :
//      case UHDM::uhdmstruct_net : {
//        //debug("Finding width of struct\n");
//        string base = vpi_get_str(vpiFullName, h);
//        if(vpiHandle ts = vpi_handle(vpiTypespec, h)) {
//          //debug("Finding Typespec\n");
//          if(vpiHandle tsi = vpi_iterate(vpiTypespecMember, ts)) {
//            //debug("Found TypespecMember\n");
//            while(vpiHandle tsm = vpi_scan(tsi)) {
//              //debug("Iterating\n");
//              vpiHandle tsmts = vpi_handle(vpiTypespec, tsm);
//              int t = vpi_get(vpiNetType, tsmts);
//              struct vars tmp;
//              tmp.type = t == 48 ? "Reg" :
//                "Wire(" + UHDM::UhdmName((UHDM::UHDM_OBJECT_TYPE)((const uhdm_handle *)tsmts)->type) + ")";
//              tmp.name = base + ".";
//              tmp.name += vpi_get_str(vpiName, tsm);
//              tmp.dims = width(tsmts, tmp.width);
//              netsCurrent.push_back(tmp);
//              debug("\t" << tmp.name << endl);
//            }
//          }
//        }
//        break;
//      }
//      default: {
//        int t = vpi_get(vpiNetType, h);
//        struct vars tmp;
//        // TODO use bool net for tmp.type
//        tmp.type = t == 48 ? "Reg" :
//          "Wire(" + UHDM::UhdmName((UHDM::UHDM_OBJECT_TYPE)((const uhdm_handle *)h)->type) + ")";
//        tmp.name = vpi_get_str(vpiFullName, h);
//        debug("\t" << tmp.name << endl);
//        tmp.dims = width(h, tmp.width);
//        netsCurrent.push_back(tmp);
//        break;
//      }
//    }
//    vpi_release_handle(h);
//  }
//  debug("No more nets\n");
//  vpi_release_handle(i);
//  return;
//}
//
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
      debug("Unable to find name of param\n");
      name = "UNKNOWN";
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
            { debug("Unable to resolve constant\n"); }
          break;
        } 
        case UHDM::uhdmparameter: {
          map <string, int>::iterator it;
          it = params.find(name);
          if(it == params.end()) {
            debug("Can't find definition of param: " << name << endl);
            params.insert(pair<string, int>(name, 0));
          } else {
            debug("Found existing param: " << it->second << endl);
            params.insert(pair<string, int>(name, it->second));
          }
          break;
        }
        case UHDM::uhdmoperation:  {
          debug("Unexpected operation in parameter assignment\n");
        }
        default: {
          debug("Didn't find a constant of param in param assignment\n");
          break;
        }
      }
      vpi_release_handle(r);
    } else {
      debug("Didn't find RHS of param assignment!!\n");
    }
  }
  return;
}


void visitTopModules(vpiHandle ti) {
  debug("Exercising iterator\n");
  while(vpiHandle th = vpi_scan(ti)) {
    debug("Top module handle obtained\n");
    if (vpi_get(vpiType, th) != vpiModule) {
      debug("Not a module\n");
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

        // Params
        //debug("****************************************\n");
        //debug("      ***  Now finding params        ***\n");
        //debug("****************************************\n");
        //// TODO this is not helping (recheck)
        //if(vpiHandle pi = vpi_iterate(vpiParameter, mh)) {
        //  debug("Found parameters\n");
        //  visitParameters(pi);
        //} else debug("No parameters found in current module\n");

        //if(vpiHandle pai = vpi_iterate(vpiParamAssign, mh)) {
        //  debug("Found paramAssign\n");
        //  visitParamAssignment(pai);
        //} else debug("No paramAssign found in current module\n");
        //debug("\nFinal list of params:\n");
        //map<string, int>::iterator pitr;
        //for (pitr = params.begin(); pitr != params.end(); ++pitr)
        //  debug(pitr->first << " = " << pitr->second << endl);

        // Variables are storing elements (reg, logic, integer, real, time)
        //   includes some _s that appear in always_ff/comb
        //   does not include IO declared as "output logic"
        // XXX because this includes logic, and also those assigned within always_comb, this list cannot be relied upon to mean possible LHSs of procedural assignments
        //debug("****************************************\n");
        //debug("      ***  Now finding variables     ***\n");
        //debug("****************************************\n");
        //if(vpiHandle vi = vpi_iterate(vpiVariables, mh)) {
        //  debug("Found variables\n"); 
        //  visitNets(vi, false);
        //} else debug("No variables found in current module\n");
        //debug("Done with vars\n");

        //// Nets (wire, tri) -> includes IO, _cast_i, _cast_o, some _s
        //debug("****************************************\n");
        //debug("      ***     Now finding nets       ***\n");
        //debug("****************************************\n");
        //if(vpiHandle ni = vpi_iterate(vpiNet, mh)) {
        //  debug("Found nets\n");
        //  visitNets(ni, true);
        //} else debug("No nets found in current module\n");

        //// ContAssigns:
        //debug("****************************************\n");
        //debug("      *** Now finding cont. assigns  ***\n");
        //debug("****************************************\n");
        //vpiHandle cid = vpi_iterate(vpiContAssign, mh);
        //vpiHandle ci = vpi_iterate(vpiContAssign, mh);
        //// finds both when decared as:
        ////   wire x = ...
        ////   assign x = ...
        //if(ci) {
        //  debug("Found continuous assign statements \n");
        //  while (vpiHandle ch = vpi_scan(cid)) {
        //    debug("ContAssignDep Info -> " <<
        //      string(vpi_get_str(vpiFile, ch)) <<
        //      ", line:" << to_string(vpi_get(vpiLineNo, ch)) << endl;
        //    visitAssignmentForDependencies(ch);
        //    // TODO record a bool for tern operations
        //    // vpi_release_handle(ch); // TODO: check if it releases the data node, not just ptr
        //  }
        //  while (vpiHandle ch = vpi_scan(ci)) {
        //    debug("ContAssign Info -> " <<
        //      string(vpi_get_str(vpiFile, ch)) <<
        //      ", line:" << to_string(vpi_get(vpiLineNo, ch)) << endl;
        //    visitAssignment(ch);
        //    vpi_release_handle(ch);
        //  }
        //  vpi_release_handle(ci);
        //} else debug("No continuous assign statements found in current module\n");

        ////Process blocks: always_*, initial, final blocks
        //// vpiAlwaysType distinguishes always type (ff, comb, latch, _)
        //debug("****************************************\n");
        //debug("      *** Now finding process blocks ***\n");
        //debug("****************************************\n");
        //vpiHandle ai = vpi_iterate(vpiProcess, mh);
        //if(ai) {
        //  debug("Found always block\n");
        //  while(vpiHandle ah = vpi_scan(ai)) {
        //    debug("vpiProcess Info -> " <<
        //      string(vpi_get_str(vpiFile, ah)) <<
        //      ", line:" << to_string(vpi_get(vpiLineNo, ah)) << endl;
        //    global_always_ff_flag = vpi_get(vpiAlwaysType, ah) == 3;
        //    visitBlocks(ah);
        //    vpi_release_handle(ah);
        //  }
        //  vpi_release_handle(ai);
        //} else debug("No always blocks in current module\n");

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




        // Ports of the current module, NOT of submodules
        //debug("****************************************\n");
        //debug("      ***  Now finding ports         ***\n");
        //debug("****************************************\n");
        //if(vpiHandle ports = vpi_iterate(vpiPort, mh)) {
        //  debug("Found ports\n");
        //  visitPorts(ports);
        //  vpi_release_handle(ports);
        //} else debug("No ports found in current module\n");
        //debug("Done with ports\n");

        // Accumulate variables:
        paramsAll.insert(params.begin(), params.end());
        params.clear();

        debug("**** STATS FOR THE MODULE ****\n");
        //debug("\nFound " << muxOutput.size() << " mux outputs in current module:\n");
        //for (auto const& it : muxOutput)
        //  { debug("\t>> " << it.first << endl); }

        //muxOutput.clear();

        //Statistics:
        static int numTernaries, numIfs, numCases;
        nTernaries.push_back(0);//ternaries.size() - numTernaries);
        nIfs.push_back(ifs.size() - numIfs);
        nCases.push_back(cases.size() - numCases);
        debug("Block: " << defName + objectName << " | numTernaries: " << ternaries.size() - numTernaries << " | numCases: " << cases.size() - numCases << " | numIfs: " << ifs.size() - numIfs << endl); 
        numTernaries = ternaries.size();
        numIfs       = ifs.size();
        numCases     = cases.size();

        // Recursive tree traversal
        //        vpiHandle m = vpi_iterate(vpiModule, mh);
        //        if(m) {
        //          while (vpiHandle h = vpi_scan(m)) {
        //            debug("Iterating next module\n");
        //            depth = depth + "  ";
        //            string submod_name = vpi_get_str(vpiName, h);
        //            debug("Name of submodule: " << submod_name << endl);
        //            //char* cstr = new char[submod_name.length() + 1];
        //            //strcpy(cstr, submod_name.c_str());
        //            //vpiHandle aah = vpi_handle_by_name(cstr, mh);
        //            //if(aah)
        //            //  debug("WORKED!!\n");
        //            visit(h, depth);
        //            vpi_release_handle(h);
        //          }
        //          vpi_release_handle(m);
        //        }
        //        vpiHandle ga = vpi_iterate(vpiGenScopeArray, mh);
        //        if(ga) {
        //          while (vpiHandle h = vpi_scan(ga)) {
        //            debug("Iterating genScopeArray\n");
        //            vpiHandle g = vpi_iterate(vpiGenScope, h);
        //            while (vpiHandle gi = vpi_scan(g)) {
        //              debug("Iterating genScope\n");
        //              depth = depth + "  ";
        //              visit(gi, depth);
        //              vpi_release_handle(gi);
        //            }
        //            vpi_release_handle(g);
        //            vpi_release_handle(h);
        //          }
        //          vpi_release_handle(ga);
        //        }
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


  //debug("\n\n\n*** Printing all conditions ***\n\n\n");
  //print_list(all, true, outputDir / "all.sigs");
  //debug("\n\n\n*** Printing case conditions ***\n\n\n");
  //print_list(cases, true, outputDir / "case.sigs");
  //debug("\n\n\n*** Printing if/if-else conditions ***\n\n\n");
  //print_list(ifs, true, outputDir / "if.sigs");
  //debug("\n\n\n*** Printing ternary conditions ***\n\n\n");
  //print_list(ternaries, true, outputDir / "tern.sigs");
  //debug("\n\n\n*** Printing regSet ***\n\n\n");
  //print_list(regSet, true, outputDir / "all.regs");
  //debug("\n\n\n*** Printing wireSet ***\n\n\n");
  //print_list(wireSet, true, outputDir / "all.wires");
  ////debug("\n\n\n*** Printing Precise CoverPoints ***\n\n\n");
  ////print_list(outputDir / "precision.sigs");
  //debug("\n\n\n*** Printing CSV ***\n\n\n");
  //print_csvs(outputDir / "tern.csv");
  //debug("\n\n\n*** Printing Dependencies ***\n\n\n");
  //print_list(dependenciesStr, true, outputDir / "all.deps");

  //debug("\n\n\n*** Printing variables ***\n\n\n");
  //ofstream file;
  //file.open("../surelog.run/all.nets", ios_base::out);
  //for (auto const &i: nets) {
  //  file << i.name << " ";
  //  int k=0;
  //  while(k<i.dims) {
  //    file << i.width[k] << " ";
  //    k++;
  //  }
  //  file << endl;
  //}
  //file.close();
  //debug("\n\n\n*** Printing params ***\n\n\n"); //why?
  //file.open("../surelog.run/all.pars", ios_base::out);
  //map<string, int>::iterator itr;
  //for (itr = paramsAll.begin(); itr != paramsAll.end(); ++itr)
  //  file << itr->first << " = " << itr->second << endl;
  //file.close();


  cout << "\n\n\n*** Parsing Complete!!! ***\n\n\n";


  // Do not delete these objects until you are done with UHDM
  SURELOG::shutdown_compiler(compiler);
  delete clp;
  delete symbolTable;
  delete errors;
  return code;
}
