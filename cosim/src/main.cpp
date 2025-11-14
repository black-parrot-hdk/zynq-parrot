
#include "bsg_argparse.h"
#include "bsg_zynq_pl.h"

#include <stdio.h>
#include <string>

extern int ps_main (bsg_zynq_pl *zpl, int argc, char **argv);

#ifdef HAS_COSIM_MAIN
extern "C" void cosim_main(char *argstr) {
#else
void main(int argc, char **argv) {
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

    // need to call finish after ZPL is destructed...
    // for now, pl and ps get the same arguments, but we could split them
    bsg_zynq_pl zpl(ps_argc, ps_argv);
    int rc = ps_main(&zpl, ps_argc, ps_argv);
    printf("PS main returned with rc: %x\n", rc);
    zpl.done();
    __builtin_unreachable();
}
