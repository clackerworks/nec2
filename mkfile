all:
	f2c -w8 nec2d.f
	f2c -w8 somnec.f
	f2c -w8 secnds.f
        ape/cc -Fwv -D_BSD_EXTENSION -DHASMOVE_ -I$home/lib/f2c/include -L $home/lib/f2c nec2d.c unix.c -lap -lf2c -o nec2d
        ape/cc -Fwv -D_BSD_EXTENSION -DHASMOVE_ -I$home/lib/f2c/include -L $home/lib/f2c somnec.c secnds.c unix.c -lap -lf2c -o somnec

install:V:
	cp nec2d $home/bin/386
	cp somnec $home/bin/386
	mkdir -p $home/lib/awk
	cp tools/rpplot.awk $home/lib/awk
	cp tools/rpplot $home/bin/rc
	cp tools/nec2tr.awk $home/lib/awk
	cp tools/nec2tr $home/bin/rc
	cp tools/nec2 $home/bin/rc
	cp tools/nec2.awk $home/lib/awk

clean:V:
	rm -f nec2d
	rm -f somnec
	rm -f *.8
	rm -f *.o
	rm -f nec2d.c
	rm -f somnec.c
	rm -f secnds.c


