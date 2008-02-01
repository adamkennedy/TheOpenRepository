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
	'lib/Parse/Marpa/ALGORITHM.pod'
	    => '$(INST_LIB)/Parse/Marpa/ALGORITHM.pod',
	'lib/Parse/Marpa/BIBLIOGRAPHY.pod'
	    => '$(INST_LIB)/Parse/Marpa/BIBLIOGRAPHY.pod',
	'lib/Parse/Marpa/DIAGNOSTICS.pod'
	    => '$(INST_LIB)/Parse/Marpa/DIAGNOSTICS.pod',
	'lib/Parse/Marpa/INTERNALS.pod'
	    => '$(INST_LIB)/Parse/Marpa/INTERNALS.pod',
	'lib/Parse/Marpa/RAW.pod'
	    => '$(INST_LIB)/Parse/Marpa/RAW.pod',
	'lib/Parse/Marpa/LANGUAGE.pod'
	    => '$(INST_LIB)/Parse/Marpa/LANGUAGE.pod',
	'lib/Parse/Marpa/CONCEPTS.pod'
	    => '$(INST_LIB)/Parse/Marpa/CONCEPTS.pod',
	'lib/Parse/Marpa/Lex.pm'
	    => '$(INST_LIB)/Parse/Marpa/Lex.pm',
	'lib/Parse/Marpa/MDL.pm'
	    => '$(INST_LIB)/Parse/Marpa/MDL.pm',
	'lib/Parse/Marpa/Parser.pm'
	    => '$(INST_LIB)/Parse/Marpa/Parser.pm',
	'lib/Parse/Marpa/TUTORIAL.pod'
	    => '$(INST_LIB)/Parse/Marpa/TUTORIAL.pod',
	'lib/Parse/Marpa.pm'
	    => '$(INST_LIB)/Parse/Marpa.pm',
	'lib/Parse/Marpa/trailer_Raw_Source.pm'
	    => '$(INST_LIB)/Parse/Marpa/trailer_Raw_Source.pm',
	'lib/Parse/Marpa/Source.pm'
	    => '$(INST_LIB)/Parse/Marpa/Source.pm',
	'lib/Parse/Marpa/Source.pm.PL'
	    => '$(INST_LIB)/Parse/Marpa/Source.pm.PL',
	'lib/Parse/Marpa/WHY_CALL_IT_MARPA.pod'
	    => '$(INST_LIB)/Parse/Marpa/WHY_CALL_IT_MARPA.pod',
	'lib/Parse/Marpa/header_Raw_Source.pm'
	    => '$(INST_LIB)/Parse/Marpa/header_Raw_Source.pm',
    },
    EXE_FILES => [
                           'bin/marpa',
    ],
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);
