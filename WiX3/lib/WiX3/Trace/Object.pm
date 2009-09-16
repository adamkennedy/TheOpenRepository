package                                # Hide from PAUSE.
  WiX3::Trace::Object;

use 5.008001;
use MooseX::Singleton;
use WiX3::Util::StrictConstructor;
use WiX3::Types qw( Tracelevel );
use MooseX::Types::Moose qw( Bool );

our $VERSION = '0.008';
$VERSION = eval $VERSION; ## no critic(ProhibitStringyEval)

has tracelevel => (
	is      => 'rw',
	isa     => Tracelevel,
	reader  => 'get_tracelevel',
	writer  => 'set_tracelevel',
	default => 1,
);

has testing => (
	is      => 'ro',
	isa     => Bool,
	reader  => 'get_testing',
	default => 0,
);

sub trace_line {
	my $self = shift;
	my ( $level, $text ) = @_;

	if ( $level <= $self->get_tracelevel() ) {
		print $text;
	}

	return $text;
}

no MooseX::Singleton;
__PACKAGE__->meta->make_immutable();

1;                                     # Magic true value required at end of module
