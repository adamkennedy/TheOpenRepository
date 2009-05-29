package ORLite::Stub;

=pod

=head1 NAME

ORLite::Stub - Stub database generator for ORLite::Mirror

=head1 SYNOPSIS

  my $generator = ORLite::Stub->new(
      from   => 'My::Project::DB',
  );
  
  $generator->run;

=head1 DESCRIPTION

B<THIS MODULE IS EXPERIMENTAL AND SUBJECT TO CHANGE WITHOUT NOTICE.>

B<YOU HAVE BEEN WARNED!>

The biggest downside of L<ORLite::Mirror> is the need for download the
remote SQLite file in order to generate the ORM correctly. It essentially
requires you to download many megabytes from the internet at compile time.

This can be a major inconvenience in many situations.

L<ORLite::Mirror> provides a "stub" option to compensate for this problem,
by using an locally-cached identical copy of the database with no actual
data to bootstrap the ORM, and then download the actual data-filled version
on first connection.

B<ORLite::Stub> provides a relatively simple function which automates the
creation or update of these stub database from the real downloaded one.

See the documentation for L<orlite2stub> for more information on how to
do the generation from the command line.

=cut

use 5.008;
use strict;
use File::Copy        ();
use File::Spec   0.86 ();
use File::Remove 1.42 ();
use DBI         1.607 ();
use DBD::SQLite  1.25 ();

our $VERSION = '0.01';

use Object::Tiny 1.04 qw{
	from
};





######################################################################
# Main Methods

sub run {
	my $self = shift;
	my $stub = File::Spec->catfile('share', 'stub.db');

	# Create the stub directory if it doesn't exist
	unless ( -d 'share' ) {
		mkdir('share') or die "Failed to create share dir";
	}

	# Flush any existing stub database
	File::Remove::remove($stub) if -f $stub;

	# Copy the module's SQLite file to the stub file
	File::Copy::copy(
		$self->from->sqlite,
		$stub,
	) or die "Failed to copy module database to stub location";

	# Connect to the stub database
	my $dbh = DBI->connect("DBI:SQLite:$stub");
	unless ( $dbh ) {
		die "Failed to connect to the stub database";
	}

	# Clear out all the tables
	my $truncate = $dbh->selectcol_arrayref(
		'select name from sqlite_master where name not like ? and type = ?',
		{}, 'sqlite_%', 'table',
	);
	foreach my $table ( @$truncate ) {
		$dbh->do("DELETE FROM $table");
	}

	# Clean up
	$dbh->do("VACUUM");
	$dbh->disconnect;

	1;
}

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=ORLite-Stub>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2009 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
