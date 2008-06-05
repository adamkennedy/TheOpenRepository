package Time::Tiny;

=pod

=head1 NAME

Time::Tiny - A time object, with as little code as possible

=head1 SYNOPSIS

  # Create a time manually
  $christmas = Time::Tiny->new(
      year  => 2006,
      month => 12,
      day   => 25,
      );
  
  # Show the current time
  $today = Time::Tiny->now;
  print "Year : " . $today->year  . "\n";
  print "Month: " . $today->month . "\n";
  print "Day  : " . $today->day   . "\n"; 

=head1 DESCRIPTION

B<Time::Tiny> is a member of the L<DateTime::Tiny> suite of time modules.

It implements an extremely lightweight object that represents a time,
without any time data.

=head2 The Tiny Mandate

Many CPAN modules which provide the best implementation of a concept
can be very large. For some reason, this generally seems to be about
3 megabyte of ram usage to load the module.

For a lot of the situations in which these large and comprehensive
implementations exist, some people will only need a small fraction of the
functionality, or only need this functionality in an ancillary role.

The aim of the Tiny modules is to implement an alternative to the large
module that implements a subset of the functionality, using as little
code as possible.

Typically, this means a module that implements between 50% and 80% of
the features of the larger module, but using only 100 kilobytes of code,
which is about 1/30th of the larger module.

=head2 The Concept of Tiny Date and Time

Due to the inherent complexity, Date and Time is intrinsically very
difficult to implement properly.

The arguably B<only> module to implement it completely correct is
L<DateTime>. However, to implement it properly L<DateTime> is quite slow
and requires 3-4 megabytes of memory to load.

The challenge in implementing a Tiny equivalent to DateTime is to do so
without making the functionality critically flawed, and to carefully
select the subset of functionality to implement.

If you look at where the main complexity and cost exists, you will find
that it is relatively cheap to represent a date or time as an object,
but much much more expensive to modify or convert the object.

As a result, B<Time::Tiny> provides the functionality required to
represent a date as an object, to stringify the date and to parse it
back in, but does B<not> allow you to modify the dates.

The purpose of this is to allow for date object representations in
situations like log parsing and fast real-time work.

The problem with this is that having no ability to modify date limits
the usefulness greatly.

To make up for this, B<if> you have L<DateTime> installed, any
B<Time::Tiny> module can be inflated into the equivalent L<DateTime>
as needing, loading L<DateTime> on the fly if necesary.

For the purposes of date/time logic, all B<Time::Tiny> objects exist
in the "C" locale, and the "floating" time zone (although obviously in a
pure date context, the time zone largely doesn't matter).

When converting up to full L<DateTime> objects, these local and time
zone settings will be applied (although an ability is provided to
override this).

In addition, the implementation is strictly correct and is intended to
be very easily to sub-class for specific purposes of your own.

=head1 METHODS

In general, the intent is that the API be as close as possible to the
API for L<DateTime>. Except, of course, that this module implements
less of it.

=cut

use strict;
BEGIN {
	require 5.004;
	$Time::Tiny::VERSION = '1.02';
}
use overload 'bool' => sub () { 1 };
use overload '""'   => 'as_string';
use overload 'eq'   => sub { "$_[0]" eq "$_[1]" };
use overload 'ne'   => sub { "$_[0]" ne "$_[1]" };





#####################################################################
# Constructor and Accessors

=pod

=head2 new

  # Create a Time::Tiny object for midnight
  my $midnight = Time::Tiny->new(
      hour   => 0,
      minute => 0,
      second => 0,
      );

The C<new> constructor creates a new B<Time::Tiny> object.

It takes three named params. C<hour> should be the hour of the day (0-23),
C<minute> should be the minute of the hour (0-59), and C<second> should be
the second of the minute (0-59).

These are the only params accepted.

Returns a new B<Time::Tiny> object.

=cut

sub new {
	my $class = shift;
	bless { @_ }, $class;
}

=pod

=head2 now

  my $current_time = Time::Tiny->now;

The C<now> method creates a new date object for the current time.

The time created will be based on localtime, despite the fact that
the time is created in the floating time zone.

This means that the time created by C<now> is somewhat lossy, but
since the primary purpose of B<Time::Tiny> is for small transient
time objects, and B<not> for use in calculations and comparisons,
this is considered acceptable for now.

Returns a new B<Time::Tiny> object.

=cut

sub now {
	my @t = localtime time;
	return $_[0]->new(
		hour   => $t[2],
		minute => $t[1],
		second => $t[0],
		);
}

=pod

=head2 hour

The C<hour> accessor returns the hour component of the time as
an integer from zero to twenty-three (0-23) in line with 24-hour
time.

=cut

sub hour {
	$_[0]->{hour} || 0;
}

=pod

=head2 minute

The C<minute> accessor returns the minute component of the time
as an integer from zero to fifty-nine (0-59).

=cut

sub minute {
	$_[0]->{minute} || 0;
}

=pod

=head2 second

The C<second> accessor returns the second component of the time
as an integer from zero to fifty-nine (0-59).

=cut

sub second {
	$_[0]->{second} || 0;
}





#####################################################################
# Type Conversion

=pod

=head2 from_string

The C<from_string> method creates a new B<Time::Tiny> object from a string.

The string is expected to be an "hh:mm:ss" type ISO 8601 time string.

  my $almost_midnight = Time::Tiny->from_string( '23:59:59' );

Returns a new B<Time::Tiny> object, or throws an exception on error.

=cut

sub from_string {
	my $string = $_[1];
	unless ( defined $string and ! ref $string ) {
		Carp::croak("Did not provide a string to from_string");
	}
	unless ( $string =~ /^(\d\d):(\d\d):(\d\d)$/ ) {
		Carp::croak("Invalid time format (does not match ISO 8601 hh:mm:ss)");
	}
	return $_[0]->new(
		hour   => $1 + 0,
		minute => $2 + 0,
		second => $3 + 0,
		);
}

=pod

=head2 as_string

The C<as_string> method converts the time object to an ISO 8601
time string, with seperators (see example in C<from_string>).

Returns a string.

=cut

sub as_string {
	sprintf( "%02u:%02u:%02u",
		$_[0]->hour,
		$_[0]->minute,
		$_[0]->second,
		);
}

=pod

=head2 DateTime

The C<DateTime> method is used to create a L<DateTime> object
that is equivalent to the B<Time::Tiny> object, for use in
comversions and caluculations.

As mentioned earlier, the object will be set to the 'C' locate,
and the 'floating' time zone.

If installed, the L<DateTime> module will be loaded automatically.

Returns a L<DateTime> object, or throws an exception if L<DateTime>
is not installed on the current host.

=cut

sub DateTime {
	require DateTime;
	my $self = shift;
	DateTime->new(
		year      => 1970,
		month     => 1,
		day       => 1,	
		hour      => $self->hour,
		minute    => $self->minute,
		second    => $self->second,
		locale    => 'en_US',
		time_zone => 'floating',
		@_,
		);
}

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Time-Tiny>

For other issues, or commercial enhancement or support, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<DateTime>, L<DateTime::Tiny>, L<Time::Tiny>, L<Config::Tiny>, L<ali.as>

=head1 COPYRIGHT

Copyright 2006 - 2008 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
