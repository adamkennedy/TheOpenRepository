package # Hide from PAUSE.
	XML::WiX3::Classes::Role::Traceable;

use 5.008001;
use Moose::Role;

use version; our $VERSION = version->new('0.003')->numify;

has trace_opts (
	isa => 'HashRef',
	getter => 'get_traceopts'
);

has _traceobject (
    is  => 'ro',
    isa => 'XML::WiX3::Classes::Trace::Object',
	lazy => 1,
	init_arg => undef,
	builder => '_setup_traceobject',
	handles => [qw(get_tracelevel set_tracelevel trace_line testing)],
);

sub _setup_traceobject {
	my $self = shift;
	return XML::WiX3::Classes::Trace::Object->new( 
	  %{ $self->trace_opts() }, 
	  use_logger_singleton => 1,
	);
}

no Moose::Role;

1; # Magic true value required at end of module
