use Module::Build;
my $build = Module::Build->new
(
module_name => 'Macropod',
dist_version_from => 'lib/Macropod/Parser.pm' ,
license  => 'perl',
requires => {
                'perl' 		=> 0,
                'PPI'  		=> 0,
		'YAML'		=> 0,
		'Carp'		=> 0,
		'Class::Accessor'	=>	0,
		'Pod::Simple' => 0,
		'File::HomeDir' => 0,
		'DBI' => 0,
            },

#pm_files => {
#	'lib/Macropod/Parser.pm' => 'lib/Macropod/Parser.pm',
#	'lib/Macropod/Document.pm' => 'lib/Macropod/Document.pm',
#	'lib/Macropod/Cache.pm' => 'lib/Macropod/Cache.pm' ,
#	'lib/Macropod/Signature.pm' => 'lib/Macropod/Signature.pm',
#}

);
$build->create_build_script;

