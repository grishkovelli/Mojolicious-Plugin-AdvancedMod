package Mojolicious::Plugin::AdvancedMod;
use Mojo::Base 'Mojolicious::Plugin';

use Mojolicious::Plugin::AdvancedMod::ActionFilter;
use Mojolicious::Plugin::AdvancedMod::HashedParams;
use Mojolicious::Plugin::AdvancedMod::Configurator;
use Mojolicious::Plugin::AdvancedMod::TagHelpers;

use DBI;

our $VERSION = '0.37';

sub register {
  my ( $plugin, $app, $conf ) = @_;
  my ( $helpers, %only ) = {};

  # Mojolicious::Plugin::AdvancedMod::Authoriz::init( $app, $helpers );
  Mojolicious::Plugin::AdvancedMod::ActionFilter::init( $app, $helpers );
  Mojolicious::Plugin::AdvancedMod::Configurator::init( $app, $helpers );
  Mojolicious::Plugin::AdvancedMod::HashedParams::init( $app, $helpers );
  Mojolicious::Plugin::AdvancedMod::TagHelpers::multi_init( $app, $helpers );

  # add helper's
  if ( $conf->{only} ) {
    %only = map { $_ => 1 } @{ $conf->{only} };
  }

  foreach my $h ( keys %$helpers ) {
    if ( %only && !exists $only{$h} ) {
      delete $helpers->{$h};
      next;
    }
    $app->helper( $h => $helpers->{$h} );
    $app->log->debug( "** AdvancedMod load $h" );
  }

  # by am_config
  if ( $app->defaults( 'am_config' ) ) {
    my $am_cfg = $app->defaults( 'am_config' );

    # add db helper's
    foreach my $k ( keys %$am_cfg ) {
      if ( $k eq 'db' || $k =~ /^db_\w+$/ ) {
        $app->helper(
          $k => sub {
            return DBI->connect( @{ $am_cfg->{$k} }{qw/ dsn user password options /} );
          }
        );
      }
    }

    # change 'secrets' key
    $app->secrets( $am_cfg->{secrets} ) if $am_cfg->{secrets};
  }
}

1;

=encoding utf8

=head1 NAME

Mojolicious::Plugin::AdvancedMod - More buns for Mojolicious

=head1 VERSION

This documentation covers version 0.37 of Mojolicious::Plugin::AdvancedMod* released Jan, 2014

=head1 SYNOPSIS

$self->plugin('AdvancedMod');

=head1 SEE ALSO

=head2 L<Mojolicious::Plugin::AdvancedMod>

Load all AdvancedMod::*. Auto-generation database helpers's if config exist C<db_*> 

=head2 L<Mojolicious::Plugin::AdvancedMod::ActionFilter>

Analogue of Rails: before_filter, after_filter

=head2 L<Mojolicious::Plugin::AdvancedMod::HashedParams>

Transformation request parameters into a hash and multi-hash

=head2 L<Mojolicious::Plugin::AdvancedMod::Configurator>

Load YAML/JSON config, encapsulation, change 'templates_path' && 'static_path' by MOJO_MODE/config. 

=head2 L<Mojolicious::Plugin::AdvancedMod::TagHelpers>

Collection of HTML tag helpers

=head2 L<Mojolicious::Command::am>

Generic Mojolicious app, controllers, models, helpers, views

=head3 Example

=for text

  my_app/
  |__ etc
  |  |__ general.yml
  |
  |__ lib
  |   |__ MyApp
  |      |__ Controllers
  |      |  |__ App.pm
  |      |
  |      |__ Helpers
  |      |  |__ App.pm
  |      | 
  |      |__ Models
  |         |__ App.pm
  |
  |__ public
  |  |__ index.html
  |
  |__ script
  |  |__ my_app
  |
  |__ log
  |
  |__ t
  |  |__ basic.t
  |
  |__ templates
     |__ app
     |  |__ index.html.haml
     |  |__ show.html.haml
     | 
     |__ layouts
        |__ defaults.html.haml

=head1 AUTHOR

=over 2

=item

Grishkovelli L<grishkovelli@gmail.com>

=item

https://github.com/grishkovelli/Mojolicious-Plugin-AdvancedMod

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013, 2014
Grishkovelli L<grishkovelli@gmail.com>

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
