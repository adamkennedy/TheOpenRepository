use Test::More tests => 1;
use Data::Dumper;
use Macropod::Parser;
use Macropod::Processor;

my $m = Macropod::Parser->new();
my $doc = $m->parse( 'Macropod::Parser' );

my $p = Macropod::Processor->new();

my $expanded = $p->process($doc);

ok( $expanded );

