#!perl
use strict;
use warnings;
use IPC::Run3;

run3 [ $^X, "bin\\get_binaries.pl" ];
run3 [ $^X, "bin\\build_perl.pl" ];
run3 [ $^X, "bin\\build_modules.pl" ];
run3 [ $^X, "bin\\copy_extra.pl" ];

