
package LacunaWaX::Dialog::About {
    use Moose;
    use Try::Tiny;
    use Wx qw(:everything);
    with 'LacunaWaX::Roles::GuiElement';

    has 'info'  => (is => 'rw', isa => 'Wx::AboutDialogInfo');

    has 'developers' => (
        is          => 'ro',
        isa         => 'ArrayRef[Str]',
        traits      => ['Array'],
        lazy_build  => 1,
        handles     => {
            devs        => 'elements',
            count_devs  => 'count',
        },
    );

    sub BUILD {
        my $self = shift;

        $self->info( Wx::AboutDialogInfo->new() );
        $self->info->SetName( wxTheApp->GetAppName );

        my $maj = wxMAJOR_VERSION;
        my $min = wxMINOR_VERSION;
        ### These are documented, but don't work under wxperl
        #my $rel = wxRELEASE_NUMBER;
        #my $sub = wxSUBRELEASE_NUMBER;

        my $wxwidgets_version = join '.', ($maj, $min);

        $self->info->SetVersion(
            "$LacunaWaX::VERSION - wxPerl $Wx::VERSION (wxwidgets version $wxwidgets_version)"
        );

        $self->info->SetCopyright(
            'Copyright 2012, 2013 Jonathan D. Barton'
        );
        $self->info->SetDescription(
            'A GUI for helping manage The Lacuna Expanse.'
        );
        ### Full license in ROOT/LICENSE
        $self->info->SetLicense(
            'This is free software; you can redistribute it and/or modify it under
            the same terms as the Perl 5 programming language system itself.'
        );
        for my $d( $self->devs ) {
            $self->info->AddDeveloper($d);
        }

        return $self;
    }
    sub _build_developers {#{{{
        my $self = shift;

        return [
            'Jonathan D. Barton (tmtowtdi@gmail.com)',
            'Nathan McCalllum',
            'Swamp Thing',
        ];
    }#}}}
    sub _set_events { }

    sub show {#{{{
        my $self = shift;
        Wx::AboutBox($self->info);
        return;
    }#}}}


    no Moose;
    __PACKAGE__->meta->make_immutable;
}

1;
