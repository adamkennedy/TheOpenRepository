use inc::Module::Install;

name           'HTML-Email-Obfuscate';
all_from       'lib/HTML/Email/Obfuscate.pm';
requires       'HTML::Parser' => '2.25';
test_requires 'Test::More'   => '0.47';

WriteAll;
