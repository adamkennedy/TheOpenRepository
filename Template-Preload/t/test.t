use lib 'lib';
use Test::Base tests => 1;
use Template;


use Template::Preload;
my $tp;

CHECK {
    $tp = Template::Preload->provider(
        INCLUDE_PATH => 't/template',
        COMPILE_DIR => 't/compile',
    );
}

my $t = Template->new(
    DEBUG => 1,
    LOAD_TEMPLATES => [$tp],
);

my $output = '';

$t->process('a/b/c/hello.tt', {name => 'Ingy'}, \$output)
    or do {
        die $t->error;
    };

is $output, "Hello, Ingy.\n",
    "output is correct";  

# use Template::Provider;
# 
# my $tp = Template::Provider->new(
#         INCLUDE_PATH => 't/template',
#         COMPILE_DIR => 't/compile',
# );

