use inc::Module::Install 0.76;

all_from       'lib/PPI/PowerToys.pm';
requires       'version'                => '0.74';
requires       'File::Spec'             => '0.80';
requires       'File::Find::Rule'       => 0;
requires       'File::Find::Rule::Perl' => '0.03';
requires       'PPI'                    => '1.201';
test_requires  'Test::More'             => '0.47';
test_requires  'Test::Script'           => '1.03';
install_script 'ppi_version';

WriteAll;
