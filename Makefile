.PHONY: program clean

build:
	quartus_sh --flow compile tecmo

program:
	quartus_pgm -m jtag -c 1 -o "p;output_files/tecmo.sof@2"

release:
	zip -j9 tecmo-mister.zip build-rom.bat build-rom.sh output_files/tecmo.rbf LICENCE README.md

clean:
	rm -rf db incremental_db output_files
