use inc::Module::Install;

name           ( 'CPAN-Mini-Extract'           );
abstract       ( 'Create CPAN::Mini mirrors with the archives extracted' );
author         ( 'Adam Kennedy <cpan@ali.as>'  );
version_from   ( 'lib/CPAN/Mini/Extract.pm'    );
license        ( 'perl'                        );
requires       ( 'perl'             => '5.006' );
requires       ( 'Carp'             => 0       );
requires       ( 'File::Basename'   => 0       );
requires       ( 'File::Path'       => 0       );
requires       ( 'File::Spec'       => '0.80'  );
requires       ( 'File::Remove'     => '0.24'  );
requires       ( 'File::Find::Rule' => '0.27'  );
requires       ( 'List::Util'       => '1.15'  );
requires       ( 'IO::File'         => 0       );
requires       ( 'IO::Zlib'         => '1.04'  );
requires       ( 'Archive::Tar'     => '1.22'  );
requires       ( 'Params::Util'     => '0.06'  );
requires       ( 'CPAN::Mini'       => '0.40'  );
build_requires ( 'Test::More'       => '0.47'  );

&WriteAll;
