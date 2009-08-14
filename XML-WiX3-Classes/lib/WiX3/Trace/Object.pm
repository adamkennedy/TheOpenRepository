package                                # Hide from PAUSE.
  WiX3::Trace::Object;

use 5.008001;

# Must be done before Moose, or it won't get picked up.
use metaclass (
	base_class  => 'MooseX::Singleton::Object',
	metaclass   => 'MooseX::Singleton::Meta::Class',
	error_class => 'WiX3::Util::Error',
);
use MooseX::Singleton;
use WiX3::Trace::Config;
use WiX3::Util::StrictConstructor;

use version; our $VERSION = version->new('0.003')->numify;

use Readonly qw( Readonly );
Readonly my @LEVELS => qw(error notice info debug debug debug);

with 'WiX3::Trace::Role';
with 'MooseX::LogDispatch';

has log_dispatch_conf => (
	is       => 'ro',
	lazy     => 1,
	init_arg => undef,
	default  => sub {
		my $self = shift;
		return WiX3::Trace::Config->new(
			tracelevel => $self->get_tracelevel(),
			testing    => $self->get_testing(),
			email_from => $self->_get_email_from(),
			email_to   => $self->_get_email_to(),
			smtp       => $self->_get_smtp(),
			smtp_user  => $self->_get_smtp_user(),
			smtp_pass  => $self->_get_smtp_pass(),
			smtp_port  => $self->_get_smtp_port(),
		);
	},
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
