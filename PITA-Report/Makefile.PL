use inc::Module::Install;

name     'PITA-Report';
all_from 'lib/PITA/Report.pm';

requires 'Carp'                    => 0;
requires 'IO::Handle'              => 0;
requires 'IO::Seekable'            => 0;
requires 'IO::File'                => 0;
requires 'IO::String'              => '1.06';
requires 'File::Flock'             => '101.060501';
requires 'Params::Util'            => '0.07';
requires 'File::ShareDir'          => '0.02';
requires 'XML::SAX::Writer'        => '0.43';
requires 'XML::SAX::ParserFactory' => '0.13';
requires 'XML::Validator::Schema'  => '1.08';

build_requires 'File::Spec'        => '0.80';
build_requires 'Test::More'        => '0.47';

install_share;
auto_install;

&WriteAll;
