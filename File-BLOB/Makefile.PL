use inc::Module::Install;

name           ( 'File-BLOB'                       );
abstract       ( "A file (with name, and other metadata) you can BLOBify" );
author         ( 'Adam Kennedy <adam@phase-n.com>' );
version_from   ( 'lib/File/BLOB.pm'                );
requires       ( 'perl'                 => '5.005' );
requires       ( 'bytes'                => 0       );
requires       ( 'Carp'                 => 0       );
requires       ( 'File::Basename'       => 0       );
requires       ( 'Storable'             => 0       );
requires       ( 'Params::Util'         => '0.06'  );
build_requires ( 'File::Spec'           => '0.80'  );
build_requires ( 'Test::More'           => '0.47'  );
auto_install   (                                   );

&WriteAll;
