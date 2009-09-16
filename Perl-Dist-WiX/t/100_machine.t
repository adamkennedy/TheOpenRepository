#!perl

use Test::More tests => 1;
use Test::Output;
use t::lib::MachineTest;
use File::Spec::Functions qw( catdir curdir );

my $dir = catdir( curdir(), qw( t MachineTest );
my $expected = '';

stdout_is ( {
	t::lib::MachineTest->default_machine(common => [ image_dir => $dir ] )->run();
}, $expected, "::Util::Machine gives expected output.");

