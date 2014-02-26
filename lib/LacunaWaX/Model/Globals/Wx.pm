
package LacunaWaX::Model::Globals::Wx {
    use v5.14;
    use Archive::Zip;
    use Archive::Zip::MemberRead;
    use Carp;
    use CHI;
    use English qw( -no_match_vars );
    use Moose;
    use Path::Tiny;
    use Wx qw(:everything);

    has 'globals' => (
        is          => 'rw', 
        isa         => 'LacunaWaX::Model::Globals',
        required    => 1,
    );

    ##########################################

    has 'cache' => (
        is          => 'rw', 
        isa         => 'Object',
        lazy_build  => 1,
    );

    has 'fonts' => (
        is          => 'ro', 
        isa         => 'HashRef',
        default     => sub{ {} },
        traits      => [ 'Hash' ],
        handles     => {
            get_font    => 'get',
            has_font    => 'defined',
            num_fonts   => 'count',
            set_font    => 'set',
        }
    );

    has 'images' => (
        is          => 'ro', 
        isa         => 'HashRef',
        default     => sub{ {} },
        traits      => [ 'Hash' ],
        handles     => {
            del_image   => 'delete',
            get_image   => 'get',
            has_image   => 'defined',
            num_images  => 'count',
            set_image   => 'set',
        }
    );

    has 'zip_file' => (
        is          => 'rw', 
        isa         => 'Path::Tiny',
        lazy_build  => 1,
    );

    has 'zip' => (
        is          => 'rw', 
        isa         => 'Archive::Zip',
        lazy_build  => 1,
    );

    sub BUILD {
        my $self = shift;

        $self->cache_fonts;
        $self->cache_images;

        return $self;
    }

    sub _build_cache {#{{{
        my $self = shift;

        my $chi = CHI->new(
            driver              => 'RawMemory',
            expires_variance    => 0.25,
            global              => 1,
        );

        return $chi;
    }#}}}
    sub _build_zip {#{{{
        my $self = shift;
        my $arg  = shift;

        my $zip = Archive::Zip->new( $self->zip_file->stringify );
        return $zip;
    }#}}}
    sub _build_zip_file {#{{{
        my $self = shift;
        my $arg  = shift;

        my $z = $self->globals->dir_user->child('assets.zip');
        return $z;
    }#}}}

    sub cache_fonts {#{{{
        my $self = shift;

        ### para_text and modern_text fontsizes increase as number increases 
        ### (4 is bigger than 1).
        ###
        ### header fontsize _decreases_ as number increases (1 is bigger than 
        ### 4, as in html).

        ### Swiss is variable-width sans-serif (arial).
        $self->set_font('para_text_1',          Wx::Font->new(8,  wxSWISS, wxNORMAL, wxNORMAL, 0)   );
        $self->set_font('para_text_2',          Wx::Font->new(10, wxSWISS, wxNORMAL, wxNORMAL, 0)   );
        $self->set_font('para_text_3',          Wx::Font->new(12, wxSWISS, wxNORMAL, wxNORMAL, 0)   );
        $self->set_font('bold_para_text_1',     Wx::Font->new(8,  wxSWISS, wxNORMAL, wxBOLD, 0)     );
        $self->set_font('bold_para_text_2',     Wx::Font->new(10, wxSWISS, wxNORMAL, wxBOLD, 0)     );
        $self->set_font('bold_para_text_3',     Wx::Font->new(12, wxSWISS, wxNORMAL, wxBOLD, 0)     );

        ### Modern is fixed-width.
        $self->set_font('modern_text_1',        Wx::Font->new(8,  wxMODERN, wxNORMAL, wxNORMAL, 0)  );
        $self->set_font('modern_text_2',        Wx::Font->new(10, wxMODERN, wxNORMAL, wxNORMAL, 0)  );
        $self->set_font('modern_text_3',        Wx::Font->new(12, wxMODERN, wxNORMAL, wxNORMAL, 0)  );
        $self->set_font('bold_modern_text_1',   Wx::Font->new(8,  wxMODERN, wxNORMAL, wxBOLD, 0)    );
        $self->set_font('bold_modern_text_2',   Wx::Font->new(10, wxMODERN, wxNORMAL, wxBOLD, 0)    );
        $self->set_font('bold_modern_text_3',   Wx::Font->new(12, wxMODERN, wxNORMAL, wxBOLD, 0)    );

        ### Header isn't really a font type.  Just large, bold SWISS.
        $self->set_font('header_1',     Wx::Font->new(22, wxSWISS, wxNORMAL, wxBOLD, 0) );
        $self->set_font('header_2',     Wx::Font->new(20, wxSWISS, wxNORMAL, wxBOLD, 0) );
        $self->set_font('header_3',     Wx::Font->new(18, wxSWISS, wxNORMAL, wxBOLD, 0) );
        $self->set_font('header_4',     Wx::Font->new(16, wxSWISS, wxNORMAL, wxBOLD, 0) );
        $self->set_font('header_5',     Wx::Font->new(14, wxSWISS, wxNORMAL, wxBOLD, 0) );
        $self->set_font('header_6',     Wx::Font->new(12, wxSWISS, wxNORMAL, wxBOLD, 0) );
        $self->set_font('header_7',     Wx::Font->new(10, wxSWISS, wxNORMAL, wxBOLD, 0) );

    }#}}}
    sub cache_images {#{{{
        my $self = shift;

        ### Read .png files from the assets zip file.  Only gets images in
        ###     /images/SOMEDIR/filename.png
        ###
        ### You can arbitrarily add more SOMEDIRs as you like, but each must 
        ### contain only images.  Adding SOMEDIR/ANOTHERDIR/imagename.png will 
        ### not work.

        my %dirs = ();

        ### Enumerate the image files
        foreach my $member( $self->zip->membersMatching("images/.*\.png\$") ) {
            $member->fileName =~ m{images/([^/]+)/};
            my $dirname = $1;
            push @{$dirs{$dirname}}, $member;
        }

        foreach my $dir( keys %dirs ) {
            foreach my $image_member(@{ $dirs{$dir} }) {
                $image_member->fileName =~ m{images/$dir/(.+)$};
                my $image_filename = $1; # just the image name, eg 'beryl.png'

                ### Read just this file, turn it into a Wx::Image
                my $zfh = Archive::Zip::MemberRead->new(
                    $self->zip,
                    $image_member->fileName,
                );

                my $binary;
                while(1) {
                    my $buffer = q{};
                    my $read = $zfh->read($buffer, 1024);
                    $binary .= $buffer;
                    last unless $read;
                }

                open my $sfh, '<', \$binary or croak "Unable to open stream: $ERRNO";
                my $img = Wx::Image->new($sfh, wxBITMAP_TYPE_PNG);
                close $sfh or croak "Unable to close stream: $ERRNO";
                $self->set_image( "$dir/$image_filename", $img );
            }
        }

        return 1;
    }#}}}

    no Moose;
    __PACKAGE__->meta->make_immutable; 
}

1;

__END__

=head1 NAME

LacunaWaX::Model::Globals::Wx - Application global settings that require Wx

=head1 SYNOPSIS

 $g = LacunaWaX::Model::Globals->new( root_dir => '/path/to/root' );
 $w = LacunaWaX::Model::Globals::Wx->new( globals => $g );

 $chalc_image = $w->get_image( 'glyphs/chalcopyrite.png' );
 $chalc_img->Rescale('50', '50');
 $bmp = Wx::Bitmap->new($chalc_img);

 $cache = $w->cache;    # CHI RawMemory cache

=head1 DESCRIPTION

Contains application-global settings, much like LacunaWaX::Model::Globals 
does.  But LacunaWaX::Model::Globals contains nothing that touches Wx, so can 
be used in non-GUI programs (eg scheduled programs meant to run in the 
background).

