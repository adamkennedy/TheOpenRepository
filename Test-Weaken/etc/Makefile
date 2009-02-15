
.PHONY: build perltidy perlcritic display

build:
	(cd ..;perl Makefile.PL)
	(cd ..;make realclean)
	(cd ..;perl Makefile.PL)
	(cd ..;make)
	(cd ..;make test)
	(cd ..;make disttest)

perltidy: 
	perl do_tidy.pl

perlcritic: perlcritic.errs

perlcritic.errs:
	perl do_critic.pl > $@
	wc -l $@

display: display.errs

# check displays
display.errs:
	perl display_test.pl > $@
	wc -l $@
