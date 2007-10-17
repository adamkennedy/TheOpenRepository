use 5.005;
use strict;
use inc::Module::Install;
use File::Spec;

name     'Perl-Dist';
author   'David A Golden <dagolden@cpan.org>';
all_from 'lib/Perl/Dist.pm';

requires 'Archive::Tar'          => '1.34'; 
requires 'Archive::Zip'          => '1.20';
requires 'File::Copy::Recursive' => '0.25';
requires 'File::Find::Rule'      => '0.30';
requires 'File::Path'            => '1.08';
requires 'File::pushd'           => '0.32';
requires 'File::Spec'            => '3.17';
requires 'File::Remove'          => '0.37';
requires 'File::ShareDir'        => '0.05';
requires 'HTTP::Status'          => '1.28';
requires 'IPC::Run3'             => '0.034';
requires 'LWP::UserAgent'        => '2.033';
requires 'LWP::Online'           => '0.02';
requires 'Tie::File'             => 0;
requires 'YAML::Tiny'            => '1.12';
requires 'CPAN'                  => 0;
requires 'Perl::Dist::Downloads' => '0.02';

WriteAll;

print "Looking for Inno Setup 5... ";

# Look for Inno Setup
unless ( $ENV{PROGRAMFILES} and -d $ENV{PROGRAMFILES} ) {
	pexit("Failed to find the Program Files directory\n");
}
my $innosetup_dir  = File::Spec->catdir( $ENV{PROGRAMFILES}, "Inno Setup 5" );
my $innosetup_file = File::Spec->catfile( $innosetup_dir, 'Compil32.exe' );
unless ( -d $innosetup_dir and -f $innosetup_file ) {
	pexit(
		"failed\n",
		"\n",
		"  Failed to find an installation of Inno Setup 5\n",
		"  Please install http://www.jrsoftware.org/download.php/is.exe\n",
	);
}
print "OK\n";

sub pexit {
	print(@_, "\n");
	exit(0);
}
