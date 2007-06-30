use strict;
use inc::Module::Install;

name           'PITA-XML';
all_from       'lib/PITA/XML.pm';
requires       'Carp'                    => 0;
requires       'IO::Handle'              => 0;
requires       'IO::Seekable'            => 0;
requires       'IO::File'                => 0;
requires       'IO::String'              => '1.06';
# requires       'File::Flock'             => '101.060501';
requires       'File::Which'             => '0.05';
requires       'File::ShareDir'          => '0.02';
requires       'Params::Util'            => '0.10';
requires       'Class::Inspector'        => '1.11';
requires       'Class::Autouse'          => '1.23';
requires       'Data::Digest'            => '0.02';
requires       'XML::SAX::Writer'        => '0.44';
requires       'XML::SAX::ParserFactory' => '0.13';
requires       'XML::Validator::Schema'  => '1.08';
build_requires 'File::Spec'              => '0.80';
build_requires 'Test::More'              => '0.47';
build_requires 'Test::LongString'        => 0;
install_share;

WriteAll;
