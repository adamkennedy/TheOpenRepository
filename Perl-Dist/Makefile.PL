use inc::Module::Install;

all_from       'lib/Perl/Dist.pm';
requires       'Archive::Tar'               => '1.34'; 
requires       'Archive::Zip'               => '1.20';
requires       'File::Copy::Recursive'      => '0.25';
requires       'File::Find::Rule'           => '0.30';
requires       'File::Path'                 => '1.08';
requires       'File::pushd'                => '0.32';
requires       'File::Spec'                 => '3.17';
requires       'File::Remove'               => '0.37';
requires       'File::ShareDir'             => '0.99';
requires       'File::Temp'                 => '0.20';
requires       'HTTP::Status'               => '1.28';
requires       'IPC::Run3'                  => '0.034';
requires       'LWP::UserAgent'             => '2.033';
requires       'LWP::UserAgent::Determined' => 0;
requires       'LWP::Online'                => '0.03';
requires       'Object::Tiny'               => '1.02';
requires       'Tie::File'                  => 0;
requires       'Tie::Slurp'                 => '0.03';
requires       'YAML::Tiny'                 => '1.12';
requires       'Module::CoreList'           => '2.13';
requires       'Params::Util'               => '0.25';
requires       'CPAN'                       => '1.9205';
requires       'PAR::Dist'                  => '0.25';
requires       'Process'                    => '0.20';
requires       'Process::Storable'          => 0;
requires       'Process::Delegatable'       => 0;
requires       'IO::Capture'                => '0.05';
requires       'Win32::File::Object'        => '0.01' if $^O eq 'MSWin32';
test_requires  'Test::More'                 => '0.42';
test_requires  'Test::Script'               => '1.02';
test_requires  'Test::LongString'           => 0;
test_requires  'Probe::Perl'                => '0.01';
install_script 'perldist';
install_share;

WriteAll;

# Look for Inno Setup
use File::Spec;
print "Looking for Inno Setup 5... ";
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
