use inc::Module::Install 0.82;

all_from      'lib/File/Find/Rule/Perl.pm';
requires      'File::Spec'        => winlike() ? '3.27' : '0.82';
requires      'File::Find::Rule'  => '0.20';
requires      'Params::Util'      => '0.38';
requires      'Parse::CPAN::Meta' => '0.04';
test_requires 'Test::More'        => '0.47';

WriteAll;
