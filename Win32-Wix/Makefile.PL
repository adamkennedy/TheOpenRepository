use inc::Module::Install;

name                  'Perl-Dist-Wix';
all_from              'lib/Perl/Dist/Wix.pm';
build_requires        'Test::More' => '0';
requires_external_bin 'candle';

WriteAll;
