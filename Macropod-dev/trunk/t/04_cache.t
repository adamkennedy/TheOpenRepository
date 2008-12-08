use Test::More tests => 1;
use Data::Dumper;
use Macropod::Parser;
use Carp qw( confess );


my $m = Macropod::Parser->new();
$m->init_cache();
my $doc = $m->parse( 'Macropod::Parser' );
$m->process($doc);
diag( "Processed and cached 'Macropod::Parser' " );
$m = undef;

my $new = Macropod::Parser->new();
$new->init_cache();

my $cached = $new->have_cached( name => 'Macropod::Parser' );
ok( $cached , 'Cached Macropod::Parser' ) ;

