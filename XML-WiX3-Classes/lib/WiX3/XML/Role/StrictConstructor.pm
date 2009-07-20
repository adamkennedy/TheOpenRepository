package # Hide from PAUSE.
	XML::WiX3::Classes::Role::StrictConstructor;

use strict;
use warnings;
use XML::WiX3::Classes::Exceptions;
use Moose::Role;

after 'BUILDALL' => sub
{
    my $self   = shift;
    my $params = shift;

    my %attrs =
        ( map { $_ => 1 }
          grep { defined }
          map { $_->init_arg() }
          $self->meta()->get_all_attributes()
        );

    my @bad = sort grep { ! $attrs{$_} }  keys %{ $params };

    if (@bad)
    {
        XWC::Exception::Parameter->throw("Found unknown attribute(s) init_arg passed to the constructor: @bad");
    }

    return;
};

no Moose::Role;

1;