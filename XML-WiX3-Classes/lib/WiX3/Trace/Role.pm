package # Hide from PAUSE.
	WiX3::Trace::Role;

use 5.008001;
use Moose::Role;
use WiX3::Types qw(Tracelevel);

use version; our $VERSION = version->new('0.003')->numify;

has tracelevel => (
	isa     => Tracelevel,
	reader  => 'get_tracelevel',
	writer  => 'set_tracelevel',
	default => 1,
);

has _testing => (
	isa      => 'Bool',
	reader   => '_get_testing',
	writer   => '_set_testing',
	init_arg => undef,
	default  => 0,
);

has email_from => (
	isa     => 'Maybe[Str]',
	reader  => '_get_email_from',
	default => undef,
);

has email_to => (
	isa     => 'ArrayRef[Str]',
	reader  => '_get_email_to',
	default => sub { return []; },
);

has smtp => (
	isa     => 'Maybe[Str]',
	reader  => '_get_smtp',
	default => undef,
);

has smtp_user => (
	isa     => 'Maybe[Str]',
	reader  => '_get_smtp_user',
	default => q{},
);

has smtp_pass => (
	isa     => 'Maybe[Str]',
	reader  => '_get_smtp_pass',
	default => undef,
);

sub testing {
	my $self = shift;
	
	$self->_set_testing(1);
	
	return $self;
}

no Moose::Role;

1; # Magic true value required at end of module
