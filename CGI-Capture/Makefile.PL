use inc::Module::Install;

name           'CGI-Capture';
all_from       'lib/CGI/Capture.pm';
requires       'Storable'   => '2.11';
requires       'IO::String' => '1.07';
build_requires 'Test::More' => '0.47';
build_requires 'File::Spec' => '0.80';

auto_install;
WriteAll;
