use Test::More tests => 4;

use Macropod::Util qw( dequote dequote_list );

my $str = 'qw( Foo Bar Baz )';
my $deq = dequote($str);
ok( $deq eq ' Foo Bar Baz ' , 'Dequote qw()' );


$str = '"testing"';
$deq = dequote( $str );
ok( $deq eq 'testing' , 'Dequote double quotes ""' );

$str = 'q|Nothing|';
$deq = dequote( $str );
ok( dequote( $str ) eq 'Nothing' , 'Dequote single q||' );


$str = 'qw{ One Two Three Four }';
my @list = dequote_list( $str );

is_deeply( \@list  , [qw/One Two Three Four/] , 'dequote list' );

