package SMS::Send;

=pod

=head1 NAME

SMS::Send - Driver-based API for sending SMS messages

=head1 SYNOPSIS

  ...

=head1 DESCRIPTION

SMS::Send is intended to provide a driver-based single API for sending SMS
and MMS messages. The intent is to provide a single API against which to
write the code to send an SMS message.

At the same time, the intent is to remove the limits of some of the previous
attempts at this sort of API, like "must be free internet-based SMS services".

SMS::Send drivers are installed seperately, and might use the web, email or
physical SMS hardware. It could be a free or paid. The details shouldn't
matter.

You should not have to care how it is actually sent, only that it has been
sent (although some drivers may not be able to provide certainty).

=head1 METHODS

=cut

use strict;
use SMS::Send::Driver ();

# Initialize plugin support
use Module::Pluggable
	require     => 0,
	inner       => 0,
	search_path => [ 'SMS::Send' ],
	except      => [ 'SMS::Send::Driver' ],
	sub_name    => '_installed_drivers',

use vars qw{$VERSION @DRIVERS};
BEGIN {
	$VERSION = '0.01';
	@DRIVERS = ();
}

=pod

=head2 installed_drivers

The C<installed_drivers> the list of SMS::Send drivers that are installed
on the current system.

sub installed_drivers {
	my $class = shift;

	unless ( @DRIVERS ) {
		my @rawlist = $class->_installed_drivers;
		foreach my $d ( @rawlist ) {
			$d =~ s/^SMS::Send:://;
			$d =~ s/::/-/g;
		}
		@DRIVERS = @rawlist;
	}

	return @DRIVERS;
}





#####################################################################
# Constructor and Accessors

sub new {
	my $class = shift;
	
}


1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SMS-Send>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>cpan@ali.asE<gt>, L<http://ali.as/>

=head1 COPYRIGHT

Copyright 2005 Adam Kennedy. All rights reserved.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
