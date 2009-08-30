package                                # Hide from PAUSE.
  WiX3::Trace::Object;

use 5.008001;
use metaclass (
	base_class  => 'MooseX::Singleton::Object',
	metaclass   => 'MooseX::Singleton::Meta::Class',
	error_class => 'WiX3::Util::Error',
);
use MooseX::Singleton;
use WiX3::Trace::Config;
use WiX3::Util::StrictConstructor;
use Readonly qw( Readonly );

our $VERSION = '0.006';
$VERSION = eval { return $VERSION };

Readonly my @LEVELS => qw(error notice info debug debug debug);

with 'MooseX::LogDispatch';

has log_dispatch_conf => (
	is       => 'ro',
	required => 1,
	handles  => [qw( get_tracelevel set_tracelevel get_testing)],
);

sub trace_line {
	my $self = shift;
	my ( $level, $text ) = @_;

	if ( $level <= $self->get_tracelevel() ) {
		$self->logger()->log(
			level   => $LEVELS[$level],
			message => $text
		);
	}

	return $text;
} ## end sub trace_line

no MooseX::Singleton;
__PACKAGE__->meta->make_immutable;

1;                                     # Magic true value required at end of module
