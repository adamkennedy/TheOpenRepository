package WiX3::Role::Traceable;

use 5.008001;
use Moose::Role 0.90;
use WiX3::Trace::Object 0.009100;

our $VERSION = '0.009101';
$VERSION =~ s/_//ms;

sub get_tracelevel {
	my $self = shift;
	return WiX3::Trace::Object->instance()->get_tracelevel(@_);
}

sub set_tracelevel {
	my $self = shift;
	return WiX3::Trace::Object->instance()->set_tracelevel(@_);
}

sub get_testing {
	my $self = shift;
	return WiX3::Trace::Object->instance()->get_testing(@_);
}

sub trace_line {
	my $self = shift;
	return WiX3::Trace::Object->instance()->trace_line(@_);
}

sub push_tracelevel {
	my $self = shift;
	my $new_level = shift;
	
	my $object = \do { WiX3::Trace::Object->instance()->get_tracelevel(); }
	bless $object, 'WiX3::Role::Traceable::Saver';
	
	WiX3::Trace::Object->instance()->set_tracelevel($new_level);
	
	return $object;
}

no Moose::Role;

package WiX3::Role::Traceable::Saver;

sub DESTROY {
	my $self = shift;
	WiX3::Trace::Object->instance()->set_tracelevel(${$self})
}

1;                                     # Magic true value required at end of module
