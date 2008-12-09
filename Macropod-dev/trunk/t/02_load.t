use Test::More tests => 1;

use Macropod::Document;


my $doc = Macropod::Document->open( file => 't/data/example.macropod' );

ok( $doc , 'Loaded a serialized Macropod::Document' );


