use inc::Module::Install;

author        'Adam Kennedy <adamk@cpan.org>';
all_from      'lib/Config/Relative.pm';
requires      'File::Spec'     => '0.82';
requires      'File::HomeDir'  => '0.64';
requires      'Params::Util'   => '0.20';
test_requires 'Test::More'     => '0.42';

WriteAll;
