package                                # Hide from PAUSE.
  WiX3::Trace::Config;

use 5.008001;
use metaclass (
	base_class  => 'MooseX::Singleton::Object',
	metaclass   => 'MooseX::Singleton::Meta::Class',
	error_class => 'WiX3::Util::Error',
);
use MooseX::Singleton;
use MooseX::NonMoose;
use Carp qw(croak);
use Readonly qw( Readonly );
use WiX3::Util::StrictConstructor;

use version; our $VERSION = version->new('0.006')->numify;

has tracelevel => (
	is      => 'rw',
	isa     => Tracelevel,
	reader  => 'get_tracelevel',
	writer  => 'set_tracelevel',
	default => 1,
);

has testing => (
	is      => 'ro',
	isa     => 'Bool',
	reader  => 'get_testing',
	default => 0,
);

has email_from => (
	is      => 'ro',
	isa     => 'Maybe[Str]',
	reader  => '_get_email_from',
	default => undef,
);

has email_to => (
	is      => 'ro',
	isa     => 'ArrayRef[Str]',
	reader  => '_get_email_to',
	default => sub { return []; },
);

has smtp => (
	is      => 'ro',
	isa     => 'Maybe[Str]',
	reader  => '_get_smtp',
	default => undef,
);

has smtp_user => (
	is      => 'ro',
	isa     => 'Maybe[Str]',
	reader  => '_get_smtp_user',
	default => q{},
);

has smtp_pass => (
	is      => 'ro',
	isa     => 'Maybe[Str]',
	reader  => '_get_smtp_pass',
	default => undef,
);

has smtp_port => (
	is      => 'ro',
	isa     => 'Maybe[Int]',
	reader  => '_get_smtp_port',
	default => undef,
);

extends 'Log::Dispatch::Configurator';

Readonly my @LEVELS  => qw(error notice info debug debug debug);
Readonly my @CONFIGS => qw(screen0 screen1 screen2 screen3);

sub get_attrs_global {
	my $self = shift;

	my @dispatchers;
	my $level = $self->get_tracelevel();
	if ( $level == 5 ) {
		@dispatchers = ('screen5');
	} elsif ( ( $level == 4 ) or ( $level == 3 ) ) {
		@dispatchers = @CONFIGS[ 0, 1, 3 ];
	} else {
		@dispatchers = @CONFIGS[ 0 .. $level ];
	}

	if ( defined $self->_get_email_from() ) {
		push @dispatchers, 'email';
	}

	my %answer = (
		format      => undef,
		dispatchers => [@dispatchers],
	);

	return \%answer;
} ## end sub get_attrs_global

sub get_attrs {
	my ( $self, $name ) = @_;

	if ( $name eq 'screen0' ) { ## no critic(ProhibitCascadingIfElse)
		return {
			class     => 'Log::Dispatch::Screen',
			name      => 'screen0',
			min_level => 'error',
			stderr    => !$self->get_testing(),
			format    => q{%m},
		};
	} elsif ( $name eq 'screen1' ) {
		return {
			class     => 'Log::Dispatch::Screen',
			name      => 'screen1',
			min_level => 'notice',
			max_level => 'notice',
			stderr    => 0,
			format    => q{%m},
		};
	} elsif ( $name eq 'screen2' ) {
		return {
			class     => 'Log::Dispatch::Screen',
			name      => 'screen2',
			min_level => 'info',
			max_level => 'info',
			stderr    => 0,
			format    => q{%m},
		};
	} elsif ( $name eq 'screen3' ) {
		return {
			class     => 'Log::Dispatch::Screen',
			name      => 'screen3',
			min_level => 'info',
			max_level => 'info',
			stderr    => 0,
			format    => q{[%F %L] %m},
		};
	} elsif ( $name eq 'screen5' ) {
		return {
			class     => 'Log::Dispatch::Screen',
			name      => 'screen5',
			min_level => 'notice',
			stderr    => 0,
			format    => q{[%p] [%F %L] %m},
		};
	} elsif ( $name eq 'email' ) {
		if ( defined $self->_get_smtp_user() ) {
			MIME::Lite->send(
				'smtp',
				$self->_get_smtp(),
				defined $self->_get_smtp_user()
				? ( AuthUser => $self->_get_smtp_user(),
					AuthPass => $self->_get_smtp_pass(),
				  )
				: (),
				defined $self->_get_smtp_port()
				? ( Port => $self->_get_smtp_port(), )
				: (),
			);
		} elsif ( defined $self->_get_smtp() ) {
			MIME::Lite->send( 'smtp', $self->_get_smtp() );
		}
		return {
			class     => 'Log::Dispatch::Email::MIMELite',
			name      => 'email',
			min_level => 'notice',
			to        => $self->_get_email_to(),
			from      => $self->_get_email_from(),
			format    => q{%m},
		};
	} else {
		## no critic(RequireUseOfExceptions)
		croak "invalid dispatcher name: $name";
	}
} ## end sub get_attrs

no Moose;
__PACKAGE__->meta->make_immutable;

1;                                     # Magic true value required at end of module
