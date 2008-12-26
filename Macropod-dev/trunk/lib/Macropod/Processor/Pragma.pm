package Macropod::Processor::Pragma;
use strict;
use warnings;

use Module::Pluggable
        require     => 1,
        #instantiate => 'new',
        search_path => 'Macropod::Processor::Pragma',
        only => qr/^Macropod::Processor::Pragma(\w+)$/ ,
        sub_name    => 'processors';

sub process {
    my ($plugin,$doc) = @_;
    my $pragmas = $doc->pragmas;
    my @sections;
    my $pod = "=head2 PRAGMAS (auto discovered)\n\n";
    
    while (my ($status,$pragma) = each %$pragmas ) {
        $pod .= qq|=head3 $status\n\n|;
        $pod .= qq|=over 4\n\n|;
        while ( my ($name , $args ) = each %$pragma ) {
            $pod .= qq|=item L<$name>\n\n|;
            $pod .= qq|    |;
            $pod .= join ( ', ' ,
                map { qq|C<$_>| } @$args
                );
        
        }
        $pod .= qq|=back 4|;
        
    }
	push @sections, $pod;
	return @sections;
}


1;
