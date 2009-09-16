#!perl

use Test::More tests => 1;
use Test::Output;
use t::lib::MachineTest;
use File::Spec::Functions qw( catdir curdir rel2abs );

my $dir = catdir( rel2abs(curdir()), qw( t MachineTest ) );
my $expected = <<'EOF';
Object number 1 ran.
Object number 2 ran.
Object number 3 ran.
Object number 4 ran.
Object number 5 ran.
Object number 6 ran.
Object number 7 ran.
Object number 8 ran.
Object number 9 ran.
Object number 10 ran.
EOF

diag("Test directory: $dir");

sub test_machine {
	t::lib::MachineTest->default_machine( common => [ image_dir, $dir ] )->run();
}

stdout_is ( \&test_machine, $expected, "::Util::Machine gives expected output.");

