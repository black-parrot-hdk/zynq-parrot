
make -C verilator/ clean.instrument build_surelog | tee build.log

make -C verilator/ gen_cov SURELOG_TOP_MODULE=bp_be_pipe_int INSTANCE=be.calculator.pipe_int_early FILTER="reset_i width_p lo_to_hi_p" | tee pipe_int.log
make -C verilator/ gen_cov SURELOG_TOP_MODULE=bp_be_pipe_sys INSTANCE=be.calculator.pipe_sys FILTER="reset_i clear_over_set_p lo_to_hi_p width_p" | tee pipe_sys.log
make -C verilator/ gen_cov SURELOG_TOP_MODULE=bp_be_pipe_aux INSTANCE=be.calculator.pipe_aux FILTER="reset_i lo_to_hi_p width_p roundPosBit anyRound" | tee pipe_aux.log
make -C verilator/ gen_cov SURELOG_TOP_MODULE=bp_be_pipe_mem INSTANCE=be.calculator.pipe_mem FILTER="reset_i clear_over_set_p lo_to_hi_p width_p synth.w_mask_i mem_array_2m mem_array_1g" | tee pipe_mem.log
make -C verilator/ gen_cov SURELOG_TOP_MODULE=bp_be_pipe_fma INSTANCE=be.calculator.pipe_fma FILTER="reset_i roundPosBit anyRound" | tee pipe_fma.log
make -C verilator/ gen_cov SURELOG_TOP_MODULE=bp_be_scheduler INSTANCE=be.scheduler FILTER="reset_i" | tee scheduler.log
make -C verilator/ gen_cov SURELOG_TOP_MODULE=bp_be_director INSTANCE=be.director FILTER="reset_i clear_over_set_p" | tee director.log
make -C verilator/ gen_cov SURELOG_TOP_MODULE=bp_fe_pc_gen INSTANCE=fe.pc_gen FILTER="reset_i" | tee pc_gen.log
make -C verilator/ gen_cov SURELOG_TOP_MODULE=bp_fe_icache INSTANCE=fe.icache FILTER="reset_i clear_over_set_p lo_to_hi_p width_p synth.w_mask_i" | tee icache.log
make -C verilator/ gen_cov SURELOG_TOP_MODULE=bp_fe_controller INSTANCE=fe.controller FILTER="reset_i" | tee controller.log

echo $PWD/instrumentation/bp_be_pipe_int.cov > cp.csv
echo $PWD/instrumentation/bp_be_pipe_sys.cov >> cp.csv
echo $PWD/instrumentation/bp_be_pipe_aux.cov >> cp.csv
echo $PWD/instrumentation/bp_be_pipe_mem.cov >> cp.csv
echo $PWD/instrumentation/bp_be_pipe_fma.cov >> cp.csv
echo $PWD/instrumentation/bp_be_scheduler.cov >> cp.csv
echo $PWD/instrumentation/bp_be_director.cov >> cp.csv
echo $PWD/instrumentation/bp_fe_pc_gen.cov >> cp.csv
echo $PWD/instrumentation/bp_fe_icache.cov >> cp.csv
echo $PWD/instrumentation/bp_fe_controller.cov >> cp.csv

make -C verilator/ instrument
