#!/usr/bin/perl

use strict;
BEGIN {
	$| = 1;
	$^W = 1;
}

use Test::More tests => 7;
use File::Spec::Functions ':ALL';
use File::Remove ();
use Cwd ();

# Create the test directories
my $cwd  = catdir( 't', 'cwd'     );
my $foo  = catdir( 't', 'foo'     );
my $file = catdir( 't', 'bar.txt' );
File::Remove::clear($cwd_dir);
mkdir($cwd)  or die "mkdir($cwd): $!";
mkdir($foo)  or die "mkdir($foo): $!";
mkdir($file) or die "mkdir($file): $!";
ok( -d $cwd,  "$cwd directory exists" );
ok( -d $foo,  "$foo directory exists" );
ok( -f $file, "$file file exists"     );

# Change the current working directory into the first
# test directory and store the absolute path.
chdir($cwd) or die "chdir($cwd): $!";
my $cwdabs = Cwd::abs_path(Cwd::cwd());
ok( $cwdabs =~ /\bcwd$/, "Expected abs path is $cwdabs" );

# Change into the directory that should be deleted
chdir($foo) or die "chdir($foo): $!";
my $fooabs = Cwd::abs_path(Cwd::cwd());
ok( $fooabs =~ /\bfoo$/, "Deleting from abs path is $fooabs" );

# Delete the foo directory
ok( File::Remove::remove($foo), "remove($foo) ok" );

# We should now be in the bottom directory again
is( Cwd::abs_path(Cwd::cwd()), $cwdabs, "We are now back in the original directory" );
