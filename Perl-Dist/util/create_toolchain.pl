#!/usr/bin/perl

use strict;
use CPAN;

CPAN::Index->reload;
print "\n\n\n";

my @modules = qw{
	ExtUtils::MakeMaker
	File::Path
	ExtUtils::Command
	Win32API::File
	ExtUtils::Install
	ExtUtils::Manifest
	Test::Harness
	Test::Simple
	ExtUtils::CBuilder
	ExtUtils::ParseXS
	version
	Scalar::Util
	IO::Compress::Base
	Compress::Raw::Zlib
	Compress::Raw::Bzip2
	IO::Compress::Zip
	IO::Compress::Bzip2
	Compress::Zlib
	Compress::Bzip2
	IO::Zlib
	File::Spec
	File::Temp
	Win32API::Registry
	Win32::TieRegistry
	File::HomeDir
	File::Which
	Archive::Zip
	Archive::Tar
	YAML
	Net::FTP
	Digest::MD5
	Digest::SHA1
	Digest::SHA
	Module::Build
	Term::Cap
	CPAN
	Term::ReadLine::Perl
};

my %seen = ();
foreach my $name ( @modules ) {
	# Find the module
	my $module = CPAN::Shell->expand('Module', $name);
	unless ( $module ) {
		die "Failed to find '$name'";
	}

	# Filter out already seen dists
	my $file = $module->cpan_file;
	$file =~ s/^[A-Z]\/[A-Z][A-Z]\///;
	next if $seen{$file}++;

	print "$file\n";
}

exit(0);
