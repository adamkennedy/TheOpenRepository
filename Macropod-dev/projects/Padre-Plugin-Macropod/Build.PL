use Padre::PluginBuilder ;
my $plugin = Padre::PluginBuilder->new(
    module_name => 'Padre::Plugin::Macropod',
    provides => [ qw(
	Padre::Plugin::Macropod
	Padre::Task::Macropod
	Padre::Wx::MacropodFrame
	)
    ],
    

);

$plugin->create_build_script;
 
