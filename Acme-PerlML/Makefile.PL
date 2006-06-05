use inc::Module::Install;

name           'Acme-PerlML';
all_from       'lib/Acme/PerlML.pm';
requires       'PPI'                  => '1.002';
requires       'Perl::SAX'            => '0.06';
requires       'XML::Parser::PerlSAX' => 0;
requires       'XML::SAX'             => 0;
build_requires 'Test::More'           => '0.47';
build_requires 'File::Spec'           => '0.80';

WriteAll;
