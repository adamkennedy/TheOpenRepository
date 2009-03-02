package Pod::Abstract::Filter::overlay;
use strict;
use warnings;

use base qw(Pod::Abstract::Filter);
use Pod::Abstract;

=head1 METHODS

=head2 filter

Causes any section within the document inside the named C<heading>, to
be replaced by the equivalant section within the specified C<file>.

=cut

sub filter {
    my $self = shift;
    my $pa = shift;
    
    my $file = $self->param('file');
    my $section = $self->param('heading');
    $section = 'METHODS' unless $section;
    
    die "overlay requires -file\n"
        unless($file);
    
    my $over = Pod::Abstract->load_file($file);
    my ($target) = $pa->select("//[\@heading =~ {$section}](0)");
    my ($overlay) = $over->select("//[\@heading =~ {$section}](0)");
    
    my @t_headings = $target->select("/[\@heading]");
    my @o_headings = $overlay->select("/[\@heading]");
    
    my %t_heading = map { $_->param('heading')->pod => $_ } @t_headings;
    foreach my $hdg (@o_headings) {
        my $hdg_text = $hdg->param('heading')->pod;
        if($t_heading{$hdg_text}) {
            $hdg->detach;
            $hdg->insert_after($t_heading{$hdg_text});
            $t_heading{$hdg_text}->detach;
        } else {
            $target->push($hdg);
        }
    }

    return $pa;
}

=head1 AUTHOR

Ben Lilburne <bnej@mac.com>

=head1 COPYRIGHT AND LICENSE

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
