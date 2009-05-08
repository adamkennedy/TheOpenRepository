package # Hide from PAUSE.
	XML::WiX3::Objects::Trace::Object;

use 5.008001;
use MooseX::Singleton;
use Readonly qw( Readonly );

use version; our $VERSION = version->new('0.003')->numify;

Readonly my @LEVELS => ('error', 'notice', 'warning', 'info', 'info', 'debug');

with 'XML::WiX3::Objects::Trace::Role';
with 'MooseX::LogDispatch';

has log_dispatch_conf => (
	is => 'ro',
	lazy => 1,
	required => 1,
	default => sub {
		my $self = shift;
		return XML::WiX3::Objects::Trace::Config->new(
			tracelevel => $self->get_tracelevel(),
			testing => $self->_get_testing(),
			email_from => $self->_get_email_from(),
			email_to => $self->_get_email_to(),
			smtp => $self->_get_smtp(),
			smtp_user => $self->_get_smtp_user(),
			smtp_pass => $self->_get_smtp_pass(),
		);  
	}
);

no MooseX::Singleton;
__PACKAGE__->meta->make_immutable;

1; # Magic true value required at end of module
