
build:
	(cd ..;make realclean)
	(cd ../bootstrap; make install)
	(cd ..;perl Makefile.PL)
	(cd ..;make)
	(cd ..;make test)
	(cd ..;make disttest)
