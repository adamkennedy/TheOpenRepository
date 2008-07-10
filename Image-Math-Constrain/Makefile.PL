use inc::Module::Install;

name           'Image-Math-Constrain';
all_from       'lib/Image/Math/Constrain.pm';

build_requires 'Test::More'       => '0.47';
build_requires 'File::Spec'       => '0.82';

auto_install;
WriteAll;
