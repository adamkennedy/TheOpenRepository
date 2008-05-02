use 5.010_000;
use strict;
use warnings;
use Test::More;
use Fatal qw(close chdir);
use Carp;
use English qw( -no_match_vars ) ;
use Config;

if ($Config{"d_fork"}) {
    plan tests => 1;
} else {
    plan skip_all => "Fork required to test examples";
    exit 0;
}

# program needs to be run either by Makefile or from t directory
my $bootstrap_dir = $0 =~ m{t/} ? "bootstrap" : "../bootstrap";

my $this_perl = $^X; 

my $script_output = <<`END OF SCRIPT`;
cd $bootstrap_dir 2>&1
echo Bootstrap 1
$this_perl -I../lib bootstrap.pl self.marpa bootstrap_header.pl bootstrap_trailer.pl 2>&1 >t_bootcopy0.pl
echo Bootstrap 2
$this_perl -I../lib t_bootcopy0.pl self.marpa bootstrap_header.pl bootstrap_trailer.pl 2>&1 >t_bootcopy1.pl
echo Diff
diff t_bootcopy0.pl t_bootcopy1.pl && echo Test OK 2>&1
echo Cleanup
rm -f t_bootcopy0.pl t_bootcopy1.pl 2>&1
END OF SCRIPT

is($script_output,
    "Bootstrap 1\n"
    . "Bootstrap 2\n"
    . "Diff\n"
    . "Test OK\n"
    . "Cleanup\n",
    "bootstrapped copies identical");

