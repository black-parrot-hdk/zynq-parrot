
#include "bsg_argparse.h"
#include "zynq_headers.h"

#include <stdio.h>

extern int ps_main(int argc, char **argv);

#ifdef HAS_COSIM_MAIN
extern "C" int cosim_main(char *argstr) {
    int argc = get_argc(argstr);
    char *argv[argc];
    get_argv(argstr, argc, argv);
#else
int main(int argc, char **argv) {
#endif
    // this ensures that even with tee, the output is line buffered
    // so that we can see what is happening in real time
    setvbuf(stdout, NULL, _IOLBF, 0);

    return ps_main(argc, argv);
}
