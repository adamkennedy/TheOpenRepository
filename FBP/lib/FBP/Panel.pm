package FBP::Panel;

use Mouse;

our $VERSION = '0.37';

extends 'FBP::Window';
with    'FBP::Children';

no Mouse;
__PACKAGE__->meta->make_immutable;

1;
