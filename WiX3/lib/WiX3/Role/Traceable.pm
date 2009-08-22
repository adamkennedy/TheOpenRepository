package WiX3::Role::Traceable;

use 5.008001;
use strict;
use warnings;
use Moose::Role;
use WiX3::Trace::Object;
use WiX3::Types qw( TraceConfig TraceObject );

use version; our $VERSION = version->new('0.005')->numify;

has _traceconfig => (
	is       => 'ro',
	isa      => TraceConfig,
	reader   => '_get_traceconfig',
	init_arg => 'options',
	default  => sub { WiX3::Trace::Config->instance() },
);

has _traceobject => (
	is       => 'ro',
	isa      => TraceObject,
	lazy     => 1,
	init_arg => undef,
	builder  => '_setup_traceobject',
	handles =>
	  [qw(get_tracelevel set_tracelevel get_testing trace_line log)],
);

sub _setup_traceobject {
	my $self = shift;
	return WiX3::Trace::Object->new( options => $self->_get_traceconfig(),
		use_logger_singleton => 1, );
}

#sub STORABLE_freeze {
#	my ($self, $cloning) = @_;
#	print "Test 0\n";
#	$self->{_traceobject} = undef;
#	require Data::Dumper;
#	print Data::Dumper->new([$self])->Indent(1)->Dump();
#	return $self;
#}

#sub STORABLE_thaw {
#	my ($self, $cloning, $traceopts) = @_;
#	print "Test 1\n";
#	require Data::Dumper;
#	print Data::Dumper->new([$self, $traceopts])->Indent(1)->Dump();
#	print "\n";	
#	print $self;
#	print "\n";	
#	print $traceopts;
#	print "\n";
#	$self->{_traceobject} = $self->_setup_traceobject;
#	print "Test 2\n";
#	
#	return;
#}

no Moose::Role;

1;                                     # Magic true value required at end of module
