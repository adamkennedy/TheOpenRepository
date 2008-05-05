use inc::Module::Install;

name           'Business-AU-Data-Postcode';
all_from       'lib/Business/AU/Data/Postcode.pm';
requires       'Data::Package::CSV';
test_requires 'Test::More' => '0.42';
install_share;

WriteAll;
