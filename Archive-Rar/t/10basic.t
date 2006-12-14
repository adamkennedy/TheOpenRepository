
use Test::Simple tests => 4;
eval "use Archive::Rar";
ok (!$@, "use Archive::Rar");

#$^W=1;
my $t1 = Archive::Rar->new ();
ok ($t1, "new Archive::Rar");

ok ($t1->isa('Archive::Rar'), "object is a Archive::Rar");
my $help=$t1->GetHelp;
ok ($help=~/rar/i,"help contains 'rar'");
#print $t1->GetHelp;
1;
