use inc::Module::Install;

name           'Business-AU-Data-ANZIC';
all_from       'lib/Business/AU/Data/ANZIC.pm';
requires       'Data::Package::CSV' => '1.00';
test_requires 'Test::More'         => '0.42';
install_share;

WriteAll;
