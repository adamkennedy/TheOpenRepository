use Test::More;
use File::Spec::Functions qw(catfile);

eval "use Test::Prereq::Build";

plan skip_all => "Test::Prereq::Build required to test dependencies" if $@;

plan tests => 1;

prereq_ok();
