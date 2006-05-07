#!/usr/bin/perl -w

# Load testing for File::LocalizeNewlines

use strict;
use lib ();
use File::Spec::Functions ':ALL';
BEGIN {
	$| = 1;
	unless ( $ENV{HARNESS_ACTIVE} ) {
		require FindBin;
		$FindBin::Bin = $FindBin::Bin; # Avoid a warning
		chdir catdir( $FindBin::Bin, updir() );
		lib->import(
			catdir('blib', 'arch'),
			catdir('blib', 'lib' ),
			catdir('lib'),
			);
	}
}

use Test::More tests => 46;
use FileHandle             ();
use File::Slurp            ();
use File::Find::Rule       ();
use File::LocalizeNewlines ();
use constant FLN => 'File::LocalizeNewlines';
use constant FFR => 'File::Find::Rule';

# Create various test files
my $local_file = catfile( 't', 'data', 'local.txt' );
my $simple_dir = catfile( 't', 'data', 'simple' );
my $not_file   = catfile( 't', 'data', 'simple', 'both.txt' );
my $not_file2  = catfile( 't', 'data', 'simple', 'both.pm' );
File::Slurp::write_file( $local_file, "foo\nbar\n" );
File::Slurp::write_file( $not_file,   "foo\015\012bar\015baz" );
File::Slurp::write_file( $not_file2,  "foo\015\012bar\015baz" );
is( length(File::Slurp::read_file( $not_file )),  12, 'both.txt is the right length' );
is( length(File::Slurp::read_file( $not_file2 )), 12, 'both.pm is the right length' );

END {
	unlink $local_file if -e $local_file;
	unlink $not_file   if -e $not_file;
	unlink $not_file2  if -e $not_file2;
}





#####################################################################
# Constructor and Accessors

{
	my $Object = FLN->new;
	isa_ok( $Object, 'File::LocalizeNewlines' );

	ok( ! exists $Object->{Find}, 'New object does not have a Find property' );
	ok( ! exists $Object->{newline}, 'New object does not have a newline property' );

	isa_ok( $Object->Find, 'File::Find::Rule' );
	is( $Object->newline, "\n", '->newline returns the platform newline' );
}

{
	my $Object = FLN->new( newline => 'foo' );
	isa_ok( $Object, FLN );
	
	ok( ! exists $Object->{Find}, 'New object does not have a Find property' );
	ok( exists $Object->{newline}, 'New object has a newline property' );

	isa_ok( $Object->Find, 'File::Find::Rule' );
	is( $Object->newline, "foo", '->newline returns the custom value' );
}

{
	my $rule = newFFR()->name('*.pm');
	my $Object = FLN->new( filter => $rule );
	isa_ok( $Object, FLN );
	
	ok( exists $Object->{Find}, 'New object does not have a Find property' );
	ok( ! exists $Object->{newline}, 'New object has a newline property' );

	isa_ok( $Object->Find, 'File::Find::Rule' );
	is( $Object->Find, $rule, 'Rule returned is the one we passed' );
	is( $Object->newline, "\n", '->newline returns the platform value' );
}

{
	my $rule = newFFR()->name('*.pm');
	my $Object = FLN->new( newline => 'foo', filter => $rule );
	isa_ok( $Object, FLN );
	
	ok( exists $Object->{Find}, 'New object does not have a Find property' );
	ok( exists $Object->{newline}, 'New object has a newline property' );

	isa_ok( $Object->Find, 'File::Find::Rule' );
	is( $Object->Find, $rule, 'Rule returned is the one we passed' );
	is( $Object->newline, "foo", '->newline returns the custom value' );
}





#####################################################################
# Localisation Testing

{
	my $Object = FLN->new;
	isa_ok( $Object, FLN );
	ok( $Object->localized( $local_file ),   '->localized returns true for known-local file' );
	ok( ! $Object->localized( $not_file ),   '->localized returns true for known-local file' );
	ok( FLN->localized( $local_file ),       'static->localized returns false for known-not-local file' );
	ok( ! FLN->localized( $not_file ),       'static->localized returns false for known-not-local file' );

	# FileHandle versions
	my $local_handle = new FileHandle("< $local_file");
	my $not_handle   = new FileHandle("< $not_file");
	ok( $Object->localized( $local_handle ), '->localized returns true for known-local file handle' );
	ok( ! $Object->localized( $not_handle ), '->localized returns true for known-local file handle' );
	$local_handle = new FileHandle("< $local_file");
	$not_handle   = new FileHandle("< $not_file");
	ok( FLN->localized( $local_handle ),     'static->localized returns false for known-not-local file handle' );
	ok( ! FLN->localized( $not_handle ),     'static->localized returns false for known-not-local file handle' );
}






#####################################################################
# Finding

{
	my $Object = FLN->new;
	isa_ok( $Object, FLN );

	my @files = $Object->find( $simple_dir );
	@files = grep { ! /ignore/ } grep { ! /CVS/ } @files; # For when building
	is_deeply( \@files, [qw{both.txt both.pm}], '->find returns expected for normal search' );
}

{
	my @files = FLN->find( $simple_dir );
	@files = grep { ! /ignore/ } grep { ! /CVS/ } @files; # For when building
	is_deeply( \@files, [qw{both.txt both.pm}], '->find returns expected for normal search' );
}

{
	my $rule = newFFR()->name('*.pm');
	my $Object = FLN->new( filter => $rule );
	isa_ok( $Object, FLN );

	my @files = $Object->find( $simple_dir );
	is_deeply( \@files, [qw{both.pm}], '->find returns expected for filtered search' );
}





#####################################################################
# Localisation

{
	my $Object = FLN->new( filter => newFFR() );
	isa_ok( $Object, FLN );

	is( $Object->localize( $simple_dir ), 2, '->localize returns the correct number of files' );
	my $length1 = length(File::Slurp::read_file($not_file));
	my $length2 = length(File::Slurp::read_file($not_file2));
	ok( ($length1 == 11 or $length1 == 13), 'length for both.txt is as expected' );
	ok( ($length2 == 11 or $length2 == 13), 'length for both.pm is as expected' );
}

{
	my $Object = FLN->new( filter => newFFR()->name('*.pm'), newline => 'foo' );
	isa_ok( $Object, FLN );
	
	is( $Object->localize( $simple_dir ), 1, '->localize returns the correct number of files' );
	my $length1 = length(File::Slurp::read_file($not_file));
	my $content2 = File::Slurp::read_file($not_file2);
	ok( ($length1 == 11 or $length1 == 13), 'length for both.txt is as expected' );
	is( $content2, 'foofoobarfoobaz', 'Content of both.pm modified as expected' );
}

exit(0);






# Support Functions

sub newFFR {
	FFR->or(
		FFR->directory->name('CVS')->prune->discard,
		FFR->new
	);
}
