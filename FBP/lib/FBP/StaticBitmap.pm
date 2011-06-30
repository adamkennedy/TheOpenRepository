package FBP::StaticBitmap;

use Mouse;
use Scalar::Util ();

our $VERSION = '0.32';

extends 'FBP::Window';

has bitmap => (
	is  => 'ro',
	isa => 'Str',
);

1;
