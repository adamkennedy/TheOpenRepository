use Test::More tests => 2;

use Macropod::Parser;

my $m = Macropod::Parser->new();
ok( $m ,'instance' );

ok( $m->parse( 'Macropod::Parser' )  );
