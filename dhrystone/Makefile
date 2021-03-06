
OBJS = start.o dhry_1.o dhry_2.o stdlib.o
CFLAGS = -MD -O3 -m32 -march=RV32I -ffreestanding -nostdlib -DTIME -DRISCV

test: testbench.exe dhry.hex
	vvp -N testbench.exe

timing: timing.exe dhry.hex
	vvp -N timing.exe > timing.txt
	sed 's,.*## ,,' timing.txt | gawk 'x != "" {print x,$$2-y;} {x=$$1;y=$$2;}' | sort | uniq -c | sort -k3 -n

testbench.exe: testbench.v ../picorv32.v
	iverilog -o testbench.exe testbench.v ../picorv32.v
	chmod -x testbench.exe

timing.exe: testbench.v ../picorv32.v
	iverilog -o timing.exe -DTIMING testbench.v ../picorv32.v
	chmod -x timing.exe

dhry.hex: dhry.bin ../firmware/makehex.py
	python3 ../firmware/makehex.py $< > $@

dhry.bin: dhry.elf
	riscv64-unknown-elf-objcopy -O binary $< $@
	chmod -x $@
	
dhry.elf: $(OBJS) ../firmware/sections.lds
	riscv64-unknown-elf-gcc $(CFLAGS) -Wl,-Bstatic,-T,../firmware/sections.lds,-Map,dhry.map,--strip-debug -o $@ $(OBJS) -lgcc
	chmod -x $@

%.o: %.c
	riscv64-unknown-elf-gcc -c $(CFLAGS) $<

%.o: %.S
	riscv64-unknown-elf-gcc -c $(CFLAGS) $<

clean:
	rm -rf *.o *.d dhry.elf dhry.map dhry.bin dhry.hex testbench.exe testbench.vcd timing.exe timing.txt

.PHONY: test clean

-include *.d

