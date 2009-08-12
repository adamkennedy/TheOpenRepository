package                                # Hide from PAUSE.
  WiX3::Util::Role::StrictConstructor;

use 5.008001;
use strict;
use warnings;
use vars qw( $VERSION     );
use WiX3::XML::Exceptions;
use Moose::Role;

use version; $VERSION = version->new('0.003')->numify;

after 'BUILDALL' => sub {
	my $self   = shift;
	my $params = shift;

	my %attrs = (
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
