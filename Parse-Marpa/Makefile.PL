require 5.010_000;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Parse::Marpa',
    AUTHOR              => 'Jeffrey Kegler',
    VERSION_FROM        => 'lib/Parse/Marpa.pm',
    ABSTRACT_FROM       => 'lib/Parse/Marpa.pm',
    PL_FILES => {
        "lib/Parse/Marpa/Source.pm.PL" => "lib/Parse/Marpa/Source.pm"
    },
    PM => {
	'lib/Parse/Marpa/Raw_Source.pm'
	    => '$(INST_LIB)/Parse/Marpa/Raw_Source.pm',
	'lib/Parse/Marpa/Doc/Algorithm.pod'
	    => '$(INST_LIB)/Parse/Marpa/Doc/Algorithm.pod',
	'lib/Parse/Marpa/Doc/Bibliography.pod'
	    => '$(INST_LIB)/Parse/Marpa/Doc/Bibliography.pod',
	'lib/Parse/Marpa/Doc/Diagnostics.pod'
	    => '$(INST_LIB)/Parse/Marpa/Doc/Diagnostics.pod',
	'lib/Parse/Marpa/Doc/Internals.pod'
	    => '$(INST_LIB)/Parse/Marpa/Doc/Internals.pod',
	'lib/Parse/Marpa/Doc/Parse_Terms.pod'
	    => '$(INST_LIB)/Parse/Marpa/Doc/Parse_Terms.pod',
	'lib/Parse/Marpa/Doc/Plumbing.pod'
	    => '$(INST_LIB)/Parse/Marpa/Doc/Plumbing.pod',
	'lib/Parse/Marpa/Doc/MDL.pod'
	    => '$(INST_LIB)/Parse/Marpa/Doc/MDL.pod',
	'lib/Parse/Marpa/Doc/To_Do.pod'
	    => '$(INST_LIB)/Parse/Marpa/Doc/To_Do.pod',
	'lib/Parse/Marpa/Doc/Undocumented.pod'
	    => '$(INST_LIB)/Parse/Marpa/Doc/Undocumented.pod',
	'lib/Parse/Marpa/Lex.pm'
	    => '$(INST_LIB)/Parse/Marpa/Lex.pm',
	'lib/Parse/Marpa/MDL.pm'
	    => '$(INST_LIB)/Parse/Marpa/MDL.pm',
	'lib/Parse/Marpa/Grammar.pm'
	    => '$(INST_LIB)/Parse/Marpa/Grammar.pm',
	'lib/Parse/Marpa/Recognizer.pm'
	    => '$(INST_LIB)/Parse/Marpa/Recognizer.pm',
	'lib/Parse/Marpa/Evaluator.pm'
	    => '$(INST_LIB)/Parse/Marpa/Evaluator.pm',
	'lib/Parse/Marpa.pm'
	    => '$(INST_LIB)/Parse/Marpa.pm',
	'lib/Parse/Marpa/trailer_Raw_Source.pm'
	    => '$(INST_LIB)/Parse/Marpa/trailer_Raw_Source.pm',
	'lib/Parse/Marpa/Source.pm'
	    => '$(INST_LIB)/Parse/Marpa/Source.pm',
	'lib/Parse/Marpa/Source.pm.PL'
	    => '$(INST_LIB)/Parse/Marpa/Source.pm.PL',
	'lib/Parse/Marpa/header_Raw_Source.pm'
	    => '$(INST_LIB)/Parse/Marpa/header_Raw_Source.pm',
    },
    EXE_FILES => [
                           'bin/mdl',
    ],
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);
