package # Hide from PAUSE.
	XML::WiX3::Objects::Trace::Role;

use 5.008001;
use Moose::Role;
use XML::WiX3::Objects::Types qw(Host);
use Readonly qw( Readonly );

use version; our $VERSION = version->new('0.003')->numify;

Readonly my @LEVELS => qw(error notice warning info info debug);

has tracelevel (
	isa     => Tracelevel,
	reader  => 'get_tracelevel',
	writer  => 'set_tracelevel',
	default => 0,
);

has testing (
	isa     => 'Bool',
	reader  => '_get_testing',
	writer  => '_set_testing',
	default => 0,
);

has email_from (
	isa     => 'Str',
	reader  => '_get_email_from',
	default => q{},
);

has email_to (
	isa     => 'ArrayRef[Str]',
	reader  => '_get_email_to',
	default => [],
);

has smtp (
	isa     => 'Str',
	reader  => '_get_smtp',
	default => q{},
);

has smtp_user (
	isa     => 'Str',
	reader  => '_get_smtp_user',
	default => q{},
);

has smtp_pass (
	isa     => 'Str',
	reader  => '_get_smtp_pass',
	default => q{},
);

sub testing {
	my $self = shift;
	
	$self->_set_testing(1);
	
	return $self;
}

sub trace_line {
	my $self = shift;
	my ($level, $text) = @_;
	
	$self->log(level => $LEVELS[$level], message => $text);
	
	return $self;
}

no Moose::Role;

1; # Magic true value required at end of module
