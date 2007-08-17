use strict;
use inc::Module::Install;

name           'pip';
all_from       'lib/pip.pm';
requires       'Carp'           => 0;
requires       'File::Basename' => 0;
requires       'File::Spec'     => ($^O eq 'MSWin32')
	? '3.23' # On Windows we need the rel2abs volume improvements
	: '0.80';
requires       'File::Which'    => '0.05';
requires       'File::Temp'     => '0.15';
requires       'File::pushd'    => '0.32';
requires       'Getopt::Long'   => 0;
requires       'CPAN'           => '1.76';
requires       'CPAN::Inject'   => '0.07';
requires       'Params::Util'   => '0.21s';
requires       'URI'            => 0;
requires       'LWP::Simple'    => 0;
build_requires 'Test::More'     => '0.42';
build_requires 'Test::Script'   => '1.02';
build_requires 'LWP::Online'    => '0.02';
install_script 'script/pip';

# Required for p5z creation and extraction
requires       'IO::Zlib'       => 0;
requires       'Archive::Tar'   => 0;

WriteAll;
