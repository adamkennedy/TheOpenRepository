use inc::Module::Install;

name           ( 'Test-NeedsDisplay'           );
abstract       ( 'Ensure that tests needing a display have one' );
author         ( 'Adam Kennedy <cpan@ali.as>'  );
version_from   ( 'lib/Test/NeedsDisplay.pm'    );
license        ( 'perl'                        );
requires       ( 'perl'             => '5.006' );
requires       ( 'File::Spec'       => '0.80'  );
build_requires ( 'Test::More'       => '0.47'  );
auto_install   (                               );

&WriteAll;
