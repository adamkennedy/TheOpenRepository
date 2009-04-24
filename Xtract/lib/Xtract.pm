package Xtract;

=pod

=head1 NAME

Xtract - Take your database and deliver it to the world

=head1 DESCRIPTION

B<THIS APPLICATION IS HIGHLY EXPERIMENTAL>

Xtract is an command line application for extracting data out of
many different types of databases (or other things that are able
to look like a database via L<DBI>).

More information to follow...

=cut

use 5.006;
use strict;
use warnings;
use Getopt::Long  2.37 ();
use Params::Util  0.35 ();
use DBIx::Publish 0.02 ();
use DBI           1.57 ();

our $VERSION = '0.01';

use Object::Tiny 1.06 qw{
	from
	user
	pass
	to
	argv
};

sub main {
	# Parse the command line options
	my $FROM = '';
	my $USER = '';
	my $PASS = '';
	my $TO   = '';
	Getopt::Long::GetOptions(
		"from=s" => \$FROM,
		"user=s" => \$USER,
		"pass=s" => \$PASS,
		"to=s"   => \$TO,
	) or die("Failed to parse options");

	# Create the program instance
	my $self = Xtract->new(
		from => $FROM,
		user => $USER,
		pass => $PASS,
		to   => $TO,
		argv => [ @ARGV ],
	);

	# Run the object
	$self->run;
}

sub run {
	my $self = shift;

	# Connect to the data source
	$self->trace("Connecting to " . $self->from . "...\n");
	my $source = DBI->connect( $self->from, $self->user, $self->pass, {
		PrintError => 1,
		RaiseError => 1,
	} ) or die("Failed to connect to " . $self->from);

	# Create the publish object
	$self->trace("Preparing to publish to " . $self->to . "...\n");
	my $publish = DBIx::Publish->new(
		source => $source,
		file   => $self->to,
	) or die("Failed to create DBIx::Publish");

	# Check the command
	my $command = shift(@ARGV) || 'all';
	unless ( $command eq 'all' ) {
		die("Unsupported command '$command'");
	}

	# Get the list of tables
	my @tables = $publish->dbh->tables('', '', '');
	foreach my $table ( @tables ) {
		$self->trace("Publishing table $table...");
		$publish->table( $table,
			"select * from $table",
		);
	}

	# Clean up
	$self->trace("Cleaning up...\n");
	$publish->finish;
	$source->disconnect;
	$self->trace("Publish run completed\n");

	return 1;
}

sub trace {
	if ( Params::Util::_CODE($_[0]->{trace}) ) {
		$_[0]->trace( @_[1..$#_] );
	} elsif ( $_[0]->{trace} ) {
		print @_[1..$#_];
	}
}

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Xtract>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<DBI>, L<DBIx::Publish>

=head1 COPYRIGHT

Copyright 2009 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
