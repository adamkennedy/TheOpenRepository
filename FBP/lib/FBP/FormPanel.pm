package FBP::FormPanel;

use Mouse;

our $VERSION = '0.38';

extends 'FBP::Panel';
with    'FBP::Form';

no Mouse;
__PACKAGE__->meta->make_immutable;

1;
