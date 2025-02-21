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
using namespace UHDM;

#define DEBUG_PRINT 1

#if DEBUG_PRINT
#define debug(x) cout << x;
#else
#define debug(x)
#endif

#define walker_warn(x) debug("WARNING: " << x << endl)
#define walker_error(x) {debug("ERROR: " << x << endl); exit(0);}

static unordered_map<int32_t, string> unaryOp = {
    {vpiMinusOp, "-"},    {vpiPlusOp, "+"},
    {vpiNotOp, "!"},      {vpiBitNegOp, "~"},
    {vpiUnaryAndOp, "&"}, {vpiUnaryNandOp, "~&"},
    {vpiUnaryOrOp, "|"},  {vpiUnaryNorOp, "~|"},
    {vpiUnaryXorOp, "^"}, {vpiUnaryXNorOp, "~^"},
    {vpiPreIncOp, "++"},  {vpiPreDecOp, "--"},
};

static unordered_map<int32_t, string> binaryOp = {
    {vpiSubOp, "-"},
    {vpiDivOp, "/"},
    {vpiModOp, "%"},
    {vpiEqOp, "=="},
    {vpiNeqOp, "!="},
    {vpiCaseEqOp, "==="},
    {vpiCaseNeqOp, "!=="},
    {vpiGtOp, ">"},
    {vpiGeOp, ">="},
    {vpiLtOp, "<"},
    {vpiLeOp, "<="},
    {vpiLShiftOp, "<<"},
    {vpiRShiftOp, ">>"},
    {vpiAddOp, "+"},
    {vpiMultOp, "*"},
    {vpiLogAndOp, "&&"},
    {vpiLogOrOp, "||"},
    {vpiBitAndOp, "&"},
    {vpiBitOrOp, "|"},
    {vpiBitXorOp, "^"},
    {vpiBitXNorOp, "^~"},
    {vpiArithLShiftOp, "<<<"},
    {vpiArithRShiftOp, ">>>"},
    {vpiPowerOp, "**"},
    {vpiImplyOp, "->"},
    {vpiNonOverlapImplyOp, "|=>"},
    {vpiOverlapImplyOp, "|->"},
};

[[nodiscard]] static string ltrim(string str, char c, bool left_to_right) {
  auto pos = left_to_right ? str.find(c) : str.rfind(c);
  if (pos != string::npos) str = str.substr(pos + 1);
  return str;
}

[[nodiscard]] static string rtrim(string str, char c, bool left_to_right) {
  auto pos = left_to_right ? str.find(c) : str.rfind(c);
  if (pos != string::npos) str = str.substr(0, pos);
  return str;
}

[[nodiscard]] static string ptrim(string str, string prefix) {
  if(str.find(prefix) == 0)
    return str.substr(prefix.length());
  else
    walker_error("Wrong prefix: " << str);
}

struct token_t {
    string text;
    bool isDelimiter;
};

static vector<token_t> splitStringWithDelimiters(const string& str, const vector<string>& delimiters) {
    vector<token_t> tokens;
    size_t start = 0, min_pos, delim_length;

    while (start < str.length()) {
        min_pos = string::npos;
        delim_length = 0;
        string found_delim;

        // Find the nearest delimiter
        for (const auto& delim : delimiters) {
            size_t pos = str.find(delim, start);
            if (pos < min_pos) {
                min_pos = pos;
                delim_length = delim.length();
                found_delim = delim;
            }
        }

        // Extract token before the delimiter
        if (min_pos != string::npos) {
            if (min_pos > start) {
                tokens.push_back({str.substr(start, min_pos - start), false});
            }
            // Store the delimiter itself
            tokens.push_back({found_delim, true});
            start = min_pos + delim_length; // Move past the delimiter
        } else {
            // Last token after the last delimiter
            tokens.push_back({str.substr(start), false});
            break;
        }
    }
    return tokens;
}

static string genScopeNetFix(string net, string_view scope, string_view label, unordered_set<string_view>* locals) {
  // if a local signal return as is
  for(auto local : *locals) {
    if(net == local)
      return net;
  }

  // if not in current scope return as is
  if(net.find(string(scope) + ".") == string::npos)
    return net;

  // if not, remove genscope label
  cout << "(" << label << "): " << net << " -> ";
  string token = string(label) + ".";
  auto pos = net.rfind(token);
  if(pos != string::npos) net.erase(pos, token.length());
  cout << net << endl;
  return net;
}

static string genScopeExprFix(string ex, string_view scope, string_view label, unordered_set<string_view>* locals) {
  vector<string> delimiters = {"(", ")", "[", "]", "inside", "{", "}", ",", "?", ":"};
  for(auto op : unaryOp)
    delimiters.push_back(op.second);
  for(auto op: binaryOp)
    delimiters.push_back(op.second);

  // split expression into nets
  vector<token_t> tokens = splitStringWithDelimiters(ex, delimiters);

  // process each net
  for(auto& token : tokens) {
    if(!token.isDelimiter) {
      token.text = genScopeNetFix(token.text, scope, label, locals);
    }
  }

  // reconstruct the expression with original delimiters
  ostringstream joined;
  for (const auto& token : tokens) {
      joined << token.text;
  }

  if(ex != joined.str())
    cout << ex << " => " << joined.str() << endl;

  return joined.str();
}

