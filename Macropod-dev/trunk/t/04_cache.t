use Test::More tests => 1;
use Data::Dumper;
use Macropod::Parser;
use Carp qw( confess );


my $m = Macropod::Parser->new();
$m->init_cache();
$m->parse( 'Macropod::Parser' );
$m->process;

diag( "Processed and cached 'Macropod::Parser' " );

my $new = Macropod::Parser->new();
$new->init_cache();

my $cached = $new->have_cached( 'Macropod::Parser' );
ok( $cached) ;

