package ORLite::Migrate;

# See POD at end of file for documentation

use 5.006;
use strict;
use Carp         ();
use Params::Util qw{ _STRING };
use DBI          ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}





#####################################################################
# Constructor and Accessors

sub patches {
	my $dir = shift;

	# Find all files in a directory
	local *DIR;
	opendir( DIR, $dir )       or die "opendir: $!";
	my @files = readdir( DIR ) or die "readdir: $!";
	closedir( DIR )            or die "closedir: $!";

	# Filter to get the patch set
	my @patches = ();
	foreach ( @files ) {
		next unless /^migrate-(\d+)\.pl$/;
		$patches["$1"] = $_;
	}

	return \@patches;
}

1;

__END__

=pod

=head1 NAME

ORLite::Migrate - Extremely light weight SQLite-specific schema migration

=head1 DESCRIPTION

B<THIS CODE IS EXPERIMENTAL AND SUBJECT TO CHANGE WITHOUT NOTICE>

B<YOU HAVE BEEN WARNED!>

L<SQLite> is a light weight single file SQL database that provides an
excellent platform for embedded storage of structured data.

L<ORLite> is a light weight single file Object-Relational Mapper (ORM)
system specifically designed for (and limited to only) work with SQLite.

L<ORLite::Migrate> is a light weight single file Database Schema
Migration enhancement for L<ORLite>.



=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=ORLite-Migrate>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2008 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
