use inc::Module::Install;

name          'Module-Manifest';
all_from      'lib/Module/Manifest.pm';

requires      'perl'           => '5.005';
# Pragmas required
requires      'Carp'           => 0;
requires      'strict'         => 0;

# Other helper modules required
requires      'File::Spec'     => '0.80';
requires      'File::Basename' => 0;
requires      'Params::Util'   => '0.10';

test_requires 'Test::More'          => '0.42';
test_requires 'Test::Kwalitee'      => '1.01';
test_requires 'Test::Signature'     => '1.10';
test_requires 'Test::Pod'           => '1.14';
test_requires 'Test::Pod::Coverage' => '1.04';
test_requires 'Test::Warn'          => '0.11';
test_requires 'Test::Perl::Critic'  => '1.01';
test_requires 'Test::Exception'     => '0.27';

WriteAll;

