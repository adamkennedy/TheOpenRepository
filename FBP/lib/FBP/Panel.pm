package FBP::Panel;

use Mouse;

our $VERSION = '0.34';

extends 'FBP::Window';

no Mouse;
__PACKAGE__->meta->make_immutable;

1;
