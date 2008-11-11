use inc::Module::Install 0.77;

all_from       'lib/Perl/Dist.pm';
requires       'Archive::Tar'               => '1.38';
requires       'Archive::Zip'               => '1.25';
requires       'File::Spec'                 => '3.2701';
requires       'File::Copy::Recursive'      => '0.37';
requires       'File::Find::Rule'           => '0.30';
requires       'File::Path'                 => '2.04';
requires       'File::pushd'                => '1.00';
requires       'File::Remove'               => '1.42';
requires       'File::HomeDir'              => '0.81';
requires       'File::ShareDir'             => '1.00';
requires       'File::PathList'             => '1.04';
requires       'File::Temp'                 => '0.20';
requires       'HTTP::Status'               => '5.817';
requires       'IPC::Run3'                  => '0.042';
requires       'LWP::UserAgent'             => '5.817';
requires       'LWP::UserAgent::Determined' => '1.03';
requires       'LWP::Online'                => '1.07';
requires       'Object::Tiny'               => '1.06';
requires       'YAML::Tiny'                 => '1.32';
requires       'Module::CoreList'           => '2.15';
requires       'Params::Util'               => '0.33';
requires       'Template'                   => '2.20';
requires       'CPAN'                       => '1.93';
requires       'PAR::Dist'                  => '0.37';
requires       'Process'                    => '0.22';
requires       'Process::Storable'          => '0.22';
requires       'Process::Delegatable'       => '0.22';
requires       'IO::Capture'                => '0.05';
requires       'Win32::File::Object'        => '0.01' if $^O eq 'MSWin32';
requires       'Portable::Dist'             => '0.02';
requires       'Probe::Perl'                => '0.01';
test_requires  'Test::More'                 => '0.86';
test_requires  'Test::Script'               => '1.03';
test_requires  'Test::LongString'           => '0.11';
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
