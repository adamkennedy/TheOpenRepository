use inc::Module::Install;

name           ( 'CPAN-Mini-Extract'           );
abstract       ( 'Create CPAN::Mini mirrors with the archives extracted' );
author         ( 'Adam Kennedy <cpan@ali.as>'  );
version_from   ( 'lib/CPAN/Mini/Extract.pm'    );
license        ( 'perl'                        );
requires       ( 'perl'             => '5.006' );
requires       ( 'List::Util'       => '1.15'  );
requires       ( 'File::Remove'     => '0.24'  );
requires       ( 'File::Find::Rule' => '0.27'  );
requires       ( 'IO::Zlib'         => '1.04'  );
requires       ( 'Archive::Tar'     => '1.22'  );
requires       ( 'CPAN::Mini'       => '0.40'  );
build_requires ( 'File::Spec'       => '0.80'  );
build_requires ( 'Test::More'       => '0.47'  );
auto_install   (                               );

&WriteAll;
