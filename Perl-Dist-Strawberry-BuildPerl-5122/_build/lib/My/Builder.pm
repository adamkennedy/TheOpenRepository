package My::Builder;
use Module::Build;
@ISA = qw(Module::Build);
sub ACTION_authortest {
    my ($self) = @_;

    $self->depends_on('build');

    $self->test_files( qw( t xt/author ) );
    $self->depends_on('test');

    return;
}



sub ACTION_releasetest {
    my ($self) = @_;

    $self->depends_on('build');

    $self->test_files( qw( t xt/author xt/release ) );
    $self->depends_on('test');

    return;
}



sub ACTION_manifest {
    my ($self, @arguments) = @_;

    if (-e 'MANIFEST') {
        unlink 'MANIFEST' or die "Can't unlink MANIFEST: $!";
    }

    return $self->SUPER::ACTION_manifest(@arguments);
}

sub ACTION_distmeta {
    my ($self) = @_;
	
    $self->depends_on('manifest');
	
    return $self->SUPER::ACTION_distmeta();
}

1;
