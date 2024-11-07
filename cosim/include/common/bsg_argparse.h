
#ifndef BSG_ARGPARSE_H
#define BSG_ARGPARSE_H

#include <unistd.h>
#include <string>
#include <cstring>

// Given a string, determine the number of space-separated arguments
static int get_argc(char *args) {
    char *cur = args, prev = ' ';
    int count = 1;
    while (*cur != '\0') {
        if ((prev == ' ') && (prev != *cur)) {
            count++;
        }
        prev = *cur;
        ++cur;
    }
    return count;
}

// Given a string, parse the space-separated arguments
static void get_argv(char *args, char **argv) {
    int count = 0;
    char *cur = args, prev = ' ';

    // First parse the path name. This is not in the argument string because
    // VCS doesn't provide it to us. Instead, we "hack" around it by reading
    // the path from 'proc/self/exe'. The maximum path-name length is 1024,
    // with an extra null character for safety
    static char path[1025] = {'\0'};

    readlink("/proc/self/exe", path, sizeof(path) - 1);
    argv[0] = path;
    count++;

    // Then we parse the remaining arguments. Arguments are separated by N
    // >= 1 spaces. We only register an argument when the previous character
    // was a space, and the current character is not (so that multiple
    // spaces don't count as multiple arguments). We replace spaces with
    // null characters (\0) so that each argument appears to be an
    // individual string and can be used later, by argparse (and other
    // libraries)
    while (*cur != '\0') {
        if ((prev == ' ') && (prev != *cur)) {
            argv[count] = cur;
            count++;
        }
        prev = *cur;
        if (*cur == ' ')
            *cur = '\0';
        cur++;
    }
}

// Extract +c_args argstring from passed command line arguments
static void get_argstr(char *argstr, int argc, char **argv) {
    std::string c_args;
    for (int i = 0; i < argc; i++) {
        std::string arg = argv[i];

        if (!arg.rfind("+c_args=", 0)) {
            c_args = arg.substr(8);
            break;
        }
    }

    strcpy(argstr, c_args.c_str());
}

#endif
