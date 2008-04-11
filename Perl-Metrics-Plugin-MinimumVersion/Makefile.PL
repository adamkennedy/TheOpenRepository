use inc::Module::Install;

name          'Perl-Metrics-Plugin-MinimumVersion';
all_from      'lib/Perl/Metrics/Plugin/MinimumVersion.pm';
# Version 0.48 gets rid of the XS bugs at least
# We need a newer version to deal with the qv() bug
requires      'version'              => '0.48';
requires      'Perl::Metrics'        => '0.03';
requires      'Perl::MinimumVersion' => '0.10';
test_requires 'Test::More'           => '0.47';
test_requires 'File::Spec'           => '0.80';

WriteAll;
