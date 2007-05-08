package Devel::TimingMonitor;

=pod

=head1 NAME

Devel::TimingMonitor - Instrument arbitrary code to monitor calls

=head1 SYNOPSIS

=head1 DESCRIPTION

One of the most obvious and interesting technologies to come out of out
the field of Aspect-Oriented Computing in the Java world is the
instrumentation of arbitrary code.

In short, it lets you creates places in any code you like, even if it is
not your own, that will be tracked, timed, analysed, and possibly
recorded.

This makes for an excellent debugging tool.

Perl has had Aspect-like capabilities since before the term existed. 
Moreover, it can create these cutpoints on the fly at run-time.

So it is a fairly straight forward idea that creating useful instrumention
of code for monitoring and debugging should be worth doing.

B<Devel::TimingMonitor> provides a platform for creating these
instruments for monitoring arbitrary code.

It uses on L<Time::HiRes> and L<Hook::LexWrap> to track calls to specific
functions you identify, and after the function has been called, reports
the context of the call, when it ran, and how long it took to run.

Note that it does only provide this basic first layer of functionality.

There are a myriad of ways in which the data might need to be interpreted.

For example, you may want to know the 5 slowest calls to a function for
a given program run. Or you may only want to know of calls that are 10
times (or more) slower than the average time.

You may want to log each and every call to the function, and how long
it took.

Building on top of L<Devel::Instrument> itself, which only creates and
modifies the hooks themselves, will be a number of additional
task-specific modules.

=head1 FUNCTIONS

=cut

use 5.006;
use strict;
use Carp          'croak';
use Hook::LexWrap ();
use Time::HiRes   ();
use Params::Util  '_CODE';

our $VERSION = '0.01';

# Record which functions are hooked
my %INSTRUMENT = ();

# Track the calls currently underway
my @CALLS = ();





#####################################################################
# Setup Methods

# Manually inject a specific hook
sub create_instrument {
	my %args = ();
	unless ( _STRING($args{function}) ) {
		croak('Did not provide a function name to create_hook');
	}
	unless ( _CODE($args{instrument}) ) {
		croak('The instrument param to create_hook is not a CODE reference');
	}
	if ( exists $args{condition} and ! _CODE($args{condition}) ) {
		croak('The condition param to create_hook is not a CODE reference');
	}

	### Check if the function exists

	# Set the hook function
	$INSTRUMENT{$arg{function}} = $args;

	### Set up the hook
	eval <<"END_INSTRUMENT";
Hook::LexWrap::wrap(
	*$args{function},
	pre => sub {
		Devel::TimingMonitor::_pre(
			'$args{function}',
			\@_,
		);
	},
	post => sub {
		Devel::TimingMonitor::_post(
			'$args{function}',
			\@_,
		);
	},
);
END_INSTRUMENT
	croak("Failed to set instrument hook for $args{function}: $@") if $@;

}






#####################################################################
# Support/Implementation Methods

# Create the call entry and save it
sub _pre {
	push @CALLS, {
		name       => shift,
		caller     => [ caller(0) ],
		start_time => Time::HiRes::time(),
		end_time   => undef,
		duraction  => undef,
		};
	return;
}

# Remove the call entry and hand off
sub _post {
	my $call = pop @CALLS;
	$call->{end_time} = Time::HiRes::time();
	$call->{args}     = [ @_[0..$#_] ];
	$call->{returned} = $_[-1];
	$call->{duration} = $call->{end_time} - $call->{start_time};

	# Get the hook and hand off (if it is still registered)
	my $hook = $INSTRUMENT{$call->{name}} or return;
	if ( $hook{condition} ) {
		local $_ = $call;
		return unless $hook{condition}->();
	}		
	$hook{instrument}->( $call );
	return;
}

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Devel::Instrument>

For other issues, or commercial enhancement or support, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<Hook::LexWrap>, L<Time::HiRes>, L<ali.as>

=head1 COPYRIGHT

Copyright 2006 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
