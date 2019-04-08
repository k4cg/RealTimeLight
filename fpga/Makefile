#
#	RealTimeLight
#	Copyright (C) 2019  Christian Carlowitz <chca@cmesh.de>
#
#	This program is free software: you can redistribute it and/or modify
#	it under the terms of the GNU General Public License as published by
#	the Free Software Foundation, either version 3 of the License, or
#	(at your option) any later version.
#
#	This program is distributed in the hope that it will be useful,
#	but WITHOUT ANY WARRANTY; without even the implied warranty of
#	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#	GNU General Public License for more details.
#
#	You should have received a copy of the GNU General Public License
#	along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

all:
	iverilog -o test.vvp test.v src/*.v
	IVERILOG_DUMPER=lxt2 vvp test.vvp

disp:
	gtkwave dump.lx2 view.sav 2>&1 >/dev/null &

syn:
	mkdir -p syn
	yosys -v2 -p 'synth_ice40 -top Top -blif syn/top.blif; write_verilog syn/out.v' src/*.v
	arachne-pnr -d 1k -P tq144 -p src/top.pcf -o syn/top.asc syn/top.blif
	icepack syn/top.asc syn/top.bin
	icetime -t -m -r syn/top-timing.rpt -d hx1k syn/top.asc

flash:
	iceprog syn/top.bin

.PHONY: syn prog disp flash psyn pdisp

