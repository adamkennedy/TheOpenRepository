package Test::POE::Stopping;

=pod

=head1 NAME

Test::POE::Stopped - Test if a POE process has nothing left to do

=head1 DESCRIPTION

L<POE> is a curious beast, as most asynchronous environments are.

But in regards to testing, one of the more interesting (and when it's not
working properly, annoying) situations is how to tell if the POE-controlled
process will, or has, stopped.

The obvious solution is to just say something like

  POE::Kernel->run;
  pass( "POE stopped" );

But this isn't really useful to us, because this test never fails, it just
deadlocks forever if some event generator is left around.

B<Test::POE::Stopped> takes an introspective method in determining this.

In your test script, a top level controlling session should be set up.

In this session, you should set a delayed alarm, that SHOULD fire after
everything is finished, and POE should have naturally stopped.

The delayed alarm will keep POE from returning, but it should make the alarm
the very last event called.

In this event you call the C<poe_stopping> function, which will examine the
running L<POE::Kernel> to see if it displays the characteristics of one
with the last event in progress (no other sessions, empty queue, no event
generators, etc).

If POE is B<not> stopping, then the C<poe_stopping> function will emit a
fail result and then do a hard-stop of the POE kernel.

=cut

use strict;
use Test::Builder  ();
use POE            ('Session');
use POE::API::Peek ();

use vars qw{$VERSION @ISA @EXPORT};
BEGIN {
	require Exporter;
	$VERSION = '0.01';
	@ISA     = 'Exporter';
	@EXPORT  = 'poe_stopping';
}


my $Test = Test::Builder->new;

sub import {
	my $self = shift;
	my $pack = caller;
	$Test->exported_to($pack);
	$Test->plan(@_);
	$self->export_to_level(1, $self, 'poe_stopping');
}





#####################################################################
# Main Methods

=pod

=head2 poe_stopping

  poe_stopping();

The C<poe_stopping> test checks the kernel to see if, after the current
event, the POE kernel will have nothing else left to do and so will stop.

=cut

sub poe_stopping {
	my $result = _poe_stopping();
	$Test->ok( $result, 'POE appears to be stopping cleanly' );
	$poe_kernel->stop unless $result;
	return 1;	
}		

sub _poe_stopping {
	my $api = POE::API::Peek->new;

	# The kernel should be running
	return undef unless $api->is_kernel_running;

	# There should only be one session left
	# Why 2? One for the controlling session, one for the kernel
	return undef unless $api->session_count == 2;

	# There should be no events left for this session
	return undef if $api->event_queue->get_item_count;

	# The kernel should not be tracking any handles
	return undef if $api->handle_count;

	# Is this last session watching any signals
	my %signals = eval {
		$api->signals_watched_by_session;
		};
	# Catch and handle a bug in POE
	if ( $@ and $@ =~ /^Can\'t use an undefined value as a HASH reference/ ) {
		%signals = ();
	}
	return undef if %signals;

	# Looks good
	return 1;
}

1;

=pod

=head1 SUPPORT

All bugs should be filed via the bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-POE-Stopping>

For other issues, or commercial enhancement and support, contact the author

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<POE>, L<http://ali.as/>

=head1 COPYRIGHT

Copyright 2006 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
