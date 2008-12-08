use Test::More tests => 2;

use Macropod::Parser;

my $m = Macropod::Parser->new();
ok( $m ,'instance' );

my $doc = $m->parse_file( 't/data/Package.pm' );
ok( $doc );
