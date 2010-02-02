package WiX3::Role::Traceable;

use 5.008001;
use Moose::Role 0.90;
use WiX3::Trace::Object 0.008;
use WiX3::Types qw( TraceObject );

our $VERSION = '0.008001';
$VERSION =~ s/_//ms;

has _traceobject => (
	is       => 'bare',
	isa      => TraceObject,
	init_arg => 'options',
	weak_ref => 1,
	default  => sub { WiX3::Trace::Object->new() },
	handles  => [qw(get_tracelevel set_tracelevel get_testing trace_line)],
);

no Moose::Role;

1;                                     # Magic true value required at end of module
