use Test::More tests => 1;
use Data::Dumper;
use Macropod::Parser;

my $m = Macropod::Parser->new();
my $doc = $m->parse( 'Macropod::Parser' );

my $expanded = $m->expand($doc);

ok( $expanded );

