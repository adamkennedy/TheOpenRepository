use inc::Module::Install;

name          'Module-Manifest';
all_from      'lib/Module/Manifest.pm';
requires      'perl'           => '5.005';
requires      'Carp'           => 0;
requires      'File::Spec'     => '0.80';
requires      'File::Basename' => 0;
requires      'Params::Util'   => '0.10';

test_requires 'Test::More'          => '0.42';
test_requires 'Test::Kwalitee'      => '1.01';
test_requires 'Test::Signature'     => 0;
test_requires 'Test::Pod'           => '1.14';
test_requires 'Test::Pod::Coverage' => '1.04';
test_requires 'Test::Warn'          => 0;
test_requires 'Test::Perl::Critic'  => 0;

WriteAll;

