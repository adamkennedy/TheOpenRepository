use inc::Module::Install;

name           'Data-Package';
all_from       'lib/Data/Package.pm';
requires       'Class::Inspector' => '1.07';
requires       'Params::Coerce'   => '0.06';
build_requires 'Test::More'       => '0.47';

WriteAll;
