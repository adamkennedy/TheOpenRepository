use inc::Module::Install;

name           'Perl-SAX';
all_from       'lib/Perl/SAX.pm';
requires       'XML::SAX::Base'   => '1.04';
requires       'XML::SAX::Writer' => '0.44';
requires       'PPI'              => '1.002';
build_requires 'File::Spec'       => '0.80';
build_requires 'Test::More'       => '0.47';

auto_install;
WriteAll;
