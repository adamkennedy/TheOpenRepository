use inc::Module::Install;

name           'HTML-TrackerLink';
all_from       'lib/HTML/TrackerLink.pm';
test_requires 'File::Spec'      => '0.80';
test_requires 'Test::More'      => '0.47';

WriteAll;
