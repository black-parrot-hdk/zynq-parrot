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

#define walker_warn(x) debug("WARN: " << x << endl)
#define walker_error(x) debug("ERROR: " << x << endl); exit(0)

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

// Define a hash function for pair
struct PairHash {
  template <class T1, class T2>
    size_t operator()(const pair<T1, T2>& p) const {
      auto hash1 = hash<T1>{}(p.first);
      auto hash2 = hash<T2>{}(p.second);
      return hash1 ^ hash2; // Combine the hash values
    }
};

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

// ancillary functions
static string_view ltrim(string_view str, char c) {
  auto pos = str.find(c);
  if (pos != string_view::npos) str = str.substr(pos + 1);
  return str;
}

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
