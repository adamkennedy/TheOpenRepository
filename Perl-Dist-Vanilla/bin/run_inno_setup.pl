#!perl
use strict;
use warnings;

my $inno_setup = "C:\\Program Files\\Inno Setup 5\\ISCC.exe";

system( $inno_setup, "vanilla.iss" )
