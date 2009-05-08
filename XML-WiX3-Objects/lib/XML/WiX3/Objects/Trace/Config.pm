package # Hide from PAUSE.
	XML::WiX3::Objects::Trace::Config;

use 5.008001;
use Moose;
use MooseX::NonMoose;
# use Moose::Util::TypeConstraints;
use Readonly qw( Readonly );

use version; our $VERSION = version->new('0.003')->numify;

Readonly my @LEVELS => ('error', 'notice', 'warning', 'info', 'info', 'debug');
Readonly my @CONFIGS => ('screen0', 'screen1', 'screen2', 'screen3');

extends 'Log::Dispatch::Configurator';
with 'XML::WiX3::Objects::Trace::Role';

sub get_attrs_global {
	my $self = shift;

	my @dispatchers;
	my $level = $self->get_tracelevel();
	if ($level == 5) {
		@dispatchers = ('screen5');
	} elsif ($level == 4) {
		@dispatchers = @CONFIGS[ 0 .. 3 ];
	} else {
		@dispatchers = @CONFIGS[ 0 .. $level ];
	}
	
	if ($self->get_email_from() ne q{}) {
		push @dispatchers, 'email';
	}
	
	return {
		format => undef,
		dispatchers => [ @dispatchers ],
    };
}

sub get_attrs {
	my ($self, $name) = @_;

	if ($name eq 'screen0') {
		return {
			class => 'Log::Dispatch::Screen',
			name => 'screen0',
			min_level => 'error',
			format => q{%m},
		};
	} elsif ($name eq 'screen1') {
		return {
			class => 'Log::Dispatch::Screen',
			name => 'screen1',
			min_level => 'notice',
			max_level => 'notice',
			format => q{%m},
		};
	} elsif ($name eq 'screen2') {
		return {
			class => 'Log::Dispatch::Screen',
			name => 'screen2',
			min_level => 'warning',
			max_level => 'warning',
			format => q{[] %m},
		};
	} elsif ($name eq 'screen3') {
		return {
			class => 'Log::Dispatch::Screen',
			name => 'screen3',
			min_level => 'info',
			max_level => 'info',
			format => q{[] [%F %L] %m},
		};
	} elsif ($name eq 'screen5') {
		return {
			class => 'Log::Dispatch::Screen',
			name => 'screen5',
			min_level => 'notice',
			format => q{[] [%F %L] %m},
		};
	} elsif ($name eq 'email') {
		if ($self->_get_smtp_user ne q{}) {
			MIME::Lite->send( 'smtp', 
			  $self->_get_smtp(), 
			  AuthUser => $self->_get_smtp_user(),
			  AuthPass => $self->_get_smtp_pass(),
			);
		} elsif ($self->_get_smtp() ne q{}) {
			MIME::Lite->send( 'smtp', $self->_get_smtp() );
		}
		return {
			class => 'Log::Dispatch::Email::MIMELite',
			name => 'email',
			min_level => 'notice',
			to => $self->_get_email_to(),
			from => $self->_get_email_from(),
			format => q{%m},
		};
	} else {
        die "invalid dispatcher name: $name";
    }
}

no Moose;
__PACKAGE__->meta->make_immutable;

1; # Magic true value required at end of module
