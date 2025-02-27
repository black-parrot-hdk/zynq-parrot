
#include "bsg_argparse.h"
#include "zynq_headers.h"

#include <stdio.h>
#include <string>

extern int ps_main(int argc, char **argv);

#ifdef HAS_COSIM_MAIN
extern "C" int cosim_main(char *argstr) {
#else
int main(int argc, char **argv) {
    char argstr[1025] = {0};
    get_argstr(argstr, argc, argv);
#endif
    // parse the new argc and argv from the argstr
    int ps_argc = get_argc(argstr);
    char *ps_argv[ps_argc];
    get_argv(argstr, ps_argv);

    // this ensures that even with tee, the output is line buffered
    // so that we can see what is happening in real time
    setvbuf(stdout, NULL, _IOLBF, 0);

    return ps_main(ps_argc, ps_argv);
}
