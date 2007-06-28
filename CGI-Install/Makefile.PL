use strict;
use inc::Module::Install;

name           'CGI-Install';
all_from       'lib/CGI/Install.pm';
requires       'Carp'                => 0;
requires       'File::Copy'          => 0;
requires       'File::Path'          => 0;
requires       'File::Spec'          => '0.80';
requires       'File::chmod'         => '0.31';
requires       'File::Which'         => '0.05';
requires       'File::Remove'        => '0.34';
requires       'File::Basename'      => 0;
requires       'Scalar::Util'        => '1.17';
requires       'Params::Util'        => '0.25';
requires       'Term::Prompt'        => '1.03';
requires       'URI::ToDisk'         => '1.09';
requires       'LWP::Simple'         => '1.41';
requires       'CGI::Capture'        => '1.08';
requires       'Object::Tiny'        => '1.02';
build_requires 'Test::More'          => '0.42';
build_requires 'Test::Script'        => '1.02';
build_requires 'Test::File::Cleaner' => '0.03';
build_requires 'URI'                 => '1.35';
build_requires 'URI::file'           => 0;
install_script 'script/cgi_install';

WriteAll;
