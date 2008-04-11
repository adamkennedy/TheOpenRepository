use inc::Module::Install;

name           'Acme-PerlML';
all_from       'lib/Acme/PerlML.pm';
requires       'PPI'                  => '1.002';
requires       'XML::Parser::PerlSAX' => 0;
requires       'XML::SAX'             => 0;
requires       'Perl::SAX'            => '0.06';
test_requires 'Test::More'           => '0.47';
test_requires 'File::Spec'           => '0.80';

WriteAll;
