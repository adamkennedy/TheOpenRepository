
build:
	(cd ..;perl Makefile.PL)
	(cd ..;make realclean)
	(cd ../bootstrap; make -W self.marpa install)
	(cd ..;perl Makefile.PL)
	(cd ..;make)
	(cd ..;make test)
	(cd ..;make disttest)

perlcritic:
	-perlcritic -profile perlcriticrc ../lib/Parse/Marpa/Grammar.pm
	-perlcritic -profile perlcriticrc ../lib/Parse/Marpa/Recognizer.pm
	-perlcritic -profile perlcriticrc ../lib/Parse/Marpa/Evaluator.pm
	for t in ../t/*.t; do \
	    perlcritic -profile perlcriticrc $$t || true; \
	done
	-perlcritic -profile perlcriticrc ../bin/mdl
	-perlcritic -profile perlcriticrc ../bootstrap/bootstrap.pl
	-perlcritic -profile perlcriticrc ../example/synopsis.pl
	-perlcritic -profile perlcriticrc ../lib/Parse/Marpa.pm
	-perlcritic -profile perlcriticrc ../lib/Parse/Marpa/Lex.pm
	-perlcritic -profile perlcriticrc ../lib/Parse/Marpa/MDL.pm
	-perlcritic -profile perlcriticrc ../lib/Parse/Marpa/Offset.pm
	-perlcritic -profile perlcriticrc ../t/lib/Marpa/Test.pm
	-perlcritic -profile perlcriticrc ../author.t/test_pod
	-perlcritic -profile perlcriticrc ../author.t/misc.pl
