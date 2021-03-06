# ============================================================================
package CatalystX::I18N;
# ============================================================================

use Moose;

use version;
our $VERSION = version->new('1.04');
our $AUTHORITY = 'cpan:MAROS';

1;

=encoding utf8

=head1 NAME

CatalystX::I18N - Catalyst internationalisation (I18N) framework

=head1 SYNOPSIS

 package MyApp::Catalyst;
 use strict;
 use warnings;
 use Catalyst qw/
     +CatalystX::I18N::Role::Base
     +CatalystX::I18N::Role::GetLocale
     +CatalystX::I18N::Role::DateTime
     +CatalystX::I18N::Role::Maketext
 /; # Choose only the roles you need
 
 # Optionally also load request and response roles
 use CatalystX::RoleApplicator;
 __PACKAGE__->apply_request_class_roles(qw/CatalystX::I18N::TraitFor::Request/);
 __PACKAGE__->apply_response_class_roles(qw/CatalystX::I18N::TraitFor::Response/);
 
 # Add some I18N configuration
 __PACKAGE__->config( 
     name    => 'MyApp', 
     I18N    => {
         default_locale     => 'de_AT',
         locales            => {
             'de'               => {
                 format_date        => 'dd.MM.yyyy',
                 format_datetime    => 'dd.MM.yyyy HH:mm',
             },
             'de_AT'            => {
                 inherits           => 'de',
                 timezone           => 'Europe/Vienna',
                 format_datetime    => 'dd.MM.yyyy uma HH\'e\'',
             },
             'de_DE'             => {
                 inherits            => 'de',
                 timezone            => 'Europe/Berlin',
             },
         }
     },
 );
 
 
 package MyApp::Catalyst::Controller::Main;
 use strict;
 use warnings;
 use parent qw/Catalyst::Controller/;
 
 sub auto : Private {
     my ($self,$c) = @_;
     $c->get_locale(); 
     # Tries to fetch the locale from the folloing sources in the given order
     # 1. Session
     # 2. User settings
     # 3. Browser settings
     # 4. Client address
     # 5. Default locale from config
 }
 
 sub action : Local {
     my ($self,$c) = @_;
     
     $c->stash->{title} = $c->maketext('Hello world!');
     $c->stash->{location} = $c->i18n_geocode->name;
     $c->stash->{language} = $c->language;
     $c->stash->{localtime} = $c->i18n_datetime_format_date->format_datetime(DateTime->now);
 }

If you want to load all available roles and traits you can use 
L<CatalystX::I18N::Role::All> as a shortcut.

 package MyApp::Catalyst;
 use strict;
 use warnings;
 use Catalyst qw/
     +CatalystX::I18N::Role::All
 /;

=head1 DESCRIPTION

CatalystX::I18N provides a comprehensive toolset for internationalisation 
(I18N) and localisation (L10N) of catalyst applications. This distribution 
consists of several modules that are designed to integrate seamlessly, but
can be run idependently or replaced easily if necessarry.

=over

=item * L<CatalystX::I18N::Role::Base> 

Basic I18N role that glues everything toghether.

=item * L<CatalystX::I18N::Role::Maketext> 

Adds a maketext capability to a Catalyst application.

=item * L<CatalystX::I18N::Role::DateTime>

Methods for localizing date and time informations.

=item * L<CatalystX::I18N::Role::NumberFormat>

Methods for localizing numbers.

=item * L<CatalystX::I18N::TraitFor::Request>

Extends a L<Catalyst::Request> with usefull methods to help dealing with
various I18N related information in HTTP requests.

=item * L<CatalystX::I18N::TraitFor::Response>

Adds a C<Content-Language> header to the response.

=item * L<CatalystX::I18N::Role::GetLocale> 

Tries best to determine the request locale.

=item * L<CatalystX::I18N::Model::L10N>

Provides access to L<Locale::Maketext> classes via Catalyst models.

=item * L<CatalystX::I18N::L10N>

Wrapper arround L<Locale::Maketext>. Can also be used outside of Catalyst.

=back

=head1 CONFIGURATION

In order to work properly, CatalystX::I18N will need find some values in your
Catalyst configuration

 __PACKAGE__->config( 
     name    => 'MyApp', 
     I18N    => {
         default_locale     => 'de_AT',
         locales            => {
             'de'               => {
                 inactive           => 1,
                 # Mark this locale as inactive. 
                 ...
                 # Arbitrary configuration parameters
             },
             'de_AT'            => {
                 inherits           => 'de',
                 # Inherit all settings form locale 'de'
                 ...
             },
         }
     },
 );

The configuration must be stored under the key C<I18N>. It should contain
a hash of C<locales> and optionally a default locale (C<default_locale>).

Locales can be marked as C<inactive>. Inactive locales will not be selected
by the L<CatalystX::I18N::Role::GetLocale/get_locale> method.

Locales can inherit from other locales (C<inherits>). All configuration values
from inherited locales will be copied, and add if you use 
L<CatalystX::I18N::Model::L10N> together with L<CatalystX::I18N::L10N> the
generated lexicons will also inherit in the given order.

Additional configuration values are defined by the various 
CatalystX::I18N::Role::Maketext::* plugins.

=head1 EXTENDING

Extending the functionality of the CatalystX::I18N distribution is easy.

E.g. writing a new plugin that does some processing when the locale changes

 package CatalystX::MyI18N::Plugin;
 use Moose::Role;
 
 after 'set_locale' => sub {
     my ($c,$locale) = @_;
     $c->do_someting($locale);
 };
 
 no Moose::Role;
 1;

=head1 SEE ALSO

L<Locale::Maketext>, <Locale::Maketext::Lexicon>,
L<Number::Format>, L<DateTime::Locale>, L<DateTime::Format::CLDR>, 
L<DateTime::TimeZone>, L<HTTP::BrowserDetect> and L<Locale::Geocode>

=head1 SUPPORT

Please report any bugs or feature requests to 
C<catalystx-i18n@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/Public/Bug/Report.html?Queue=CatalystX::I18N>.
I will be notified and then you'll automatically be notified of the progress 
on your report as I make changes.

=head1 AUTHOR

    Maroš Kollár
    CPAN ID: MAROS
    maros [at] k-1.com
    
    L<http://www.revdev.at>

=head1 COPYRIGHT

CatalystX::I18N is Copyright (c) 2010 Maroš Kollár 
- L<http://www.k-1.com>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut