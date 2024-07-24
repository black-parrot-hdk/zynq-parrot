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



void walker_warn(std::string s) {
  std::cout << "WARN: " << s << std::endl;
}

void walker_error(std::string s) {
  std::cout << "ERROR: " << s << std::endl;
  exit(0);
}

// functions declarations
std::string visitbit_sel(vpiHandle);
std::string visithier_path(vpiHandle);
std::string visitindexed_part_sel(vpiHandle);
std::string visitpart_sel(vpiHandle);
std::list <std::string> visitCond(vpiHandle);
std::list <std::string> visitExpr(vpiHandle h, bool retainConsts, bool& constOnly);
std::tuple <bool, std::list <std::string>> visitOperation(vpiHandle);
void findTernaryInOperation(vpiHandle);
//void visitAssignmentForDependencies(vpiHandle, bool);
void visitAssignment(vpiHandle);
void visitBlocks(vpiHandle);
void visitTernary(vpiHandle, std::list<std::string> &);
void visitTopModules(vpiHandle);
void visitParamAssignment(vpiHandle);

std::string evalOperation(vpiHandle);
int evalExpr(vpiHandle, bool&);

// global variables
bool saveVariables = true; 
bool expand = true;
bool global_always_ff_flag = false;
// struct defines
// keeps track current conditional block's condition expr for iterative inserts
struct currentCond_s {
  bool v;
  std::string cond;
} currentCond = {false, ""};

// discovered variables
struct vars {
  int width[4];     // malloc will be slower, expensive; supports upto 4 dimensional arrays
  int dims;         // for multi dimension arrays
  std::string name;
  std::string type; //reg/wire
};

// global data structures
std::list <vars> nets, netsCurrent; // for storing nets discovered
std::list <std::unordered_set <std::string>> csvs;
std::list <std::string> all, ternaries, cases, ifs;  // for storing specific control expressions (see definition in main README.md)
std::list <int> nTernaries, nCases, nIfs; // incremental numbers for debug
std::map <std::string, int> 
paramsAll, params; // for params, needed for supplanting in expressions expansions

std::unordered_set<std::string>
rhsOperands;
std::unordered_map<std::string, std::unordered_set<std::string>>
dependenciesStr;

//list of variables that are mux outputs;
std::unordered_map<std::string, std::string>
muxOutput;

// lhs2rhsMultiMap is map of lhsActual to all associated rhsActulOperands
std::multimap<std::string, std::string>
lhs2rhsMultiMap;

// set of registers or wires (supercedes nets, netsAll)
std::unordered_set<std::string>
regSet, wireSet;


// Define a hash function for std::pair
struct PairHash {
    template <class T1, class T2>
    std::size_t operator()(const std::pair<T1, T2>& p) const {
        auto hash1 = std::hash<T1>{}(p.first);
        auto hash2 = std::hash<T2>{}(p.second);
        return hash1 ^ hash2; // Combine the hash values
    }
};

// unordered_map : not ordered, but lookups are faster
// unordered_map : fast insertion, duplicates are ignored

// Custom hash function for std::tuple<int, std::string>
//struct TupleHash {
//  std::size_t operator()(const std::tuple<int, std::string>& t) const {
//    auto h1 = std::hash<int>{}(std::get<0>(t));
//    auto h2 = std::hash<std::string>{}(std::get<1>(t));
//    return h1 ^ (h2 << 1); // Combine the two hash values
//  }
//};
//
//// Custom equality function for std::tuple<int, std::string> (optional)
//struct TupleEqual {
//  bool operator()(const std::tuple<int, std::string>& t1, const std::tuple<int, std::string>& t2) const {
//    return std::get<0>(t1) == std::get<0>(t2) && std::get<1>(t1) == std::get<1>(t2);
//  }
//};
//// for precise coverage
//std::unordered_set<std::tuple<int, std::string>, TupleHash, TupleEqual> covs;

std::filesystem::path outputDir;


// ancillary functions
static std::string_view ltrim(std::string_view str, char c) {
  auto pos = str.find(c);
  if (pos != std::string_view::npos) str = str.substr(pos + 1);
  return str;
}
// prints out discovered control expressions to file or stdout
void print_csvs(std::string fileName = "") {
  std::ofstream file;
  file.open(fileName, std::ios_base::out);
  for (auto const &csv : csvs) {
    for (auto j = csv.begin(); j != csv.end(); ++j) {
      file << *j;
      if (std::next(j) != csv.end()) {
        file << " , ";
      }
    }
    file << std::endl;
  }
  file.close();
}

void print_unordered_set(std::unordered_set<std::pair<std::string, int>, PairHash> &map, bool std = false, std::string fileName = "") {
  std::ofstream file;
  file.open(fileName, std::ios_base::out);
  if(file) {
    for (const auto& item : map) {
      if(std)
        std::cout << item.first << " @depth= " << item.second << std::endl;

      file << item.first << ", " << item.second << std::endl;
    }
  }
  return;
}

void print_list(std::unordered_map<std::string, std::unordered_set<std::string>> &map, bool f = false, std::string fileName = "", bool std = false) {
  std::ofstream file;
  if(f)
    file.open(fileName, std::ios_base::out);

  for (const auto& pair : map) {
    if(std) std::cout << pair.first << ": " << std::endl;
    if(f) file << pair.first << ": " << std::endl;;
    for (const std::string& item : pair.second) {
      if(std) std::cout << "\t" << item << std::endl;
      if(f) file << "\t" << item << std::endl;
    }
  }

  if(f)
    file.close();

  return;
}

void print_list(std::unordered_set<std::string> &list, bool f = false, std::string fileName = "", bool std = false) {
  std::ofstream file;
  if(f)
    file.open(fileName, std::ios_base::out);

  for (auto const &i: list) {
    if(std)
      std::cout << i << std::endl;
    if(f)
      file << i << std::endl;
  }

  if(f)
    file.close();

  return;
}

void print_list(std::list<std::string> &list, bool f = false, std::string fileName = "", bool std = false) {
  std::ofstream file;
  if(f)
    file.open(fileName, std::ios_base::out);

  for (auto const &i: list) {
    if(std)
      std::cout << i << std::endl;
    if(f)
      file << i << std::endl;
  }

  if(f)
    file.close();

  return;
}

char* getAllButLastWord(const std::string& input) {
  // Convert the input string to a C-string
  char* tempStr = new char[input.length() + 1];
  strcpy(tempStr, input.c_str());

  // Find the last occurrence of '.'
  char* lastDot = strrchr(tempStr, '.');
  if (!lastDot) {
    std::cout << "The input string does not contain '.'" << std::endl;
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
  std::multimap <std::string, std::string>          modSubmodMap;
  std::unordered_map <std::string, std::tuple<std::string, vpiHandle>>
    net_submodOut; // search with net, gives submodOut
  std::multimap <std::string, std::string>          submodIn_net;
  // multimap because submodIn can be driven by an operation of nets
  //std::multimap <std::string, std::string>          net2driver;
  std::unordered_map<std::string, std::unordered_set<std::string>> net2driver;
  std::unordered_map<std::string, std::unordered_set<std::string>> net2sel; // net to select signal (implies net is a muxOutput)
  std::list <std::string>                           moduleInputs;
  std::list <std::string>                           regs;
  std::list <std::string>                           running_cond_str;
  vpiHandle                                         parent;

};

std::map <std::string, int>           running_const;

void print_ds(std::string fileName, data_structure& ds) {
  std::ofstream file;
  file.open(fileName, std::ios_base::app);
  for (auto const& i : ds.modSubmodMap)
    file << i.first << " -- " << i.second << std::endl;

  for (auto const& i : ds.net_submodOut)
    file << i.first << " <> " << std::get<0>(i.second) << std::endl;

  for (auto const& i : ds.submodIn_net)
    file << i.first << " <> " << i.second << std::endl;

  for (auto const& i : ds.net2driver) {
    file << i.first << " ??\n";
    for (auto const& el : i.second)
      file << "\t" << el << std::endl;
  }

  for (auto const& i : ds.net2sel) {
    file << i.first << " ??\n";
    for (auto const& el : i.second)
      file << "\t" << el << std::endl;
  }

  for (auto const& i : ds.regs)
    file << "Reg:" << i << std::endl;

  for (auto const& i : ds.moduleInputs)
    file << "Input:" << i << std::endl;

  return;
}



std::unordered_map <std::string, data_structure> module_ds_map; // MAJOR TODO record only names and compute fullNames

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
void printOperandsInExpr(vpiHandle h, std::unordered_set<std::string> *out, bool print);
void findMuxesInOperation(vpiHandle h, std::list <std::string> &buffer);

// this populates the data_structure
void parse_module(vpiHandle module, vpiHandle p_in, bool genScope = false, std::string useThisForGenScope = "") {

  // TODO -- use defName for efficiency; full instance name repeats parse_modules unnecessarily
  const char *name;
  if(!useThisForGenScope.empty()) {
    if(!genScope)
      walker_error("Name explicitly given despite not being genScope");

    name = useThisForGenScope.c_str();
  } else {
    if(vpi_get(vpiTop, module) == 1) {
      std::cout << "Top module, saving with name\n";
      name = vpi_get_str(vpiName, module);
    } else
      name = vpi_get_str(vpiFullName, module);
  }

  if(name == nullptr)
    walker_error("Name can't be found\n");

  //if already parsed, do not parse again
  if(!genScope && module_ds_map.find(name) != module_ds_map.end()) {
    std::cout << "Module already parsed, so returing\n";
    return;
  }

  std::cout << "\n\nparse_module: " << name << std::endl;

  data_structure ds;
  ds.parent = p_in;
  // params resolutoin
  if(vpiHandle pai = vpi_iterate(vpiParameter, module)) {
    std::cout << "Found params\n";
    while(vpiHandle p = vpi_scan(pai)) {
      s_vpi_value value;
      vpi_get_value(p, &value);

      if(value.format) {
        std::cout << "Parameter:\n\t" << vpi_get_str(vpiFullName, p) << " = " << value.value.integer << std::endl;
        params.insert({vpi_get_str(vpiFullName, p), value.value.integer});
      }
    }
  } else std::cout << "No params found in current module\n";

  if(vpiHandle pai = vpi_iterate(vpiParamAssign, module)) {
    std::cout << "Found paramAssign\n";
    visitParamAssignment(pai);
  } else std::cout << "No paramAssign found in current module\n";

  //std::cout << "\nFinal list of params:\n";
  //std::map<std::string, int>::iterator pitr;
  //for (pitr = params.begin(); pitr != params.end(); ++pitr)
  //  std::cout << pitr->first << " = " << pitr->second << std::endl;

  // submodIn_net mapping
  // net_submodOut mapping
  if(vpiHandle m = vpi_iterate(vpiModule, module)) {
    std::cout << "List of submodules in " << name << ":\n";
    while (vpiHandle h = vpi_scan(m)) {
      std::string submod_name = vpi_get_str(vpiName, h);
      std::cout << "\t<<  " << submod_name << std::endl;
      ds.modSubmodMap.insert({name, submod_name});

      mapNetsToIO(h, ds);
    }
  }

  std::cout << "Module-Submodule map:\n"; 
  std::cout << name << std::endl;
  for (auto const &s : ds.modSubmodMap)
    std::cout << "\\_" << s.second << std::endl;

  // save module inputs
  if(vpiHandle ports = vpi_iterate(vpiPort, module)) {
    while (vpiHandle p = vpi_scan(ports)) {
      if(vpi_get(vpiDirection, p) == 1) {
        vpiHandle low_conn = vpi_handle(vpiLowConn, p);
        char *portName = vpi_get_str(vpiFullName, low_conn);
        if(portName) {
          std::cout << "Found input port; saving " << portName << std::endl;
          ds.moduleInputs.push_front(portName);
        } else {
          std::cout << "Port name not found\n";
        }
      }
    }
  }

  // driver mapping
  if(vpiHandle assigns = vpi_iterate(vpiContAssign, module)) {
    std::cout << "Parsing module assigns\n";
    while (vpiHandle a = vpi_scan(assigns)) {
      parseAssigns(a, ds, false);
    }
  }

  // parse always blocks
  if(vpiHandle proc_blks = vpi_iterate(vpiProcess, module)) {
    while(vpiHandle a = vpi_scan(proc_blks)) {
      global_always_ff_flag = (vpi_get(vpiAlwaysType, a) == 3 || vpi_get(vpiAlwaysType, a) == 1);
      std::cout << "\n\n\nParsing always block | Type: " << (global_always_ff_flag ? "Procedural" : "Continuous") << std::endl;
      std::cout << "File: " << std::string(vpi_get_str(vpiFile, a)) << ":" << std::to_string(vpi_get(vpiLineNo, a)) << std::endl;
      parseAlways(a, ds);
      assert(ds.running_cond_str.size() == 0);
      vpi_release_handle(a);
    }
  }

  // genScopeArrays (if/for blocks outside of always blocks)
  if(vpiHandle ga = vpi_iterate(vpiGenScopeArray, module)) {
    while (vpiHandle h = vpi_scan(ga)) {
      std::cout << "Iterating genScopeArray\n";
      vpiHandle g = vpi_iterate(vpiGenScope, h);
      while (vpiHandle gi = vpi_scan(g)) {
        std::cout << "Iterating genScope\n";
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
    std::cout << "Inserting freshly into module_ds_map\n";
    module_ds_map.insert({name, ds});
  } else {
    std::cout << "Appending into each ds in module_ds_map individually\n";
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
  std::cout << "Node type: " << UHDM::UhdmName((UHDM::UHDM_OBJECT_TYPE)((const uhdm_handle *)always)->type) << std::endl;
  switch(((const uhdm_handle *)always)->type) {
    case UHDM::uhdmalways : {
      // always necessarily has a statement
      if(vpiHandle s = vpi_handle(vpiStmt, always)) {
        parseAlways(s, ds);
      } else {
        std::cout << "No statement found in always block\n";
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
      std::cout << "Parsing assignment\n";
      parseAssigns(always, ds, global_always_ff_flag);
      break;
    }
    case UHDM::uhdmif_stmt:
    case UHDM::uhdmif_else: {
      vpiHandle condition = vpi_handle(vpiCondition, always);
      bool constOnly;
      std::list <std::string> cond_str = visitExpr(condition, true, constOnly);
      if(cond_str.size() != 1)
        walker_error("visitExpr is returning not just one element list");
      // push condition str
      if(!constOnly)
        ds.running_cond_str.push_front("(" + cond_str.front() + ")");
      // can have single assignment, for_stmt, or begin
      vpiHandle s = vpi_handle(vpiStmt, always);
      parseAlways(s, ds);

      if(vpiHandle s_else = vpi_handle(vpiElseStmt, always)) {
        std::cout << "Node type: else_stmt\n";
        parseAlways(s_else, ds);
      }

      if(!constOnly)
        ds.running_cond_str.pop_front();
      break;
    }
    case UHDM::uhdmcase_stmt: {
      bool constOnly;
      std::list <std::string> cond_str;
      if(vpiHandle c = vpi_handle(vpiCondition, always)) {
        cond_str = visitExpr(c, true, constOnly);
      } else
        walker_error("No condition found in case_stmt");

      std::cout << "Finding case_items\n";
      if(vpiHandle items = vpi_iterate(vpiCaseItem, always)) {
        while(vpiHandle item = vpi_scan(items)) {
          bool rcs_active; // running_cond_str active
          std::cout << "Case item processing\n";
          if(vpiHandle expr = vpi_handle(vpiExpr, item)) {
            std::list <std::string> match;
            if(((const uhdm_handle *)expr)->type == UHDM::uhdmoperation) {
              std::tie(rcs_active, match) = visitOperation(expr); // rcs used dummily
            } else {
              match = visitExpr(expr, true, rcs_active); // rcs used dummily
            }
            if(!constOnly) {
              ds.running_cond_str.push_front(" ( " + cond_str.front() + " == " + match.front() + " ) ");
              rcs_active = true;
            }
            else rcs_active = false;
          }

          // will usually be an assignment
          parseAlways(item, ds);
          if(rcs_active)
            ds.running_cond_str.pop_front();
        }
      }
      break;
    }
    case UHDM::uhdmfor_stmt: {
      // TODO: consider the initial condition, don't assume 0
      std::string itr;
      int limit = 0;
      if(vpiHandle l = vpi_handle(vpiCondition, always)) {
        if(vpiHandle ops = vpi_iterate(vpiOperand, l)) {
          vpiHandle lhs = vpi_scan(ops);
          itr = vpi_get_str(vpiName, lhs);
          vpiHandle rhs = vpi_scan(ops);
          std::cout << "Param: " <<  vpi_get_str(vpiName, rhs) << std::endl;
          limit = stoi(evalOperation(rhs));
          std::cout << "Condition for ForLoop: " << itr << " : " <<  limit << std::endl;
        }
      }

      if(vpiHandle stmt = vpi_handle(vpiStmt, always)) {
        for(int i = 0; i <= limit; i++) {
          std::cout << "Running iteration:  " << itr << " : " << i  << std::endl;
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
        std::cout << "Stmt found\n";
        parseAlways(stmt, ds);
      } else if(vpiHandle stmt = vpi_iterate(vpiStmt, always)) {
        std::cout << "Stmt iterable found\n";
        while(vpiHandle s = vpi_scan(stmt)) {
          parseAlways(s, ds);
        }
      } else
        std::cout << "Stmt not found; UNKNOWN_NODE\n";
    }
  }

}

std::string compose_running_str(std::string s, data_structure &ds) {
  std::string result;
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
    result + " & " + s;

  return result;
}

void parseAssigns(vpiHandle assign, 
    data_structure &ds,
    bool isProcedural
    ) {
  // if LHS is like a[i], or {a,...} what to do?
  std::cout << "\nWalking " << (isProcedural ? "Procedural" : "Cont.") <<  " assignment | " << vpi_get_str(vpiFile, assign) << ":" << vpi_get(vpiLineNo, assign) << std::endl;
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
    std::cout << "Walking RHS | Type: " << UHDM::UhdmName(rhs_type) << std::endl;

    std::unordered_set<std::string> rhsOps;
    printOperandsInExpr(rhs, &rhsOps, false); // updates rhsOperands
    std::cout << "Got RHS\n";

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
      std::cout << "Walking LHS | Type: " << UHDM::UhdmName(lhsType) << std::endl;

      std::unordered_set <std::string> lhsStr;
      //if (vpiHandle lhsActual = vpi_handle(vpiActual, lhs)) {
      //  std::cout << "lhsActual exists\n";
      //  if ((UHDM::UHDM_OBJECT_TYPE)((const uhdm_handle *)lhsActual)->type == UHDM::uhdmstruct_net) {
      //    std::cout << "Found struct on lhs of assignment\n";
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
        std::list tmp = visitExpr(lhs, false, constOnly);
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
        std::list <std::string> select_sigs;
        if(rhs_type == UHDM::uhdmoperation) {
          findMuxesInOperation(rhs, select_sigs);
          if(!select_sigs.empty()) {
            for(auto const& sel : select_sigs) {
              // TODO choose between carrying the AND of nested signals or just individual signals
              std::cout << "Composing running string " << sel << std::endl;
              std::string running_cond = compose_running_str(sel, ds);
              ds.net2sel[lhsEl].insert(running_cond);
              std::cout << lhsEl << " ?? " << running_cond << std::endl;
            }
          } // else std::cout << "LHS is not muxOutput\n";
        } //else std::cout << "Not found operation in assigment\n";

        // insert into net2sel if inside if/case statements
        if(!ds.running_cond_str.empty()) {
          // this signals the assignment is inside an if/case condition
          ds.net2sel[lhsEl].insert(compose_running_str("", ds));
        }

        // insert into net2driver
        for (const auto& rhsStr: rhsOps) {
          auto it = std::find(select_sigs.begin(), select_sigs.end(), rhsStr);
          if(it != select_sigs.end()) {
            // no need to add select_signals as drivers
            continue;
          } else {
            ds.net2driver[lhsEl].insert(rhsStr);
            std::cout << lhsEl << (isProcedural ? " <- " : " <= ") << rhsStr << std::endl;
          }
        }
      }

      vpi_release_handle(lhs);
    } // else std::cout << "Assignment without LHS handle\n";
    vpi_release_handle(rhs);
  } // else std::cout << "Assignment without RHS handle\n";
}

void mapNetsToIO(vpiHandle submodule,
    data_structure &ds
    ) {
  std::string submodule_name = vpi_get_str(vpiName, submodule);
  if(vpiHandle ports = vpi_iterate(vpiPort, submodule)) {
    std::cout << "Parsing submod ports\n";
    while (vpiHandle p = vpi_scan(ports)) {
      if(vpiHandle low_conn = vpi_handle(vpiLowConn, p)) {
        // low conn can never be operation, has to be a ref_obj
        std::string low_conn_name = vpi_get_str(vpiFullName, low_conn);
        if(vpiHandle high_conn = vpi_handle(vpiHighConn, p)) {
          //vpiHandle actual_high = vpi_handle(vpiActual, high_conn);
          //if(actual_high)
          //  high_conn = actual_high;
          std::cout << "HighConn type: " << UHDM::UhdmName(((const uhdm_handle *)high_conn)->type) << std::endl;
          if(((const uhdm_handle *)high_conn)->type == UHDM::uhdmoperation) {
            // if the port's high_conn is an operation
            /* vpiOpType : type
             * 36 : empty
             */
            if(vpi_get(vpiOpType, high_conn) == 36) {
              // unconnected output port -- so ignore; technically you should have known this from DCE
            } else {
              std::unordered_set <std::string> l;
              printOperandsInExpr(high_conn, &l, false);
              for (auto const& el : l) {
                // 2 -> output port
                // 1 -> input port
                if(vpi_get(vpiDirection, p) == 2) {
                  ds.net_submodOut.insert({el, std::make_tuple(low_conn_name, submodule)});
                  std::cout << "MappingOut: " << el << " <> " << low_conn_name << std::endl;
                } else {
                  ds.submodIn_net.insert({low_conn_name, el}); // can be a multimap
                  std::cout << "MappingIn: " << low_conn_name << " <> " << el << std::endl;
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
            std::list tmp = visitExpr(high_conn, true, constOnly);
            if(!constOnly) {
              if(!tmp.empty()) {
                if(vpi_get(vpiDirection, p) == 2) {
                  ds.net_submodOut.insert({tmp.front(), std::make_tuple(low_conn_name, submodule)});
                  std::cout << "MappingOut: " << tmp.front() << " <> " << low_conn_name << std::endl;
                } else {
                  ds.submodIn_net.insert({low_conn_name, tmp.front()}); // can be a multimap
                  std::cout << "MappingIn: " << low_conn_name << " <> " << tmp.front()  << std::endl;
                }
              }
            }
          }
        }
      }
    }
  }
}

std::string getLastWord(const std::string &input) {
  // Find the position of the last '.'
  size_t lastDotPos = input.rfind('.');

  // If there is no '.' in the string, return the original string
  if (lastDotPos == std::string::npos) {
    return input;
  }

  // Return the substring up to (but not including) the last '.'
  return input.substr(lastDotPos+1, input.length());
}

bool removeLastWordOrSel(const std::string &input, std::string &parent, std::string &last) {
  //std::cout << "Removing last word from " << input << std::endl;
  // find the position of the last '.'
  std::size_t posDot = input.find_last_of('.');
  std::size_t posBracket = input.find_last_of('[');
  std::size_t pos;
  if(posDot != std::string::npos && posBracket != std::string::npos)
    pos = std::max(posDot, posBracket);
  else if (posDot != std::string::npos) 
    pos = posDot;
  else if (posBracket != std::string::npos)
    pos = posBracket;
  else {
    // if there is no '.' or '[' in the string, return the original string
    std::cout << "No '.' or '[' in the string\n";
    return false; // parent and last are empty
  }

  // return the substring up to (but not including) the last '.'
  parent = input.substr(0, pos);
  last = input.substr(pos+1, input.length());
  //std::cout << "Removed; result: " << parent << std::endl;
  return true;
}

// Function to find the penultimate word in a string separated by '.'
char* getPenultimateWord(const std::string& input) {
  // Convert the input string to a C-string
  char* tempStr = new char[input.length() + 1];
  strcpy(tempStr, input.c_str());

  // Find the first occurrence of '.' from the end
  char* lastDot = strrchr(tempStr, '.');
  if (!lastDot) {
    std::cout << "The input string does not have enough words separated by '.'" << std::endl;
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

//std::string fetchSuperModuleNet(vpiHandle parent, std::string submodIn) {
//  assert((UHDM::UHDM_OBJECT_TYPE)((const uhdm_handle *)parent)->type == UHDM::uhdmmodule_inst);
//  if(char * name = vpi_get_str(vpiName, parent)) {
//    data_structure ds = module_ds_map[name];
//    // TOD make this nested lookup -- might not help
//    auto range = ds.submodIn_net.equal_range(submodIn);
//    if(range.first == range.second)
//      std::cout << "Supermodule net corresponding to input not found!\n";
//    for (auto it = range.first; it != range.second; ++it) {
//
//      std::cout << "Did not find the connection to the input port in the supermodule\n";
//      assert (false);
//    }
//  } else 
//    std::cout << "Unable to determine name of parent\n";
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

std::map <std::string, std::string> blacklist = { 
  // module defName            sel input
  {"work@bsg_mux2_gatestack",  "i2"},
  {"work@bsg_mux_bitwise",     "sel_i"},
  {"work@bsg_mux_butterfly",   "sel_i"},
  {"work@bsg_muxi2_gatestack", "i2"},
  {"work@bsg_mux_one_hot",     "sel_one_hot_i"},
  {"work@bsg_mux_segmented",   "sel_i"},
  {"work@bsg_mux",             "sel_i"}
};

bool findDriver (data_structure &ds, std::string net) {
  return ds.net2driver.find(net) != ds.net2driver.end();
}
bool findSource (data_structure &ds, std::string net) {
  auto source = ds.net_submodOut.find(net);
  return source != ds.net_submodOut.end();
}
bool findIfInput(data_structure &ds, std::string net) {
  return std::find(ds.moduleInputs.begin(), ds.moduleInputs.end(), net) != ds.moduleInputs.end();
}

inline bool matchesPattern(const std::string& test, const std::string& prefix) {
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

std::vector<std::string> findMatchingStrings(const data_structure &ds, const std::string &prefix, std::string indent) {
  std::vector<std::string> matchingValues;

  for (const auto &pair : ds.net_submodOut) {
    if (matchesPattern(pair.first, prefix)) {
      std::cout << indent << "\tMatching source for: " << pair.first << " <- " << std::get<0>(pair.second) << std::endl;
      matchingValues.push_back(pair.first);
    }
  }

  for (const auto &pair : ds.net2driver) {
    if (matchesPattern(pair.first, prefix)) {
      std::cout << indent << "\tMatching driver for: " << pair.first << std::endl;
      std::cout << indent << "\tCandidates:\n";
      for (const auto& i : pair.second) {
        std::cout << indent << "\t\t" << i << std::endl;
        matchingValues.push_back(i);
      }
    }
  }

  return matchingValues;
}

void traverse(std::string pnet, 
    //std::string psel,
    vpiHandle inst, int depth, std::unordered_set<std::string> &visited, std::unordered_set<std::pair<std::string, int>, PairHash> &covs, std::string indent = "") {

  // some nets can be directly avoided -- clk, reset (but I don't think we ever get clk).
  // for resets, I think since we avoid parsing the select signal, it should also be automatically taken care of

  //std::string net = pnet + psel;
  std::string net = pnet;

  // retrieve the data_structure
  bool topModule = vpi_get(vpiTop, inst);
  std::string name = topModule ? vpi_get_str(vpiName, inst) : vpi_get_str(vpiFullName, inst);
  data_structure ds = module_ds_map[name];

  // if module input and topModule, exit cleanly
  bool isInput = findIfInput(ds, net);
  std::cout << indent << (isInput ? "Net is an input port" : "Net is not an input port") << std::endl;
  if (topModule && isInput) {
    std::cout << indent << "*** Success!! ***\n";
    return;
  } // if not topmodule, handled within source-finding routine

  // if already traversed as a parent, return, otherwise also save to visited
  if(visited.find(net) != visited.end()) {
    std::cout << indent << "\tPreviously traversed\n";
    return;
  } else {
    visited.insert(net);
  }

  std::cout << indent << "Parsing: " << net << " | depth=" << depth << " | inst: "<< name << std::endl;

  // assume we have nothing
  bool noDriver = true;
  bool noSource = true;
  bool noSupermod = true;

  // iterators for different ds
  auto source = ds.net_submodOut.find(net);

  // check if blacklisted module
  std::string defName = vpi_get_str(vpiDefName, inst);
  for (auto const& bl : blacklist)
    if(bl.first == defName) {
      std::cout << indent << "Blacklisted module\n";
      std::string sel = vpi_get_str(vpiFullName, inst);
      sel = sel + "." + bl.second;
      std::cout << indent << "Inserting: " << sel << " @depth=" << depth << std::endl;
      covs.insert({sel, depth});

      // skip to the input ports of the module (avoid the select signal inputs)
      //vpiHandle supermodule = vpi_handle(vpiParent, inst);
      vpiHandle supermodule = ds.parent;
      std::cout << indent << "Input port candidates to jump to:\n";
      //for(auto const& in : module_ds_map[name].moduleInputs)
      //  std::cout << indent << "[in]: " << in << std::endl;

      for(auto const& in : module_ds_map[name].moduleInputs) { // in -- low_conn
        std::cout << indent << "submodIn_net candidates:\n";
        //for(auto const& super_in : module_ds_map[(vpi_get_str(vpiFullName, supermodule))].submodIn_net)
        //  std::cout << indent << super_in.first << std::endl;

        char *pname = vpi_get(vpiTop, ds.parent) ? vpi_get_str(vpiName, ds.parent) : vpi_get_str(vpiFullName, ds.parent); // topModule's ds.parent is nullptr
        for(auto const& super_in : module_ds_map[pname].submodIn_net) {
          if(in == super_in.first) {
            std::cout << "Shorting to the input port: " << super_in.second << std::endl;
            if(in.find(bl.second) == std::string::npos) {
              std::cout << indent << "Not a select input, traversing\n";
              //std::string new_indent = indent.substr(0, indent.length() - 2);
              traverse(super_in.second, supermodule, depth, visited, covs, indent + "| ");
            } else
              std::cout << indent << "This is the select input, ignoring\n";
          }
        }
      }

      visited.erase(net);
      std::cout << indent << "Exiting\n";
      return;
    }

  // if muxOutput, add to covs at this depth
  if(ds.net2sel.find(net) == ds.net2sel.end()) {
    std::cout << indent << "Net is not mux-output\n";
  } 
  else {
    std::cout << indent << "Net is mux-output\n";
    std::unordered_set sels = ds.net2sel[net]; // resume from here
    for (auto const& it : sels) {
      covs.insert({it, depth});
      std::cout << indent << "\t\\_" << it << ", " << depth << std::endl;
    }
  }

  // find the assignment where net is lhs 
  //   and recurse into each of the operands
  if(ds.net2driver.find(net) == ds.net2driver.end()) {
    std::cout << indent << "Net has no registered driver\n";
  }
  else {
    noDriver = false;
    std::cout << indent << "Driver candidates:\n";
    for (auto const it : ds.net2driver[net]) {
      std::cout << indent << "[d]: " << it << std::endl;
    }

    for (auto const it : ds.net2driver[net]) {
      auto findReg = std::find(ds.regs.begin(), ds.regs.end(), net);
      bool isReg = findReg != ds.regs.end();
      if(isReg) {
        // increment depth
        std::cout << indent << "Reg driver = " << it << std::endl;
        traverse(it, inst, depth + 1, visited, covs, indent + "| ");
      } else {
        std::cout << indent << "Wire driver = " << it << std::endl;
        traverse(it, inst, depth, visited, covs, indent + "| ");
      }
    }
    visited.erase(net);
    std::cout << indent << "Exiting\n";
    return;
  }

  // or a module instance where net is the output pin, 
  //   and recurse into each of the operands
  if(source == ds.net_submodOut.end()) {
    std::cout << indent <<"Net has no registered source\n";
    //for(auto const& el : ds.net_submodOut)
    //  std::cout << "Help: " << el.first << " <- " << std::get<0>(el.second) << std::endl;
  } else {
    noSource = false;
    assert(source->first == net);
    std::cout << indent << "Source = " << std::get<0>(source->second) << std::endl;

    //char *inst_name = getPenultimateWord(source->second);
    //std::string inst_name = std::get<1>(source->second);
    //std::cout << indent << "Net's source is from module: " << inst_name << std::endl;
    //char* cstrManual = new char[inst_name.size() + 1]; // +1 for the null terminator
    //std::strcpy(cstrManual, inst_name.c_str());
    //vpiHandle submodule = vpi_handle_by_name(cstrManual, inst);
    vpiHandle submodule = std::get<1>(source->second);
    if(submodule) {
      std::cout << indent << "Found submodule handle\n";
      parse_module(submodule, inst);
      std::cout << indent << "Traversing with submodule handle\n";
      traverse(std::get<0>(source->second), submodule, depth, visited, covs, indent + "| ");
      visited.erase(net);
      std::cout << indent << "Exiting\n";
      return;
    } else
      walker_error("Submodule handle not found");
  }

  // if module input and !topModule, recurse back into the super-module
  if(!topModule && isInput) {
    noSupermod = false;
    std::cout << indent << "Net has a source from supermodule\n";
    if(ds.parent) {
      std::cout << indent << "Name of supermodule: " << vpi_get_str(vpiName, ds.parent) << std::endl;
      char *pname = vpi_get(vpiTop, ds.parent) ? vpi_get_str(vpiName, ds.parent) : vpi_get_str(vpiFullName, ds.parent); // topModule's ds.parent is nullptr
      if(pname) {
        data_structure ds_par = module_ds_map[pname];
        auto range = ds_par.submodIn_net.equal_range(net);
        if(range.first == range.second) {
          walker_warn("Supermodule net corresponding to input not found!");
          visited.erase(net);
          std::cout << indent << "Exiting\n";
          return;
        }
        std::cout << indent << "Supermodule net candidates:\n";
        for (auto it = range.first; it != range.second; ++it)
          std::cout << indent << "[sup]: " << it->second << std::endl;
        for (auto it = range.first; it != range.second; ++it) {
          std::cout << indent << "Traversing into supermodule\n";
          //std::string new_indent = indent.substr(0, indent.length() - 2);
          traverse(it->second, ds.parent, depth, visited, covs, indent + "| ");
        }
        visited.erase(net);
        std::cout << indent << "Exiting\n";
        return;
      } else walker_error( "Unable to determine name of supermodule");
    } else walker_error("Parent of current module not found!");
  } else {
    // either not an input port OR is topModule
    std::cout << indent << "Net has no supermodule source\n";
  }

  // if not found in either net2driver or net_submodOut do nothing and returrn
  if (noSource && noDriver && noSupermod) {
    // Debug why source or driver couldn't be found

    // struct fix: 
    // first find net.* or net[*]
    std::cout << indent << "Finding matches for " << net << ".* or [*]" << std::endl;
    std::vector <std::string> matches = findMatchingStrings(ds, net, indent);
    if(!matches.empty()) {
      for(auto const& el : matches) {
        traverse(el,
            //psel,
            inst, depth, visited, covs, indent + "| ");
      }
      visited.erase(net);
      std::cout << indent << "Exiting\n";
      return;
    }

    // struct fix:
    // else try left shifting
    std::cout << indent << "Failed to match net.* / [*]" << std::endl;
    std::string new_net, new_psel;
    std::string cumul_psel = "";
    std::string check_net = net;
    while(true) {
      bool r = removeLastWordOrSel(check_net, new_net, new_psel);
      if(r && new_net != name) {
        if((findDriver(ds, new_net) || findSource(ds, new_net) || findIfInput(ds, new_net))) {
          // dealing with either a struct or part/bitsel here
          std::cout << indent << "Found match for parent: " << new_net << std::endl;
          traverse(new_net, 
              //new_psel,
              inst, depth, visited, covs, indent + "| ");
          visited.erase(net);
          std::cout << indent << "Exiting\n";
          return;
        } else {
          check_net = new_net;
          cumul_psel += new_psel;
        }
      } else {
        std::cout << indent << "DEBUG this node: " << net << std::endl;
        walker_warn("DEBUG this node");
        visited.erase(net);
        std::cout << indent << "Exiting\n";
        return;
      }
    }
  }

  visited.erase(net);
  std::cout << indent << "Exiting\n";
  return;
}

// visitor functions for different node types
//std::string visitref_obj(vpiHandle h) {
//  std::string out = "";
//  if(vpiHandle actual = vpi_handle(vpiActual, h)) {
//    std::cout << "Actual type of ref_obj: " << 
//      UHDM::UhdmName((UHDM::UHDM_OBJECT_TYPE)((const uhdm_handle *)actual)->type) << std::endl;
//    switch(((const uhdm_handle *)actual)->type) {
//      case UHDM::uhdmparameter : 
//        out = (visitExpr(actual, true)).front(); //TODO
//        break;
//      case UHDM::uhdmconstant:
//      case UHDM::uhdmenum_const :
//      case UHDM::uhdmenum_var :
//      default :
//        std::cout << "Default actual object\n";
//        if (const char* s = vpi_get_str(vpiFullName, actual))
//          out += s;
//        else if(const char *s = vpi_get_str(vpiName, actual))
//          out += s;
//        else out += "UNKNOWN";
//        std::cout << "(Full)Name: " << out << std::endl;
//        break;
//    }
//  } else {
//    std::cout << "Walking not actual reference object; type: " << 
//      UHDM::UhdmName((UHDM::UHDM_OBJECT_TYPE)((const uhdm_handle *)h)->type) << std::endl;
//    if (const char* s = vpi_get_str(vpiFullName, h)) {
//      std::cout << "FullName available " << s << std::endl;
//      out += s;
//    } else if(const char *s = vpi_get_str(vpiName, h)) {
//      std::cout << "FullName unavailable\n";
//      out += s;
//    } else std::cout << "Neither FullName, nor Name available\n";
//
//  }
//  return out;
//}

std::string visitbit_sel(vpiHandle h) {
  std::string out = "";
  std::cout << "Walking bit select\n";
  if(const char *s = vpi_get_str(vpiFullName, h)) {
    out += s;
    std::cout << "FullName at bit_sel: " << s << std::endl;
  } else {
    vpiHandle par = vpi_handle(vpiParent, h);
    if(!par) {
      walker_error("Couldn't find parent of bit_sel!");
    } else {
      bool constOnly;
      out += visitExpr(par, true, constOnly).front();
    }
  }
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
  std::cout << "Final bit_sel: " << out << std::endl;
  return out;
}

std::string visitindexed_part_sel(vpiHandle h) {
  std::string out = "";
  std::cout << "Walking indexed part select\n";
  vpiHandle par = vpi_handle(vpiParent, h);
  bool constOnly;
  if(!par) std::cout << "Couldn't find parent\n";
  else out += visitExpr(par, true, constOnly).front();
  out += "[";
  if(vpiHandle b = vpi_handle(vpiBaseExpr, h)) {
    std::cout << "Base expression found\n";
    out += evalOperation(b);
    vpi_release_handle(b);
  }
  out += "+:";
  if(vpiHandle w = vpi_handle(vpiWidthExpr, h)) {
    std::cout << "Width expression found\n";
    out += evalOperation(w);
    vpi_release_handle(w);
  }
  out += "]";
  return out;
}

std::string visitvar_sel(vpiHandle h) {
  std::string out = "";
  std::cout << "Walking var select\n";
  out += vpi_get_str(vpiFullName, h);

  bool constOnly;
  if(vpiHandle indh = vpi_iterate(vpiIndex, h)) {
    while(vpiHandle ind = vpi_scan(indh)) {
      out += "[";
      out += (visitExpr(ind, true, constOnly)).front();
      out += "]";
    }
    vpi_release_handle(indh);
  } else std::cout << "Indices not found" << std::endl;
  return out;
}

std::string visitpart_sel(vpiHandle h) {
  std::string out = "";
  std::cout << "Walking part select\n";
  vpiHandle par = vpi_handle(vpiParent, h);
  bool constOnly;
  if(!par) std::cout << "Couldn't find parent\n";
  else out += visitExpr(par, true, constOnly).front();
  out += "[";
  vpiHandle lrh = vpi_handle(vpiLeftRange, h);
  if(lrh) {
    out += evalOperation(lrh);
  }
  else std::cout << "Left range not found; type: " <<
    UHDM::UhdmName((UHDM::UHDM_OBJECT_TYPE)(((const uhdm_handle *)lrh)->type)) << std::endl;
  out += ":";
  vpiHandle rrh = vpi_handle(vpiRightRange, h);
  if(rrh) {
    out += evalOperation(rrh);
  }
  else std::cout << "Right range not found; type: " <<
    UHDM::UhdmName((UHDM::UHDM_OBJECT_TYPE)(((const uhdm_handle *)rrh)->type)) << std::endl;
  out += "]";
  vpi_release_handle(rrh);
  vpi_release_handle(lrh);
  return out;
}

std::list <std::string> visitExpr(vpiHandle h, bool retainConsts, bool& constOnly) {
  std::cout << "In visitExpr; type: " << UHDM::UhdmName((UHDM::UHDM_OBJECT_TYPE)((const uhdm_handle *)h)->type) << std::endl;
  constOnly = false; // init
  std::list <std::string> out;
  switch(((const uhdm_handle *)h)->type) {
    case UHDM::uhdmoperation : {
      // TODO might have to do something based on retain const
      std::cout << "Operation at visitExpr\n";
      std::tie(constOnly, out) = visitOperation(h);
      break;
    }
    case UHDM::uhdmlogic_net :
    case UHDM::uhdmlogic_var :
    case UHDM::uhdmstruct_var :
    case UHDM::uhdmenum_var :
    case UHDM::uhdmpacked_array_var :
    case UHDM::uhdmstruct_net : {
      std::cout << "Found fullname " << vpi_get_str(vpiFullName, h) << std::endl;
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
          out.push_back(std::to_string(tmp));
        else if(const char *fullName = vpi_get_str(vpiFullName, h))
          out.push_back(fullName);
        else if(const char *fullName = vpi_get_str(vpiName, h))
          out.push_back(fullName);
        else 
          walker_error("Unable to identify constant");

      } else {
        std::cout << "Ignoring\n";
      }
      break;
    }
    case UHDM::uhdmref_obj : {
      if(vpiHandle actual = vpi_handle(vpiActual, h)) {
        std::cout << "Actual type of ref obj: " << UHDM::UhdmName((UHDM::UHDM_OBJECT_TYPE)((const uhdm_handle *)actual)->type) << std::endl;
        out = visitExpr(actual, retainConsts, constOnly);
      }
      else {
        std::cout << "Ref object at leaf\n";

        std::cout << "Walking reference object; type: " <<
          UHDM::UhdmName((UHDM::UHDM_OBJECT_TYPE)((const uhdm_handle *)h)->type) << std::endl;
        if (const char* s = vpi_get_str(vpiFullName, h)) {
          std::cout << "FullName available " << s << std::endl;
          out.push_back(s);
        } else if(const char *s = vpi_get_str(vpiName, h)) {
          std::cout << "FullName unavailable\n";
          out.push_back(s);
        } else walker_error("Neither FullName, nor Name available");
      }
      break;
    }
    case UHDM::uhdmbit_select : {
      std::cout << "Bit select at leaf\n";
      std::string tmp = visitbit_sel(h);
      out.push_back(tmp);
      break;
    }
    case UHDM::uhdmpart_select : {
      std::cout << "Part select at leaf\n";
      std::string tmp = visitpart_sel(h);
      out.push_back(tmp);
      break;
    }
    case UHDM::uhdmvar_select : {
      std::cout << "Var select at leaf\n";
      std::string tmp = visitvar_sel(h);
      out.push_back(tmp);
      break;
    }
    case UHDM::uhdmindexed_part_select : {
      std::cout << "Indexed part select at leaf\n";
      std::string tmp = visitindexed_part_sel(h);
      out.push_back(tmp);
      break;
    }
    case UHDM::uhdmhier_path : { 
      std::string tmp = visithier_path(h);
      std::cout << "Struct at leaf: " << tmp << std::endl;
      out.push_back(tmp);
      break;
    }
    case UHDM::uhdmint_typespec : {
      std::cout << "Typespec at leaf\n";
      s_vpi_value value;
      vpi_get_value(h, &value);
      if (value.format)
        out.push_back(std::to_string(value.value.integer));
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
      std::string fname = vpi_get_str(vpiName, h);
      if(retainConsts) {
        std::string tmp = fname + "(";
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
      std::list <std::string> tmp = visitExpr(pat, retainConsts, constOnly);
      break;
    }
    default :
      if(char *c = vpi_get_str(vpiFullName, h))
        out.push_back(c);
      else walker_error("UNKNOWN node at leaf; type: " +
          UHDM::UhdmName((UHDM::UHDM_OBJECT_TYPE)((const uhdm_handle *)h)->type));
      break;
  }
  return out;
}

std::string visithier_path(vpiHandle soph) {
  std::string out = "";
  std::cout << "Walking hierarchical path\n";

  if(vpiHandle it = vpi_iterate(vpiActual, soph)) {
    bool first = true;
    while(vpiHandle itx = vpi_scan(it)) {
      bool bitsel = ((const uhdm_handle *)itx)->type == UHDM::uhdmbit_select;
      std::cout << "Found ref object; type: " << UHDM::UhdmName((UHDM::UHDM_OBJECT_TYPE)((const uhdm_handle *)itx)->type) << std::endl;

      if(!first)
        out += ".";

      if(bitsel && first) {
        std::cout << "Walking base (bitsel)\n";
        if(vpiHandle expr = vpi_handle(vpiExpr, soph)) {
          bool constOnly;
          std::string base = (visitExpr(expr, true, constOnly)).front();
          std::cout << "Base: " << base << std::endl;

          if(vpiHandle ind = vpi_handle(vpiIndex, itx) ) {
            base += "[";
            base += evalOperation(ind);
            base += "]";
            out += base;
          } else walker_error("Index of bitsel at hier_path not found");
        } else if(const char *fullName = vpi_get_str(vpiFullName, itx)) {
          out += std::string(fullName);

        } else if(vpiHandle parent = vpi_handle(vpiParent, itx)) {
          if(const char *fullName = vpi_get_str(vpiFullName, parent)) {
            out += std::string(fullName);
          } else {
            walker_error("Parent of bitsel in hierpath first, doesn't have fullname");
          }

        } else
          walker_error("Cannot find bitsel base");

        std::cout << "Full bitsel: " << out << std::endl;
      } else {
        if(first) {
          std::cout << "Walking base \n";
          if(vpiHandle actual = vpi_handle(vpiActual, itx)) {
            std::cout << "Actual found\n";
            bool constOnly;
            out += (visitExpr(actual, true, constOnly)).front();
          } else
            walker_error("Actual not found");
        } else {
          std::cout << "Walking member hierarchy\n";
          //out += vpi_get_str(vpiName, itx);
          bool constOnly;
          out += getLastWord((visitExpr(itx, true, constOnly)).front());

        }
      }
      first = false;
      std::cout << "Extracted at this point: " << out << std::endl;
    }
  } else std::cout << "Couldn't iterate through member actuals\n";
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
   } else std::cout << "Left range UNKNOWN; type: " <<
   UHDM::UhdmName((UHDM::UHDM_OBJECT_TYPE)(((const uhdm_handle *)lrh)->type)) << std::endl;
   vpiHandle rrh = vpi_handle(vpiRightRange, h);
   if(rrh) {
   right = evalExpr(rrh, found);
   } else std::cout << "Right range UNKNOWN; type: " <<
   UHDM::UhdmName((UHDM::UHDM_OBJECT_TYPE)(((const uhdm_handle *)rrh)->type)) << std::endl;
   vpi_release_handle(rrh);
   vpi_release_handle(lrh);
   std::cout << "Operand width: " << std::to_string(right-left);
   return right - left;
   }
   case UHDM::uhdmhier_path:
   case UHDM::uhdmref_obj: {
   std::string name = visitref_obj(h);
   std::cout << "Finding width of " << name << std::endl;
   auto match = std::find_if(netsCurrent.cbegin(), netsCurrent.cend(),
   [&] (const vars& s) {
   return s.name == name;
   });
   if(match != netsCurrent.cend()) {
   std::cout << "Operand width: " << *(match->width) << std::endl;
   return *(match->width);
   } else {
   std::cout << "Couldn't find the width of: " << name << std::endl;
   return -1;
   }
   }
   case UHDM::uhdmconstant:
   case UHDM::uhdmparameter:
   return -1;
   default: 
   std::cout << "Operand width: UNKNOWN\n";
   std::cout << "Operand type: " <<  UHDM::UhdmName((UHDM::UHDM_OBJECT_TYPE)(((const uhdm_handle *)h)->type)) << std::endl;
   return -1;
   }
   return -1;
   }
 */

std::tuple <bool, std::list <std::string>> visitOperation(vpiHandle h) {
  vpiHandle ops = vpi_iterate(vpiOperand, h);
  std::list <std::string> current;
  std::string out = "";
  bool constantsOnly = true;

  const int type = vpi_get(vpiOpType, h);
  std::cout << "Operation type: " << UHDM::UhdmName((UHDM::UHDM_OBJECT_TYPE)type) << "(" << std::to_string(type) << ")" << std::endl;
  std::string symbol = "";
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
    default : symbol += " UNKNOWN_OP(" + std::to_string(type) + ") " ; break;
  }

  std::cout << "Found symbol\n";
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
      std::cout << "Walking on operands\n";
      if(opCnt == 0) {
        if(type == 67) {
          std::cout << "Finding typespec\n";
          bool constOnly;
          out += (visitExpr(oph, true, constOnly)).front();
        } 

        if(((const uhdm_handle *)oph)->type == UHDM::uhdmoperation) {
          out += "(";
          std::list <std::string> tmp;
          bool k_tmp;
          std::tie(k_tmp, tmp) = visitOperation(oph);
          out += tmp.front();
          out += ")";

          constantsOnly &= k_tmp; //Depends on whether subop is constantsOnly
        } else {
          bool conly;
          std::string tmp = (visitExpr(oph, true, conly)).front(); // true because we want to retain or resolve consts
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
          std::list <std::string> tmp;
          bool k_tmp;
          std::tie(k_tmp, tmp) = visitOperation(oph);
          out += tmp.front();
          out += ")";
          constantsOnly &= k_tmp;
        } else {
          bool conly;
          std::string tmp = (visitExpr(oph, true, conly)).front();
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
      std::cout << "Operation is constants-only: " << out << std::endl;
    std::cout << "Inserting Operation\n";
    current.push_front(out);

  } else {
    std::cout << "Couldn't iterate on operands! Iterator type: " <<  UHDM::UhdmName((UHDM::UHDM_OBJECT_TYPE)((const uhdm_handle *)ops)->type) << std::endl;
  }

  vpi_release_handle(ops);
  return std::make_tuple(constantsOnly, current);
}

//std::list <std::string> visitCond(vpiHandle h) {
//  /* Condition can be any of:
//     \_bit_select:
//     \_constant:             // ignore
//     \_hier_path:
//     \_indexed_part_select:  // perhaps only in case conditions
//     \_operation:
//     \_ref_obj:
//   */
//
//  std::cout << "Walking condition; type: " << 
//    UHDM::UhdmName((UHDM::UHDM_OBJECT_TYPE)((const uhdm_handle *)h)->type) << std::endl;
//  std::list <std::string> current;
//  switch(((const uhdm_handle *)h)->type) {
//    case UHDM::uhdmpart_select :
//    case UHDM::uhdmindexed_part_select :
//    case UHDM::uhdmbit_select :
//    case UHDM::uhdmref_obj :
//    case UHDM::uhdmconstant :
//    case UHDM::uhdmparameter : 
//    case UHDM::uhdmhier_path :
//      std::cout << "Leafs found\n";
//      bool constOnly;
//      current = visitExpr(h, true, constOnly); //need to retain constants so condition gets printed fully
//      break;
//    case UHDM::uhdmoperation :
//      std::cout << "Operation found\n";
//      bool k;
//      std::tie(k, current) = visitOperation(h);
//      break;
//    default: 
//      std::cout << "UNKNOWN type found\n";
//      break;
//  }
//  return current;
//}
//
//void visitIfElse(vpiHandle h) {
//  std::list <std::string> out;
//  std::cout << "Found IfElse/If\n";
//  if(vpiHandle c = vpi_handle(vpiCondition, h)) {
//    std::cout << "Found condition\n";
//    out = visitCond(c);
//    vpi_release_handle(c);
//  } else std::cout << "No condition found\n";
//  std::cout << "Saving to list: \n";
//  print_list(out);
//
//  std::list <std::string> tmp(out);
//  ifs.insert(ifs.end(), out.begin(), out.end());
//  all.insert(all.end(), tmp.begin(), tmp.end());
//
//  if(vpiHandle s = vpi_handle(vpiStmt, h)) {
//    std::cout << "Found statements\n";
//    visitBlocks(s);
//    vpi_release_handle(s);
//  } else std::cout << "Statements not found\n";
//  return;
//}
//
//void visitCase(vpiHandle h) {
//  std::list <std::string> out;
//  if(vpiHandle c = vpi_handle(vpiCondition, h)) {
//    std::cout << "Found condition\n";
//    out = visitCond(c);
//    vpi_release_handle(c);
//  } else std::cout << "No condition found!\n";
//  cases.insert(cases.end(), out.begin(), out.end());
//  all.insert(all.end(), out.begin(), out.end());
//  std::cout << "Parsing case item; type: " << 
//    UHDM::UhdmName((UHDM::UHDM_OBJECT_TYPE)((const uhdm_handle *)h)->type) << std::endl;
//  vpiHandle newh = vpi_iterate(vpiCaseItem, h);
//  if(newh) {
//    while(vpiHandle sh = vpi_scan(newh)) {
//      std::cout << "Found case item; type: " << 
//        UHDM::UhdmName((UHDM::UHDM_OBJECT_TYPE)((const uhdm_handle *)sh)->type) << std::endl;
//      visitBlocks(sh);
//      vpi_release_handle(sh);
//    }
//    vpi_release_handle(newh);
//  } else std::cout << "Statements not found\n";
//  return;
//}

bool isOpTernary(vpiHandle h) {
  const int n = vpi_get(vpiOpType, h);
  if (n == vpiConditionOp) {
    return true;
  }
  return false;
}
void findMuxesInOperation(vpiHandle h, std::list <std::string> &buffer) {
  if (isOpTernary(h)) {
    std::cout << "Ternary found in RHS\n";
    visitTernary(h, buffer);
  } else {
    if(vpiHandle operands = vpi_iterate(vpiOperand, h)) {
      while(vpiHandle operand = vpi_scan(operands)) {
        std::cout << "Walking operand | Type: " << UHDM::UhdmName((UHDM::UHDM_OBJECT_TYPE)((uhdm_handle *)operand)->type) << std::endl;
        if(((uhdm_handle *)operand)->type == UHDM::uhdmoperation) {
          std::cout << "\nOperand is an operation; recursing" << std::endl;
          findMuxesInOperation(operand, buffer);
        }
        vpi_release_handle(operand);
      }
      vpi_release_handle(operands);
    }
  }
}

// takes any RHS of an assignment and prints out operands
void printOperandsInExpr(vpiHandle h, std::unordered_set<std::string> *out, bool print=false) {
  assert(vpi_get(vpiType, h) == vpiExpr);
  UHDM::UHDM_OBJECT_TYPE h_type = (UHDM::UHDM_OBJECT_TYPE)((const uhdm_handle *)h)->type;
  std::cout << "printOperandsInExpr | Type: " << UHDM::UhdmName(h_type) << std::endl;
  switch(((const uhdm_handle *)h)->type) {
    case UHDM::uhdmoperation :  {
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
      std::list <std::string> tmp = visitExpr(pat, false, constOnly);
      assert(tmp.size() <= 1);
      if(tmp.size() == 1) {
        out->insert(tmp.front());
        std::cout << tmp.front() << std::endl;
      }
      break;
    }
    default: {
      //if(vpiHandle actual_h = vpi_handle(vpiActual, h)) 
      //  h = actual_h;
      bool constOnly;
      std::list <std::string> tmp = visitExpr(h, false, constOnly);
      assert(tmp.size() <= 1);
      if(tmp.size() == 1) {
        out->insert(tmp.front());
        std::cout << tmp.front() << std::endl;
      }
      break;
    }
  }
  if(print) {
    std::cout << "Operands in given expression:" << std::endl;
    for (auto const& ops: *out)
      std::cout << "\t" << ops << std::endl;
  }
  return;
}

//void visitAssignmentForDependencies(vpiHandle h, bool isProcedural = false) {
//  // TODO: if LHS is like a[i], or {a,...} what to do?
//
//  // clear rhsOperands -- once per assignment
//  rhsOperands.clear();
//
//  std::cout << "Walking assignment for dependency generation\n";
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
//    std::cout << "Walking RHS | Type: "
//      << UHDM::UhdmName(rhs_type) << std::endl;
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
//      std::cout << "Walking LHS | Type: "
//        << UHDM::UhdmName((UHDM::UHDM_OBJECT_TYPE)((const uhdm_handle *)lhs)->type) << std::endl;
//      std::string lhsStr;
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
//          std::list <std::string> tmp = visitExpr(lhs);
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
//        std::cout << "Dependencies:"<< std::endl << lhsStr << std::endl;
//
//        // TODO we are potentially misrepresenting (on lhs):
//        //   part-sel, bit-sel, etc. (Retain hier map?)
//        //   They probably cannot be matched with variable names later
//        for (const auto& value: rhsOperands) {
//          lhs2rhsMultiMap.insert({lhsStr, value});
//          std::cout << "\t<< " << value << std::endl;
//        }
//
//        if(isProcedural) {
//          regSet.insert(lhsStr);
//          std::cout << "LHS is procedural\n";
//        } else {
//          wireSet.insert(lhsStr);
//          std::cout << "LHS is continuous\n";
//        }
//
//        if(rhs_type == UHDM::uhdmoperation) {
//          // TODO function to return mux select string based on assignment
//          std::list <std::string> select_sigs;
//          findMuxesInOperation(rhs, select_sigs);
//          if(!select_sigs.empty()) {
//            std::cout << "LHS is muxOutput\n";
//            for(auto const& el : select_sigs)
//              muxOutput.insert({lhsStr, el});
//          } else std::cout << "LHS is not muxOutput\n";
//        } else {
//          std::cout << "Not found operation in assigment\n";
//        }
//
//        rhsOperands.clear();
//      }
//      vpi_release_handle(lhs);
//    } else
//      std::cout << "Assignment without LHS handle\n";
//
//    vpi_release_handle(rhs);
//  } else 
//    std::cout << "Assignment without RHS handle\n";
//}
//
//void visitAssignment(vpiHandle h) {
//  // both vpiContAssign and vpiAssign
//  std::cout << "Walking assignment | file: "
//    << vpi_get_str(vpiFile, h) << ":" << vpi_get(vpiLineNo, h) << std::endl;
//  if(vpiHandle rhs = vpi_handle(vpiRhs, h)) {
//    std::cout << "Walking RHS | Type: "
//      << UHDM::UhdmName((UHDM::UHDM_OBJECT_TYPE)((const uhdm_handle *)rhs)->type) << std::endl;
//    if(((uhdm_handle *)rhs)->type == UHDM::uhdmoperation) {
//      std::cout << "Walking operation" << std::endl;
//      std::list <std::string> buffer;
//      findMuxesInOperation(rhs, buffer);
//    } else
//      std::cout << "Not an operation on the RHS" << std::endl;
//
//    vpi_release_handle(rhs);
//  } else {
//    std::cout << "No RHS handle on the assignment" << std::endl;
//  }
//  return;
//}
//
//void visitBlocks(vpiHandle h) {
//  // always_ff, always_comb, always and possibly others are all recognized here
//  std::cout << "Block type: " 
//    << UHDM::UhdmName((UHDM::UHDM_OBJECT_TYPE)((const uhdm_handle *)h)->type) << std::endl;
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
//        std::cout << "Found event control\n";
//        visitBlocks(h);
//      } else
//        std::cout << "UNRECOGNIZED uhdmstmt type: " << UHDM::UhdmName((UHDM::UHDM_OBJECT_TYPE)((const uhdm_handle *)h)->type) << std::endl;
//      break;
//    case UHDM::uhdmcase_stmt :
//      std::cout << "Case statement found\n";
//      visitCase(h);
//      break;
//    case UHDM::uhdmif_stmt :
//    case UHDM::uhdmelse_stmt : 
//    case UHDM::uhdmif_else :
//      std::cout << "If/IfElse statement found\n";
//      visitIfElse(h);
//      if(vpiHandle el = vpi_handle(vpiElseStmt, h)) {
//        std::cout << "Else statement found\n";
//        visitIfElse(el);
//      } else std::cout << "Didn't find else statement\n";
//      break;
//    case UHDM::uhdmalways : {
//      vpiHandle newh = vpi_handle(vpiStmt, h);
//      visitBlocks(newh);
//      vpi_release_handle(newh);
//      break;
//    }
//    case UHDM::uhdmassignment : {
//      // uses the same visitor for contAssign
//      std::cout << "Assignment found | Type: " << (global_always_ff_flag ? "Procedural" : "Continuous") << std::endl;
//      //visitAssignmentForDependencies(h, global_always_ff_flag); // this helps distinguish reg assignment from always_comb's wire assignment
//      visitAssignment(h);
//      break;
//    }
//    default :
//      if(vpiHandle newh = vpi_handle(vpiStmt, h)) {
//        std::cout << "UNKNOWN type; but statement found inside\n";
//        visitBlocks(newh);
//      } else {
//        std::cout << "UNKNOWN type; skipping processing this node\n";
//        //Accommodate all cases eventually
//      }
//      break;
//  }
//  return;
//}
//
//void findTernaryInOperation(vpiHandle h) {
//  std::string out = "";
//  std::cout << "Checking if operand is ternary\n";
//  if(((uhdm_handle *)h)->type == UHDM::uhdmoperation) {
//    const int nk = vpi_get(vpiOpType, h);
//    //std::cout << "Type " << UHDM::UhdmName((UHDM::UHDM_OBJECT_TYPE)nk) << "\n";
//    if(nk == 32) {
//      std::cout << "An operand is ternary\n";
//      std::list <std::string> buffer;
//      visitTernary(h, buffer); // TODO WRONG
//    }
//
//  }
//  return;
//}

//void printRecursiveDependents(std::string ref, std::unordered_set<std::string> *out, bool print=false) {
//  if (dependenciesStr.find(ref) != dependenciesStr.end()) {
//    std::unordered_set <std::string> deps = dependenciesStr[ref];
//    for (auto const& it: deps) {
//      std::cout << "\t\t<< " << it << std::endl;
//      printRecursiveDependents(it, out);
//    }
//    out->insert(deps.begin(), deps.end());
//  } else
//    std::cout << "\t\tDependents not found for: " << ref << std::endl;
//
//  out->insert(ref);
//
//  if(print)
//    for (auto const& it: *out)
//      std::cout << "\t\tSo, final list of dependents: " << it << std::endl;
//  return;
//}
//
// takes in an operation and produces a list of strings
void visitTernary(vpiHandle h, std::list<std::string> &current) {
  //std::list <std::unordered_set <std::string>> csv; // has to be a list to preserve hierarchical parental order, for progressive coverage
  std::cout << "Analysing ternary operation\n";
  bool first = true;
  if(vpiHandle i = vpi_iterate(vpiOperand, h)) {
    while (vpiHandle op = vpi_scan(i)) {
      std::cout << "Walking "  << (first ? "condition" : "second/third") << " operand | Type: "  << ((const uhdm_handle *)op)->type << std::endl;

      switch(((const uhdm_handle *)op)->type) {
        case UHDM::uhdmoperation :
          {
            std::cout << "Operation found in ternary\n";
            if(isOpTernary(op)) {
              visitTernary(op, current);
            }
            if(first) {
              std::list <std::string> out;
              bool k;
              std::tie(k, out) = visitOperation(op);
              // minor TODO  based on k, return a string (of the choice made in the tern)
              current.insert(current.end(), out.begin(), out.end());

              // this is for progressive coverage
              //UHDM::any* op_obj = (UHDM::any *)(((uhdm_handle *)op)->object);
              //std::cout << "Finding dependenciesStr of an Expr:" << UHDM::vPrint(op_obj) << std::endl;
              //std::unordered_set <std::string> operands;
              //printOperandsInExpr(op, &operands, true);

              //std::unordered_set<std::string> depsSet;
              //for (auto &ref : operands) {
              //  std::cout << "\tDependency on Operand: " << ref << std::endl;
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
            std::cout << "Leaf found in ternary\n";
            /* For now, the below has the following issues that need to be fixed by Surelog:
             * Parameter values are not printed despite being resolved at this point
             * (Some) variables used within genBlk that are defined outside of the genBlk have genBlk in thier hier paths
             * Not all wires and logics print their fullNames
             * But once these are fixed, vPrint would be a far cleaner efficient way to print these
             */
            //UHDM::any* op_obj = (UHDM::any *)(((uhdm_handle *)op)->object);
            //current.push_back(UHDM::vPrint(op_obj));
            bool constOnly;
            std::list <std::string> tmp = visitExpr(op, true, constOnly);
            current.insert(current.end(), tmp.begin(), tmp.end());


            // TODO Do this for hier path (not operations) 
            //assert(tmp.size() == 1);
            //std::cout << "Checking dependents on " << tmp.front() << std::endl;
            //std::unordered_set <std::string> depsSet;
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
    std::cout << "Couldn't iterate through operands" << std::endl;

  std::cout << "Saving ternaries...\n";
  print_list(current);
  ternaries.insert(ternaries.end(), current.begin(), current.end());
  //csvs.insert(csvs.end(), csv.begin(), csv.end());
  all.insert(all.end(), current.begin(), current.end());
  return;
}

int evalExpr(vpiHandle h, bool& found) {
  std::cout << "In evalExpr | type: " << UHDM::UhdmName((UHDM::UHDM_OBJECT_TYPE)((const uhdm_handle *)h)->type) << std::endl;

  if(char *c = vpi_get_str(vpiName, h)) {
    std::cout << "Looking up: " << c << std::endl;
    auto range = running_const.find(c);
    if(range != running_const.end()) {
      std::cout << "Found running_const\n";
      std::cout << c << " was found to be " << range->second << std::endl;
      found = true;
      return range->second;
    } else std::cout << "Not found in running_const\n";
  }

  if(char *c = vpi_get_str(vpiFullName, h)) {
    std::cout << "Looking up: " << c << std::endl;
    auto range = params.find(c);
    if(range != params.end()) {
      std::cout << "Found param\n";
      std::cout << c << " was found to be " << range->second << std::endl;
      found = true;
      return range->second;
    } else std::cout << "Not found in param\n";
  }

  if(vpiHandle actual = vpi_handle(vpiActual, h)) {
    std::cout << "Found actual; recursing" << std::endl;
    return evalExpr(actual, found);
  }
  else  {
    if(const char *tmp = vpi_get_str(vpiDecompile, h)) {
      std::cout << "Found non-actual " << tmp << std::endl;
      s_vpi_value value;
      vpi_get_value(h, &value);
      found = true;
      if(value.format) {
        return value.value.integer;
      } else
        return stoi(std::string(tmp));
    }
    else walker_error("Actual doesn't exists, no decompile");
  }

  walker_error("Unable to resolve consant");
  return 0;
}

std::string evalOperation(vpiHandle h) {
  //Some supported evaluatable operations we support
  std::cout <<"In evalOperation | type: " << UHDM::UhdmName((UHDM::UHDM_OBJECT_TYPE)((const uhdm_handle *)h)->type) << std::endl;
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
            if(!found)
              walker_error("Did not really evaluate the function, check `found`");
            op++;
            break;
        }
      }
      vpi_release_handle(opi);
    } else walker_error("Couldn't iterate on operands");

    const int type = vpi_get(vpiOpType, h);
    std::cout << "Operation type in eval: " << UHDM::UhdmName((UHDM::UHDM_OBJECT_TYPE)type) << "(" << std::to_string(type) << ")" << std::endl;
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
  std::cout << "Done evaluating operation\n";

  return std::to_string(result);
}

//int width(vpiHandle h, int *ptr) {
//  //std::cout << "Calculating width\n";
//  vpiHandle ranges;
//  std::string out;
//  int dims=0;
//  int *w;
//  w = ptr;
//  if((ranges = vpi_iterate(vpiRange, h))) {
//    //std::cout << "Range found\n";
//    while (vpiHandle range = vpi_scan(ranges) ) {
//      if(dims < 4) {
//        //std::cout << "New dimension\n";
//        dims++;
//        vpiHandle lh = vpi_handle(vpiLeftRange, range);
//        vpiHandle rh = vpi_handle(vpiRightRange, range);
//        *w = evalExpr(lh) - evalExpr(rh) + 1;
//        std::cout << "\t\tRange: " << *w << std::endl;
//        w++;
//        vpi_release_handle(lh);
//        vpi_release_handle(range);
//      } else walker_error("Dimension overflow!");
//    }
//  } else {
//    //meaning either a bit or an unknown range
//    std::cout << "\t\tRange: 1\n";
//    *w = 1;
//    dims++;
//  }
//  vpi_release_handle(ranges);
//  return dims;
//}
//
//void visitPorts(vpiHandle h) {
//  std::cout << "Walking ports\n";
//  while (vpiHandle p = vpi_scan(h)) {
//    std::cout << vpi_get_str(vpiName, p) << std::endl;
//    if(vpi_get(vpiDirection, p) == 2) {
//      std::cout << "\tOutput port\n";
//      vpiHandle lowConn = vpi_handle(vpiLowConn, p);
//      std::cout << "\t\tLow conn name: " << vpi_get_str(vpiFullName, lowConn) << std::endl;
//      vpiHandle highConn = vpi_handle(vpiHighConn, p);
//      std::unordered_set<std::string> parents;
//      // LowConn is always ref_obj (IO port)
//      if(highConn) {
//        std::cout << "\t\tHigh conn type: " << UHDM::UhdmName((UHDM::UHDM_OBJECT_TYPE)((const uhdm_handle *)highConn)->type);
//        if(((const uhdm_handle *)highConn)->type == UHDM::uhdmref_obj) {
//          std::cout << " | Ref name: " << vpi_get_str(vpiFullName, highConn);
//        } else if(((const uhdm_handle *)highConn)->type == UHDM::uhdmoperation) {
//          const int type = vpi_get(vpiOpType, highConn);
//          std::cout << " | Op type: " << UHDM::UhdmName((UHDM::UHDM_OBJECT_TYPE)type) << "(" << std::to_string(type) << ")";
//        }
//      }
//      std::cout << std::endl;
//      traverse(lowConn, 0, parents, covs);
//    } else if(vpi_get(vpiDirection, p) == 1) {
//      std::cout << "\tInput port; ignored\n";
//      // TODO check if this is included in vpiVaribales/vpiNet
//    }
//  }
//}

//void visitNets(vpiHandle i, bool net) {
//  std::cout << "Walking variables\n";
//  while (vpiHandle h = vpi_scan(i)) {
//    std::string out = "";
//    switch(((const uhdm_handle *)h)->type) {
//      case UHDM::uhdmstruct_var :
//      case UHDM::uhdmstruct_net : {
//        //std::cout << "Finding width of struct\n";
//        std::string base = vpi_get_str(vpiFullName, h);
//        if(vpiHandle ts = vpi_handle(vpiTypespec, h)) {
//          //std::cout << "Finding Typespec\n";
//          if(vpiHandle tsi = vpi_iterate(vpiTypespecMember, ts)) {
//            //std::cout << "Found TypespecMember\n";
//            while(vpiHandle tsm = vpi_scan(tsi)) {
//              //std::cout << "Iterating\n";
//              vpiHandle tsmts = vpi_handle(vpiTypespec, tsm);
//              int t = vpi_get(vpiNetType, tsmts);
//              struct vars tmp;
//              tmp.type = t == 48 ? "Reg" :
//                "Wire(" + UHDM::UhdmName((UHDM::UHDM_OBJECT_TYPE)((const uhdm_handle *)tsmts)->type) + ")";
//              tmp.name = base + ".";
//              tmp.name += vpi_get_str(vpiName, tsm);
//              tmp.dims = width(tsmts, tmp.width);
//              netsCurrent.push_back(tmp);
//              std::cout << "\t" << tmp.name << std::endl;
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
//        std::cout << "\t" << tmp.name << std::endl;
//        tmp.dims = width(h, tmp.width);
//        netsCurrent.push_back(tmp);
//        break;
//      }
//    }
//    vpi_release_handle(h);
//  }
//  std::cout << "No more nets\n";
//  vpi_release_handle(i);
//  return;
//}
//
// find the parameter/paramAssign name (not full name), and value (at elaboration)
// and store them in std::map params for later retrieval
void visitParameters(vpiHandle pi) {
  while (vpiHandle ps = vpi_scan(pi)) {
    if(const char *s = vpi_get_str(vpiName, ps)) {
      std::string pname = s;
      const UHDM::parameter *op_obj = (const UHDM::parameter *)(((uhdm_handle *)ps)->object);
      std::string_view pval = op_obj->VpiValue();

      int pstr = std::atoi(ltrim(pval, ':').data());
      params.insert(std::pair<std::string, int>(pname, pstr));
    }
  }
}

void visitParamAssignment(vpiHandle p) {
  while(vpiHandle h = vpi_scan(p)) {
    //std::cout << "Found a handle " << ((const uhdm_handle *)h)->type << "\n";
    std::string name = "";
    if(vpiHandle l = vpi_handle(vpiLhs, h)) {
      name = vpi_get_str(vpiFullName, l);
      std::cout << "\t" << name << std::endl;
      vpi_release_handle(l);
    } else {
      std::cout << "Unable to find name of param\n";
      name = "UNKNOWN";
    }
    if(vpiHandle r = vpi_handle(vpiRhs, h)) {
      //std::cout << "Found a handle " << ((const uhdm_handle *)r)->type << "\n";
      switch(((const uhdm_handle *)r)->type) {
        case UHDM::uhdmconstant: {
          s_vpi_value value;
          vpi_get_value(r, &value);
          if(value.format) {
            std::cout << "\t\tFound const assignment: " << std::to_string(value.value.integer) << std::endl;
            params.insert(std::pair<std::string, int>(name, value.value.integer));
          } else
            std::cout << "Unable to resolve constant\n";
          break;
        } 
        case UHDM::uhdmparameter: {
          std::map <std::string, int>::iterator it;
          it = params.find(name);
          if(it == params.end()) {
            std::cout << "Can't find definition of param: " << name << std::endl;
            params.insert(std::pair<std::string, int>(name, 0));
          } else {
            std::cout << "Found existing param: " << it->second << std::endl;
            params.insert(std::pair<std::string, int>(name, it->second));
          }
          break;
        }
        case UHDM::uhdmoperation: 
          std::cout << "Unexpected operation in parameter assignment\n";
        default:
          std::cout << "Didn't find a constant of param in param assignment\n";
          break;
      }
      vpi_release_handle(r);
    } else {
      std::cout << "Didn't find RHS of param assignment!!\n";
    }
  }
  return;
}


void visitTopModules(vpiHandle ti) {
  std::cout << "Exercising iterator\n";
  while(vpiHandle th = vpi_scan(ti)) {
    std::cout << "Top module handle obtained\n";
    if (vpi_get(vpiType, th) != vpiModule) {
      std::cout << "Not a module\n";
      return;
    }

    //lambda for module visit
    std::function<void(vpiHandle, std::string)> visit =
      [&visit](vpiHandle mh, std::string depth) {

        std::string out_f;
        std::string defName;
        std::string objectName;
        if (const char* s = vpi_get_str(vpiDefName, mh)) {
          defName = s;
        }
        if (const char* s = vpi_get_str(vpiName, mh)) {
          if (!defName.empty()) {
            defName += " ";
          }
          objectName = std::string("(") + s + std::string(")");
        }
        std::string file = "";
        if (const char* s = vpi_get_str(vpiFile, mh))
          file = s;
        std::cout << "Walking module: " + defName + objectName + "\n";// + 
        std::cout << "\t File: " + file + ", line:" + std::to_string(vpi_get(vpiLineNo, mh)) + "\n";

        // Params
        //std::cout << "****************************************\n";
        //std::cout << "      ***  Now finding params        ***\n";
        //std::cout << "****************************************\n";
        //// TODO this is not helping (recheck)
        //if(vpiHandle pi = vpi_iterate(vpiParameter, mh)) {
        //  std::cout << "Found parameters\n";
        //  visitParameters(pi);
        //} else std::cout << "No parameters found in current module\n";

        //if(vpiHandle pai = vpi_iterate(vpiParamAssign, mh)) {
        //  std::cout << "Found paramAssign\n";
        //  visitParamAssignment(pai);
        //} else std::cout << "No paramAssign found in current module\n";
        //std::cout << "\nFinal list of params:\n";
        //std::map<std::string, int>::iterator pitr;
        //for (pitr = params.begin(); pitr != params.end(); ++pitr)
        //  std::cout << pitr->first << " = " << pitr->second << std::endl;

        // Variables are storing elements (reg, logic, integer, real, time)
        //   includes some _s that appear in always_ff/comb
        //   does not include IO declared as "output logic"
        // XXX because this includes logic, and also those assigned within always_comb, this list cannot be relied upon to mean possible LHSs of procedural assignments
        //std::cout << "****************************************\n";
        //std::cout << "      ***  Now finding variables     ***\n";
        //std::cout << "****************************************\n";
        //if(vpiHandle vi = vpi_iterate(vpiVariables, mh)) {
        //  std::cout << "Found variables\n"; 
        //  visitNets(vi, false);
        //} else std::cout << "No variables found in current module\n";
        //std::cout << "Done with vars\n";

        //// Nets (wire, tri) -> includes IO, _cast_i, _cast_o, some _s
        //std::cout << "****************************************\n";
        //std::cout << "      ***     Now finding nets       ***\n";
        //std::cout << "****************************************\n";
        //if(vpiHandle ni = vpi_iterate(vpiNet, mh)) {
        //  std::cout << "Found nets\n";
        //  visitNets(ni, true);
        //} else std::cout << "No nets found in current module\n";

        //// ContAssigns:
        //std::cout << "****************************************\n";
        //std::cout << "      *** Now finding cont. assigns  ***\n";
        //std::cout << "****************************************\n";
        //vpiHandle cid = vpi_iterate(vpiContAssign, mh);
        //vpiHandle ci = vpi_iterate(vpiContAssign, mh);
        //// finds both when decared as:
        ////   wire x = ...
        ////   assign x = ...
        //if(ci) {
        //  std::cout << "Found continuous assign statements \n";
        //  while (vpiHandle ch = vpi_scan(cid)) {
        //    std::cout << "ContAssignDep Info -> " <<
        //      std::string(vpi_get_str(vpiFile, ch)) <<
        //      ", line:" << std::to_string(vpi_get(vpiLineNo, ch)) << std::endl;
        //    visitAssignmentForDependencies(ch);
        //    // TODO record a bool for tern operations
        //    // vpi_release_handle(ch); // TODO: check if it releases the data node, not just ptr
        //  }
        //  while (vpiHandle ch = vpi_scan(ci)) {
        //    std::cout << "ContAssign Info -> " <<
        //      std::string(vpi_get_str(vpiFile, ch)) <<
        //      ", line:" << std::to_string(vpi_get(vpiLineNo, ch)) << std::endl;
        //    visitAssignment(ch);
        //    vpi_release_handle(ch);
        //  }
        //  vpi_release_handle(ci);
        //} else std::cout << "No continuous assign statements found in current module\n";

        ////Process blocks: always_*, initial, final blocks
        //// vpiAlwaysType distinguishes always type (ff, comb, latch, _)
        //std::cout << "****************************************\n";
        //std::cout << "      *** Now finding process blocks ***\n";
        //std::cout << "****************************************\n";
        //vpiHandle ai = vpi_iterate(vpiProcess, mh);
        //if(ai) {
        //  std::cout << "Found always block\n";
        //  while(vpiHandle ah = vpi_scan(ai)) {
        //    std::cout << "vpiProcess Info -> " <<
        //      std::string(vpi_get_str(vpiFile, ah)) <<
        //      ", line:" << std::to_string(vpi_get(vpiLineNo, ah)) << std::endl;
        //    global_always_ff_flag = vpi_get(vpiAlwaysType, ah) == 3;
        //    visitBlocks(ah);
        //    vpi_release_handle(ah);
        //  }
        //  vpi_release_handle(ai);
        //} else std::cout << "No always blocks in current module\n";

        std::cout << "****************************\n";
        std::cout << "**** Precision coverage ****\n";
        std::cout << "****************************\n";
        parse_module(mh, nullptr);
        // module_ds_map now has a struct with all the data structures
        std::cout << "Done parsing module\n";

        std::unordered_set<std::string> parents;
        std::unordered_set<std::pair<std::string, int>, PairHash> covs;
        if(vpiHandle ports = vpi_iterate(vpiPort, mh)) {
          std::cout << "**************\n";
          std::cout << "Parsing ports:\n";
          std::cout << "**************\n";
          while (vpiHandle p = vpi_scan(ports)) {
            if(vpi_get(vpiDirection, p) == 2) { // ignoring inout
              char *portName = vpi_get_str(vpiName, p);
              // ports have no fullName (perhaps because these are just pins?)
              if(portName) {
                std::cout << "Found output port " << portName << "; traversing...\n";
                vpiHandle lowConn = vpi_handle(vpiLowConn, p);
                std::string low_conn_full_name = vpi_get_str(vpiFullName, lowConn);
                std::cout << "Traverse function start:\n";

                traverse(low_conn_full_name, mh, 0, parents, covs, "");
              }
            }
          }
          std::cout << "*** End of precision coverage ***\n";
          std::cout << "Precision coverage dump:\n";
          print_unordered_set(covs, true, outputDir / "cp.csv");
        }




        // Ports of the current module, NOT of submodules
        //std::cout << "****************************************\n";
        //std::cout << "      ***  Now finding ports         ***\n";
        //std::cout << "****************************************\n";
        //if(vpiHandle ports = vpi_iterate(vpiPort, mh)) {
        //  std::cout << "Found ports\n";
        //  visitPorts(ports);
        //  vpi_release_handle(ports);
        //} else std::cout << "No ports found in current module\n";
        //std::cout << "Done with ports\n";

        // Accumulate variables:
        nets.insert(nets.end(), netsCurrent.begin(), netsCurrent.end());
        netsCurrent.clear();
        paramsAll.insert(params.begin(), params.end());
        params.clear();

        std::cout << "**** STATS FOR THE MODULE ****\n";
        std::cout << "\nFound " << muxOutput.size() << " mux outputs in current module:\n";
        for (auto const& it : muxOutput)
          std::cout << "\t>> " << it.first << std::endl;

        muxOutput.clear();

        //Statistics:
        static int numTernaries, numIfs, numCases;
        nTernaries.push_back(0);//ternaries.size() - numTernaries);
        nIfs.push_back(ifs.size() - numIfs);
        nCases.push_back(cases.size() - numCases);
        std::cout << "Block: " << defName + objectName << " | numTernaries: " << ternaries.size() - numTernaries << " | numCases: " << cases.size() - numCases << " | numIfs: " << ifs.size() - numIfs << std::endl; 
        numTernaries = ternaries.size();
        numIfs       = ifs.size();
        numCases     = cases.size();

        // Recursive tree traversal
        //        vpiHandle m = vpi_iterate(vpiModule, mh);
        //        if(m) {
        //          while (vpiHandle h = vpi_scan(m)) {
        //            std::cout << "Iterating next module\n";
        //            depth = depth + "  ";
        //            std::string submod_name = vpi_get_str(vpiName, h);
        //            std::cout << "Name of submodule: " << submod_name << std::endl;
        //            //char* cstr = new char[submod_name.length() + 1];
        //            //std::strcpy(cstr, submod_name.c_str());
        //            //vpiHandle aah = vpi_handle_by_name(cstr, mh);
        //            //if(aah)
        //            //  std::cout << "WORKED!!\n";
        //            visit(h, depth);
        //            vpi_release_handle(h);
        //          }
        //          vpi_release_handle(m);
        //        }
        //        vpiHandle ga = vpi_iterate(vpiGenScopeArray, mh);
        //        if(ga) {
        //          while (vpiHandle h = vpi_scan(ga)) {
        //            std::cout << "Iterating genScopeArray\n";
        //            vpiHandle g = vpi_iterate(vpiGenScope, h);
        //            while (vpiHandle gi = vpi_scan(g)) {
        //              std::cout << "Iterating genScope\n";
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

  std::string out = "";

  std::cout << "UHDM Elaboration...\n";
  UHDM::Serializer serializer;
  UHDM::ElaboratorListener* listener =
    new UHDM::ElaboratorListener(&serializer, false);
  listener->listenDesigns({the_design});
  delete listener;
  std::cout << "Listener in place\n";

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
  std::cout << "Output dir for *.sigs: "<< outputDir << std::endl;

  if (the_design) {
    UHDM::design* udesign = nullptr;
    if (vpi_get(vpiType, the_design) == vpiDesign) {
      // C++ top handle from which the entire design can be traversed using the
      // C++ API
      udesign = UhdmDesignFromVpiHandle(the_design);
      std::cout << "Design name (C++): " << udesign->VpiName() << "\n";
    }
    // Example demonstrating the classic VPI API traversal of the folded model
    // of the design Flat non-elaborated module/interface/packages/classes list
    // contains ports/nets/statements (No ranges or sizes here, see elaborated
    // section below)
    std::cout << "Design name (VPI): " + std::string(vpi_get_str(vpiName, the_design)) + "\n";
    // Flat Module list:
    std::cout << "Module List:\n";
    //      topmodule -- instance scope
    //        allmodules -- assign (ternares), always (if, case, ternaries)

    vpiHandle ti = vpi_iterate(UHDM::uhdmtopModules, the_design);
    if(ti) {
      std::cout << "Walking uhdmtopModules\n";
      // The walk
      visitTopModules(ti);
    } else std::cout << "No uhdmtopModules found!\n";
  } else std::cout << "No design found!\n";


  //std::cout << "\n\n\n*** Printing all conditions ***\n\n\n";
  //print_list(all, true, outputDir / "all.sigs");
  //std::cout << "\n\n\n*** Printing case conditions ***\n\n\n";
  //print_list(cases, true, outputDir / "case.sigs");
  //std::cout << "\n\n\n*** Printing if/if-else conditions ***\n\n\n";
  //print_list(ifs, true, outputDir / "if.sigs");
  //std::cout << "\n\n\n*** Printing ternary conditions ***\n\n\n";
  //print_list(ternaries, true, outputDir / "tern.sigs");
  //std::cout << "\n\n\n*** Printing regSet ***\n\n\n";
  //print_list(regSet, true, outputDir / "all.regs");
  //std::cout << "\n\n\n*** Printing wireSet ***\n\n\n";
  //print_list(wireSet, true, outputDir / "all.wires");
  ////std::cout << "\n\n\n*** Printing Precise CoverPoints ***\n\n\n";
  ////print_list(outputDir / "precision.sigs");
  //std::cout << "\n\n\n*** Printing CSV ***\n\n\n";
  //print_csvs(outputDir / "tern.csv");
  //std::cout << "\n\n\n*** Printing Dependencies ***\n\n\n";
  //print_list(dependenciesStr, true, outputDir / "all.deps");

  //std::cout << "\n\n\n*** Printing variables ***\n\n\n";
  //std::ofstream file;
  //file.open("../surelog.run/all.nets", std::ios_base::out);
  //for (auto const &i: nets) {
  //  file << i.name << " ";
  //  int k=0;
  //  while(k<i.dims) {
  //    file << i.width[k] << " ";
  //    k++;
  //  }
  //  file << std::endl;
  //}
  //file.close();
  //std::cout << "\n\n\n*** Printing params ***\n\n\n"; //why?
  //file.open("../surelog.run/all.pars", std::ios_base::out);
  //std::map<std::string, int>::iterator itr;
  //for (itr = paramsAll.begin(); itr != paramsAll.end(); ++itr)
  //  file << itr->first << " = " << itr->second << std::endl;
  //file.close();


  std::cout << "\n\n\n*** Parsing Complete!!! ***\n\n\n";


  // Do not delete these objects until you are done with UHDM
  SURELOG::shutdown_compiler(compiler);
  delete clp;
  delete symbolTable;
  delete errors;
  return code;
}
