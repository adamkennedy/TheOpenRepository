use 5.010_000;
use strict;
use warnings;
use Test::More;
use Fatal qw(close chdir);
use Carp;
use English qw( -no_match_vars ) ;
use Config;

if ($Config{"d_fork"}) {
    plan tests => 4;
} else {
    plan skip_all => "Fork required to test examples";
    exit 0;
}

local($RS) = undef;
# program needs to be run either by Makefile or from t directory
my $bootstrap_dir = $0 =~ m{t/} ? "bootstrap" : "../bootstrap";
chdir($bootstrap_dir) or croak("Cannot chdir to bootstrap directory: $!");

my $this_perl = $^X; 

sub bootcopy {
    my $program = shift;
    my $output_file = shift;
   
    open(IN,
	"-|", $this_perl, "-I../lib", $program,
	"self.marpa",
	"bootstrap_header.pl",
	"bootstrap_trailer.pl"
    ) or die("open for copy from $program to $output_file: $!");
    my $bootcopy = <IN>;
    open(OUT, ">", $output_file);
    print OUT $bootcopy;
    close(IN);
    close(OUT);
    \$bootcopy;
}

my $bootcopy0_ref = bootcopy("bootstrap.pl", "t.bootcopy0.pl");
ok($$bootcopy0_ref, "wrote bootcopy0.pl");

my $bootcopy1_ref = bootcopy("t.bootcopy0.pl", "t.bootcopy1.pl");
ok($$bootcopy1_ref, "wrote bootcopy1.pl");

my $bootcopy2_ref = bootcopy("t.bootcopy1.pl", "t.bootcopy2.pl");
ok($$bootcopy2_ref, "wrote bootcopy2.pl");

# If I do the test with is(), on error it prints out both,
# and that is just too much
my $compare = ($$bootcopy1_ref eq $$bootcopy2_ref);
ok($compare, "bootstraped copies identical");

for my $bootcopy ("t.bootcopy0.pl", "t.bootcopy1.pl", "t.bootcopy2.pl") {
    unlink($bootcopy) or croak("Failed to unlink $bootcopy: $!");
}
