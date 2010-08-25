package                                # Hide from PAUSE.
  WiX3::Util::Role::StrictConstructor;

# Corresponds to MooseX::StrictConstructor::Role::Object

use 5.008001;
use strict;
use warnings;
use Moose::Role;
use WiX3::Exceptions;

our $VERSION = '0.010';
$VERSION =~ s/_//ms;

after 'BUILDALL' => sub {
	my $self   = shift;
	my $params = shift;

	my %attrs = (
		__INSTANCE__ => 1,
		map { $_ => 1 }
		  grep {defined}
		  map  { $_->init_arg() } $self->meta()->get_all_attributes() );

	my @bad = sort grep { !$attrs{$_} } keys %{$params};

	if (@bad) {
		WiX3::Exception::Parameter->throw(
"Found unknown attribute(s) init_arg passed to the constructor: @bad"
		);
	}

	return;
};

no Moose::Role;

1;
