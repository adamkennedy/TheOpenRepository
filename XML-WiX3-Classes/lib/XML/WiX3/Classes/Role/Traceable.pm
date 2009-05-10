package XML::WiX3::Classes::Role::Traceable;

use 5.008001;
use Moose::Role;
use XML::WiX3::Classes::Trace::Object;

use version; our $VERSION = version->new('0.003')->numify;

has _traceopts => (
	is => 'ro',
	isa => 'HashRef',
	reader => '_get_traceopts',
	default => sub { return { tracelevel => 1 } }
);

has _traceobject => (
    is  => 'ro',
    isa => 'XML::WiX3::Classes::Trace::Object',
	lazy => 1,
	init_arg => undef,
	builder => '_setup_traceobject',
	handles => [qw(get_tracelevel set_tracelevel trace_line testing log)],
);

sub _setup_traceobject {
	my $self = shift;
	return XML::WiX3::Classes::Trace::Object->new( 
	  %{ $self->_get_traceopts() }, 
	  use_logger_singleton => 1,
	);
}

no Moose::Role;

1; # Magic true value required at end of module
