# ============================================================================
package CatalystX::I18N::Model::L10N;
# ============================================================================

use Moose;
extends 'Catalyst::Model';

use CatalystX::I18N::TypeConstraints;
use Path::Class;

has 'class' => (
    is          => 'rw', 
    isa         => 'Str',
);

has 'gettext_style' => (
    is          => 'rw', 
    isa         => 'Bool',
    default     => 1,
);

has 'directories' => (
    is          => 'rw', 
    isa         => 'CatalystX::I18N::Type::DirList',
    coerce      => 1,
    default     => sub { [] },
);

has '_app' => (
    is          => 'rw', 
    isa         => 'Str',
    required    => 1,
);

around BUILDARGS => sub {
    my $orig  = shift;
    my ( $self,$app,$config ) = @_;
    
    if (defined $config->{directories}
        && ref($config->{directories}) ne 'ARRAY') {
        $config->{directories} = [ $config->{directories} ];
    }
    
    # Build default directory path unless configured
    unless (defined $config->{directories}
        && scalar @{$config->{directories}} > 0) {
        my $calldir = $app;
        $calldir =~ s{::}{/}g;
        my $file = "$calldir.pm";
        my $path = $INC{$file};
        $path =~ s{\.pm$}{/L10N};
        $config->{directories} = [ Path::Class::Dir->new($path) ];
    }
    
    # Get L10N class
    $config->{class} ||= $app .'::L10N';
    
    # Set _app class
    $config->{_app} = $app;
    
    # Call original BUILDARGS
    return $self->$orig($app,$config);
};

sub BUILD {
    my ($self) = @_;
    
    my $class = $self->class;

    # Load L10N class
    eval {
        Class::MOP::load_class($class);
        return 1;
    } or Catalyst::Exception->throw(sprintf("Could not load '%s' : %s",$class,$@));
    
    Catalyst::Exception->throw(sprintf("Could initialize '%s' because is is not a 'Locale::Maketext' class",$class))
        unless $class->isa('Locale::Maketext');
    
    my $app = $self->_app;
    
    # Load lexicons in the L10N class if possible
    if ($class->can('load_lexicon')) {
        my (@locales,%inhertiance,$config);
        $config = $app->config->{I18N}{locales};
        foreach my $locale (keys %$config) {
            push(@locales,$locale);
            $inhertiance{$locale} = $config->{$locale}{inherits}
                if defined $config->{$locale}{inherits};
            
        }
        $app->log->debug(sprintf("Loading L10N lexicons for locales %s",join(',',@locales)))
            if $app->debug;
        $class->load_lexicon( 
            locales             => \@locales, 
            directories         => $self->directories,
            gettext_style       => $self->gettext_style,
            inheritance         => \%inhertiance,
        );
    } else {
        $app->log->warn(sprintf("'%s' does not implement a 'load_lexicon' method",$class))
    }
}

sub ACCEPT_CONTEXT {
    my ( $self, $c ) = @_;
    
    # set locale and fallback
    my $handle = $self->class->get_handle( $c->locale );
    
    # Catch error
    Catalyst::Exception->throw(sprintf("Could not fetch lanuage handle for locale '%s'",$c->locale))
        unless ( scalar $handle );
    
    if ($self->can('fail_with')) {
        $handle->fail_with( sub { 
            $self->fail_with($c,@_);
        } );
    } else {
        $handle->fail_with( sub { } );
    }
    
    return $handle;
}

__PACKAGE__->meta->make_immutable( inline_constructor => 0 );
no Moose;
1;

=encoding utf8

=head1 NAME

CatalystX::I18N::Model::L10N - Glues CatalystX::I18N::L10N into Catalyst

=head1 SYNOPSIS

 # In your catalyst base class
 package MyApp::Catalyst;
 use Catalyst qw/CatalystX::I18N::Role::Base/;
 
 __PACKAGE__->config( 
    'Model::L10N' => {
        directory       => '/path/to/l10n/files', # optional
    },
 );
 
 
 # Create a model class
 package MyApp::Model::L10N;
 use parent qw/CatalystX::I18N::Model::L10N/;
 
 
 # Create a L10N class (must be a Locale::Maketext class)
 package MyApp::L10N;
 use parent qw/CatalystX::I18N::L10N/;
 
 
 # In your controller class(es)
 package MyApp::Controller::Main;
 use parent qw/Catalyst::Controller/;
 
 sub action : Local {
     my ($self,$c) = @_;
     
     my $model = $c->model('L10N');
     $c->stash->{title} = $model->maketext('Hello world');
     # See CatalystX::I18N::Role::Maketext for a convinient wrapper
 }

=head1 DESCRIPTION

This model glues a L<CatalystX::I18N::L10N> class (or any other 
L<Locale::Maketext> class) with Catalyst. 

The method C<fail_with> will be called for each missing msgid if present
in your model class. 

 package MyApp::Model::L10N;
 use parent qw/CatalystX::I18N::Model::L10N/;
 
 sub fail_with {
     my ($self,$c,$language_handle,$msgid,$params) = @_;
     # Do somenthing clever
     return $string;
 }

See L<Catalyst::Helper::Model::L10N> for gerating an L10N model from the 
command-line.

=head1 CONFIGURATION

=head3 class

Set the L<Locale::Maketext> class you want to use from this model.

Defaults to $APPNAME::L10N

=head3 gettext_style

Enable gettext style. C<%quant(%1,document,documents)> instead of 
C<[quant,_1,document,documents]>

Default TRUE

=head3 directory

List of directories to be searched for L10N files.

See L<CatalystX::I18N::L10N> for more details on the C<directory> parameter

=head1 SEE ALSO

L<CatalystX::I18N::L10N>, L<Locale::Maketext>, L<Locale::Maketext::Lexicon>
and L<CatalystX::I18N::Role::Maketext>

=head1 AUTHOR

    Maroš Kollár
    CPAN ID: MAROS
    maros [at] k-1.com
    
    L<http://www.revdev.at>