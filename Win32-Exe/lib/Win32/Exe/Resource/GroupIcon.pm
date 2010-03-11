package Win32::Exe::Resource::GroupIcon;

use strict;
use base 'Win32::Exe::Resource';
use constant FORMAT => (
    Magic		=> 'a2',
    Type		=> 'v',
    Count		=> 'v',
    'Resource::Icon'    => [ 'a14', '{$Count}', 1 ],
);
use constant DEFAULT_ARGS => (
    Magic   => "\0\0",
    Type    => 1,
    Count   => 0,
);
use constant DELEGATE_SUBS => (
    'IconFile'	=> [ 'dump_iconfile', 'write_iconfile' ],
);

our $VERSION = '0.11_01';
$VERSION =~ s/_//ms;

sub icons {
    my $self = shift;
    $self->members(@_);
}

sub set_icons {
    my ($self, $icons) = @_;

    $self->SetCount(scalar @$icons);
    $self->set_members('Resource::Icon' => $icons);

    my $rsrc = $self->first_parent('Resources') or return;

    foreach my $idx (0 .. $#{$icons}) {
	my $icon = $self->icons->[$idx];
	$icon->SetId($idx+1);
	$rsrc->insert($self->icon_name($icon->Id), $icons->[$idx]);
    }
}

sub substr {
    my ($self, $id) = @_;
    my $section = $self->first_parent('Resources');
    return $section->res_data($self->icon_name($id));
}

sub icon_name {
    my ($self, $id) = @_;
    my @icon_name = split("/", $self->PathName, -1);
    $icon_name[1] = "#RT_ICON";
    $icon_name[2] = "#$id";
    return join("/", @icon_name);
}

1;
