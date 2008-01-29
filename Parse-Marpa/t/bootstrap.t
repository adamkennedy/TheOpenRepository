use 5.010_000;
use strict;
use warnings;
use Test::More tests => 5;
use Fatal qw(close chdir);
use Carp;
use English;

# probably won't work on windows

BEGIN {
	use_ok( 'Parse::Marpa' );
}

local($RS) = undef;
# program needs to be run either by Makefile or from t directory
my $bootstrap_dir = $0 =~ m{t/} ? "bootstrap" : "../bootstrap";
chdir($bootstrap_dir);

my $this_perl = $^X; 

sub bootcopy {
    my $program = shift;
    my $output_file = shift;
   
    open(IN,
	"-|", $this_perl, "-I../lib", $program,
	"self.marpa", "bootstrap_header.pl", "bootstrap_trailer.pl"
    ) or die("open for copy from $program to $output_file: $!");
    my $bootcopy = <IN>;
    open(OUT, ">", $output_file);
    print OUT $bootcopy;
    close(IN);
    close(OUT);
    \$bootcopy;
}

my $bootcopy0_ref = bootcopy("bootstrap.pl", "bootcopy0.pl");
ok($$bootcopy0_ref, "wrote bootcopy0.pl");

my $bootcopy1_ref = bootcopy("bootcopy0.pl", "bootcopy1.pl");
ok($$bootcopy1_ref, "wrote bootcopy1.pl");

my $bootcopy2_ref = bootcopy("bootcopy1.pl", "bootcopy2.pl");
ok($$bootcopy2_ref, "wrote bootcopy2.pl");

# If I do the test with is(), on error it prints out both,
# and that is just too much
my $compare = ($$bootcopy1_ref eq $$bootcopy2_ref);
ok($compare, "bootstraped copies identical");
