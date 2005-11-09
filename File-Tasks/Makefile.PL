use inc::Module::Install;

name           ( 'File-Tasks'                       );
abstract       ( 'Manipulate sets of file tasks, to be applied to a filesystem');
author         ( 'Adam Kennedy <adam@phase-n.com>'  );
version_from   ( 'lib/File/Tasks.pm'                );
requires       ( 'perl'                 => '5.005'  );
requires       ( 'Clone'                => '0.13'   );
requires       ( 'File::Find::Rule'     => '0.20'   );
requires       ( 'File::Flat'           => '0.92'   );
requires       ( 'File::Spec'           => '0.82'   );
requires       ( 'List::Util'           => '1.15'   );
requires       ( 'Scalar::Util'         => '1.15'   );
requires       ( 'Archive::Builder'     => '1.04'   );
requires       ( 'Param::Coerce'        => '0.05'   );
requires       ( 'Params::Util'         => '0.06'   );
build_requires ( 'Test::More'           => '0.47'   );
build_requires ( 'Test::ClassAPI'       => '1.02'   );
include        ( 'Test::ClassAPI'                   );
no_index       ( directory              => 't.data' );
auto_install   (                                    );

&WriteAll;
