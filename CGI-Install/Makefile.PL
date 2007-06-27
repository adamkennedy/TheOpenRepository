use strict;
use inc::Module::Install;

name           'CGI-Install';
all_from       'lib/CGI/Install.pm';
requires       'Carp'         => 0;
requires       'File::Copy'   => 0;
requires       'File::Spec'   => '0.80';
requires       'File::chmod'  => '0.31';
requires       'File::Which'  => '0.05';
requires       'Scalar::Util' => '1.17';
requires       'Params::Util' => '0.25';
requires       'Term::Prompt' => '1.03';
requires       'URI::ToDisk'  => '1.09';
requires       'LWP::Simple'  => '1.41';
requires       'CGI::Capture' => '1.08';
requires       'Object::Tiny' => '1.02';
build_requires 'Test::More'   => '0.42';
build_requires 'URI'          => '1.35';

WriteAll;
