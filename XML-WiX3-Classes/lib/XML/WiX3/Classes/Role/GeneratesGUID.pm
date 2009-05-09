package XML::WiX3::Classes::Role::GeneratesGUID;

use 5.008001;
use Moose::Role;
use XML::WiX3::Classes::Types qw(Host);

use version; our $VERSION = version->new('0.003')->numify;

has sitename => (
    is      => 'ro',
	isa     => Host,
	reader  => '_get_sitename',
	default => q{www.perl.invalid},
);

has _guidobject => (
    is       => 'ro',
    isa      => 'XML::WiX3::Classes::GeneratesGUID::Object',
	lazy     => 1,
	init_arg => undef,
	default  => sub {
		my $self = shift;
		return XML::WiX3::Classes::GeneratesGUID::Object->new(
			sitename => $self->_get_sitename()
		);
	},
	handles => [qw(generate_guid)],
);

no Moose::Role;

1; # Magic true value required at end of module