// Netlist structs
class wire_t {
  public:
   string name;
};

class parameter_t: public virtual wire_t {
  public:
    uint64_t val;
};

class port_t: public virtual wire_t {
  public:
    bool isOutput;
    unordered_set<string>* highConns;
    unordered_set<string>* conds;

    port_t(): highConns(new unordered_set<string>())
            , conds(new unordered_set<string>())
            {}
};

class net_t: public virtual wire_t {
  public:
    unordered_set<string>* rhs;
    bool isReg = false;
    unordered_set<string>* conds;

    net_t(): rhs(new unordered_set<string>())
           , conds(new unordered_set<string>())
           {}
};

class module_t {
  public:
    string name;
    string fname;
    string dname;
    map<string, parameter_t*>* params;
    map<string, port_t*>* ports;
    map<string, net_t*>* nets;
    map<string, module_t*>* submods;
    module_t* highmod;
    bool isTop = false;

    module_t(): params(new map<string, parameter_t*>())
              , ports(new map<string, port_t*>())
              , nets(new map<string, net_t*>())
              , submods(new map<string, module_t*>())
              {}

    void addNet(string name, unordered_set<string>* rhs, unordered_set<string>* conds, bool isReg) {
      if(this->nets->find(name) != this->nets->end()) {
        for(auto rhsNet : *rhs)
          this->nets->find(name)->second->rhs->insert(rhsNet);
        for(auto cond : *conds)
          this->nets->find(name)->second->conds->insert(cond);
        this->nets->find(name)->second->isReg = isReg;
      }
      else {
        net_t* net = new net_t();
        net->name = name;
        for(auto rhsNet : *rhs)
          net->rhs->insert(rhsNet);
        for(auto cond : *conds)
          net->conds->insert(cond);
        net->isReg = isReg;
        this->nets->insert({net->name, net});
      }
    }

    void print() {
      cout << "------------------------------" << endl;
      cout << "Module: " << fname << "("  << dname << ")" << endl;

      string prefix = string(fname) + ".";

      cout << "Params:" << endl;
      for(auto p : *params)
        cout << "\t" << ptrim(p.second->name, prefix) << ": " << p.second->val << endl;

      cout << "Ports:" << endl;
      for(auto p : *ports) {
        cout << "\t" << ptrim(p.second->name, prefix) << ": ";
        for(auto hc : *p.second->highConns)
          cout << hc << " ";
        cout << endl;
      }

      cout << "Nets:" << endl;
      for(auto n : *nets) {
        cout << "\t" << ptrim(n.second->name, prefix) << endl;

        if(n.second->isReg)
          cout << "\t\t" << "(R)" << endl;

        if(!n.second->conds->empty()) {
          cout << "\t\t" << "(M)" << endl;
          for(auto cond: *n.second->conds)
            cout << "\t\t\t" << cond << endl;
        }

        cout << "\t\t" << "(RHS)" << endl;
        for(auto rhs : *n.second->rhs)
          cout << "\t\t\t" << ptrim(rhs, prefix) << endl;
      }

      cout << "Submodules:" << endl;
      for(auto m : *submods)
        m.second->print();
    }
};

class cov_t {
  public:
    string name;
    int depth;

    cov_t(string name, int depth) {
      this->name = name;
      this->depth = depth;
    }

    bool operator==(const cov_t& c) const {
        return ((this->name == c.name) && (this->depth == c.depth));
    }
};

class covHash {
  public:
    size_t operator()(const cov_t& c) const {
        return (hash<string>()(c.name)) ^ (hash<int>()(c.depth));
    }
};

unordered_set<cov_t, covHash>* global_visited = new unordered_set<cov_t, covHash>();

string printOperation(const operation* op, map<string_view, int>* vars);
string printExpr(const any* ex, map<string_view, int>* vars);
void netsInExpr(const any* ex, unordered_set<string>* nets, unordered_set<string>* conds, map<string_view, int>* vars);
void evalStmt(module_t* out, const any* st, unordered_set<string>* conds, map<string_view, int>* vars);
void evalParam(module_t* out, const param_assign* pass, const any* inst);
void evalPort(module_t* out, const port* p);
void evalContAssign(module_t* out, const cont_assign* cass, map<string_view, int>* vars);
void evalProcessBlock(module_t* out, const process_stmt* pr, map<string_view, int>* vars);
void evalGenStmt(module_t* out, const gen_stmt* gs, map<string_view, int>* vars);
void evalGenScopeArray(module_t* out, const gen_scope_array* ga, unordered_set<string_view>* locals, map<string_view, int>* vars);
void evalModule(module_t* out, module_inst* m, map<string_view, int>* vars);
void traverseNet(module_t* m, string net, int depth, unordered_set<string>* visited, unordered_set<cov_t, covHash>* covs);
void traverseModule(module_t* m, unordered_set<cov_t, covHash>* covs);
