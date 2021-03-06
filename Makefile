
TEST_OBJS = $(addsuffix .o,$(basename $(wildcard tests/*.S)))
FIRMWARE_OBJS = firmware/start.o firmware/irq.o firmware/print.o firmware/sieve.o firmware/multest.o firmware/stats.o

test: testbench.exe firmware/firmware.hex
	vvp -N testbench.exe

test_sp: testbench_sp.exe firmware/firmware.hex
	vvp -N testbench_sp.exe

test_axi: testbench_axi.exe firmware/firmware.hex
	vvp -N testbench_axi.exe

testbench.exe: testbench.v picorv32.v
	iverilog -o testbench.exe testbench.v picorv32.v
	chmod -x testbench.exe

testbench_sp.exe: testbench.v picorv32.v
	iverilog -o testbench_sp.exe -DSP_TEST testbench.v picorv32.v
	chmod -x testbench_sp.exe

testbench_axi.exe: testbench.v picorv32.v
	iverilog -o testbench_axi.exe -DAXI_TEST testbench.v picorv32.v
	chmod -x testbench_axi.exe

firmware/firmware.hex: firmware/firmware.bin firmware/makehex.py
	python3 firmware/makehex.py $< > $@

firmware/firmware.bin: firmware/firmware.elf
	riscv64-unknown-elf-objcopy -O binary $< $@
	chmod -x $@

firmware/firmware.elf: $(FIRMWARE_OBJS) $(TEST_OBJS) firmware/sections.lds
	riscv64-unknown-elf-gcc -Os -m32 -march=RV32I -ffreestanding -nostdlib -o $@ \
		-Wl,-Bstatic,-T,firmware/sections.lds,-Map,firmware/firmware.map,--strip-debug \
		$(FIRMWARE_OBJS) $(TEST_OBJS) -lgcc
	chmod -x $@

firmware/start.o: firmware/start.S
	riscv64-unknown-elf-gcc -c -m32 -o $@ $<

firmware/%.o: firmware/%.c
	riscv64-unknown-elf-gcc -c -Os -m32 -march=RV32I -ffreestanding -nostdlib -o $@ $<

tests/%.o: tests/%.S tests/riscv_test.h tests/test_macros.h
	riscv64-unknown-elf-gcc -m32 -march=RV32I -c -o $@ -DTEST_FUNC_NAME=$(notdir $(basename $<)) \
		-DTEST_FUNC_TXT='"$(notdir $(basename $<))"' -DTEST_FUNC_RET=$(notdir $(basename $<))_ret $<

clean:
	rm -vrf $(TEST_OBJS) firmware/firmware.elf firmware/firmware.bin firmware/firmware.hex \
		firmware/firmware.map testbench*.exe testbench.vcd .Xil fsm_encoding.os \
		synth_vivado.log synth_vivado_*.backup.log synth_vivado.v

.PHONY: test test_sp test_axi clean

