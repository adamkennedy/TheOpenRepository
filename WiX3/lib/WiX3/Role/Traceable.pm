package WiX3::Role::Traceable;

use 5.008001;
use Moose::Role 0.90;
use WiX3::Trace::Object 0.009100;

our $VERSION = '0.009100';
$VERSION =~ s/_//ms;

sub get_tracelevel {
	my $self = shift;
	WiX3::Trace::Object->instance()->get_tracelevel(@_);
}

sub set_tracelevel {
	my $self = shift;
	WiX3::Trace::Object->instance()->set_tracelevel(@_);
}

sub get_testing {
	my $self = shift;
	WiX3::Trace::Object->instance()->get_testing(@_);
}

sub trace_line {
	my $self = shift;
	WiX3::Trace::Object->instance()->trace_line(@_);
}

no Moose::Role;

1;                                     # Magic true value required at end of module
