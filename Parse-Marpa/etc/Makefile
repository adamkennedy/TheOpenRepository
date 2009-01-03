
build:
	(cd ..;perl Makefile.PL)
	(cd ..;make realclean)
	(cd ../bootstrap; make -W self.marpa install)
	(cd ..;perl Makefile.PL)
	(cd ..;make)
	(cd ..;make test)
	(cd ..;make disttest)

perlcritic:
	perlcritic -profile perlcriticrc ../lib/Parse/Marpa/Grammar.pm
	perlcritic -profile perlcriticrc ../lib/Parse/Marpa/Recognizer.pm
	perlcritic -profile perlcriticrc ../lib/Parse/Marpa/Evaluator.pm
	perlcritic -profile perlcriticrc ../t/equation.t
	perlcritic -profile perlcriticrc ../t/equation_s.t

bocage_counts:
	prove -Ibocage .

