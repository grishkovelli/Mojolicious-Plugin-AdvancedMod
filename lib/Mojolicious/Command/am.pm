package Mojolicious::Command::am;
use Mojo::Base 'Mojolicious::Command';
use Mojo::Util qw(class_to_file class_to_path);
use Data::Dumper;

our $VERSION = 0.01;

###############################################################

has description => "AdvancedMod alias.\n";
has usage       => <<USAGE;

Usage: $0 COMMAND OPTION [ARGS]

  Commands:
    n - create new application
    g - generic
    d - delete

  Options:
    controller
    model
    resource

  Arguments:
    handler
    plugins
    actions

  Examples:
    # create new application
    mojo am new App
    mojo am new App actions:new,create,update plugins:haml_renderer,dbi
    # generic new controller
    mojo am g controller Main
    # generic controller, model and view's
    mojo am g resource UserStat actions:index,new

USAGE

###############################################################

my @actions = qw/ index show edit new create update destroy /;

###############################################################

sub run {
  my $self = shift;
  my $cmd  = shift;

  return unless $cmd;

  if ( $cmd eq 'n' ) {
    $self->new_app( @_ );
  }
  elsif ( $cmd eq 'g' ) {
    my $op = shift || '';

    if ( $op eq 'controller' ) {
      $self->new_controller( @_ );
    }
    elsif ( $op eq 'model' ) {
      $self->new_model( @_ );
    }
    elsif ( $op eq 'resource' ) {
      $self->new_resource( @_ );
    }
    else {
      die "Usage: am g [controller|model|resource]";
    }
  }
}

sub new_controller {
  my $self  = shift;
  my $name  = shift;
  my %opts  = _cmd_opts_parsing( \@_ );
  my $class = $self->app->routes->namespaces->[0];

  $opts{handler} ||= $self->app->renderer->default_handler;
  $opts{actions} ||= \@actions;

  # controller
  my $controller = "${class}::Controllers::$name";
  $self->render_to_rel_file(
    'controller',
    "lib/" . ( class_to_path $controller ),
    { class   => $controller,
      actions => $opts{actions}
    }
  );

  # helper
  my $helper = "${class}::Helpers::$name";
  $self->render_to_rel_file( 'helper', "lib/" . ( class_to_path $helper ), $helper );

  # view's by actions
  foreach my $action ( @{ $opts{actions} } ) {
    next if $action =~ /(create|update|destroy)/;
    $self->write_rel_file( "templates/$name/$action.html.$opts{handler}", "It's action #$action" );
  }
}

sub new_model {
  my $self  = shift;
  my %opts  = _cmd_opts_parsing( \@_ );
  my $class = $self->app->routes->namespaces->[0];

  foreach my $name ( @_ ) {
    my $model = "${class}::Models::$name";
    $self->render_to_rel_file( 'model', "lib/" . ( class_to_path $model ), $model );
  }
}

sub new_resource {
  my $self    = shift;
  my %opts    = _cmd_opts_parsing( \@_ );
  my $class   = $self->app->routes->namespaces->[0];
  my $handler = $self->app->renderer->default_handler;

  $opts{actions} ||= \@actions;

  foreach my $name ( @_ ) {
    # Controller
    my $controller = "${class}::Controllers::$name";
    $self->render_to_rel_file(
      'controller',
      "lib/" . ( class_to_path $controller ),
      { class   => $controller,
        actions => \@actions
      }
    );

    # Model
    my $model = "${class}::Models::$name";
    $self->render_to_rel_file( 'model', "lib/" . ( class_to_path $model ), $model );

    # Helper
    my $helper = "${class}::Helpers::$name";
    $self->render_to_rel_file( 'helper', "lib/" . ( class_to_path $helper ), $helper );

    # View's
    foreach my $action ( @{ $opts{actions} } ) {
      next if $action =~ /(create|update|destroy)/;
      $self->write_rel_file( "templates/$name/$action.html.$handler", "It's action #$action" );
    }
  }
}

sub new_app {
  my $self  = shift;
  my $class = shift || 'TestApp';
  my %opts  = _cmd_opts_parsing( \@_ );

  # ARGS list: handler, actions, plugins
  $opts{handler} ||= 'haml';
  $opts{actions} ||= \@actions;
  push @{ $opts{plugins} }, 'haml_renderer' if $opts{handler} eq 'haml';

  # Prevent bad applications
  die <<EOF unless $class =~ /^[A-Z](?:\w|::)+$/;
Your application name has to be a well formed (CamelCase) Perl module name
like "TestApp".
EOF

  # Script
  my $name = class_to_file $class;
  $self->render_to_rel_file( 'mojo', "$name/script/$name", $class );
  $self->chmod_file( "$name/script/$name", 0744 );

  # Application class
  my $app = class_to_path $class;
  $self->render_to_rel_file(
    'appclass',
    "$name/lib/$app",
    { class   => $class,
      plugins => $opts{plugins},
      handler => $opts{handler}
    }
  );

  # Controller
  my $controller = "${class}::Controllers::App";
  $self->render_to_rel_file(
    'controller',
    "$name/lib/" . ( class_to_path $controller ),
    { class   => $controller,
      actions => $opts{actions}
    }
  );

  # Model
  my $model = "${class}::Models::App";
  $self->render_to_rel_file( 'model', "$name/lib/" . ( class_to_path $model ), $model );

  # Helper
  my $helper = "${class}::Helpers::App";
  $self->render_to_rel_file( 'helper', "$name/lib/" . ( class_to_path $helper ), $helper );

  # View's
  foreach my $action ( @{ $opts{actions} } ) {
    next if $action =~ /(create|update|destroy)/;
    $self->write_rel_file( "$name/templates/app/$action.html.$opts{handler}", "It's action #$action" );
  }

  # Test
  $self->render_to_rel_file( 'test', "$name/t/basic.t", $class );

  # Directory's
  foreach my $dir ( qw/ log css images fonts js / ) {
    my $path = $dir eq 'log' ? "$name/$dir" : "$name/public/$dir";
    $self->create_rel_dir( $path );
  }

  # Static
  $self->render_to_rel_file( 'static', "$name/public/index.html" );

  # Templates
  $self->render_to_rel_file( 'layout', "$name/templates/layouts/default.html.$opts{handler}" );
}

sub _cmd_opts_parsing {
  my ( $args, %opts ) = shift;

  for ( my $i = 0; $i <= $#$args; $i++ ) {
    next unless $args->[$i] =~ /^\w+:/;
    my ( $k, $v ) = split /:/, $args->[$i];

    $opts{$k} = $k eq 'handler' ? $v : [ split /,/, $v ];
    splice @$args, $i, 1;
  }

  return %opts;
}

1;

__DATA__

@@ mojo
% my $class = shift;
#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
BEGIN { unshift @INC, "$FindBin::Bin/../lib" }

require Mojolicious::Commands;
Mojolicious::Commands->start_app('<%= $class %>');

@@ appclass
% my $h = shift;
package <%= $h->{class} %>;
use Mojo::Base 'Mojolicious';

sub startup {
  my $self = shift;

  % if( $h->{plugins} ) {
      % foreach my $p ( @{ $h->{plugins} } ) {
  $self->plugin('<%= $p %>');
      % }
  % }

  $self->app->renderer->default_handler( '<%= $h->{handler} %>' );

  my $r = $self->routes;

  $r->get('/')->to('app#index');
}

1;

@@ controller
% my $h = shift;
package <%= $h->{class} %>;
use Mojo::Base 'Mojolicious::Controller';

% foreach my $action ( @{ $h->{actions} } ) {
sub <%= $action %> {
  my $self = shift;
  $self->render( '<%= $action %>' );
}

% }

1;

@@ model
% my $class = shift;
package <%= $class %>;

1;

@@ helper
% my $class = shift;
package <%= $class %>;
use Mojo::Base 'Mojolicious::Plugin';

sub register {
  my ( $plugin, $app, $conf ) = @_;

}

1;

@@ static
<!DOCTYPE html>
<html>
  <head>
    <title>Welcome to the Mojolicious real-time web framework!</title>
  </head>
  <body>
    <h2>Welcome to the Mojolicious real-time web framework!</h2>
    This is the static document "public/index.html",
    <a href="/">click here</a> to get back to the start.
  </body>
</html>

@@ test
% my $class = shift;
use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

my $t = Test::Mojo->new('<%= $class %>');
$t->get_ok('/')->status_is(200)->content_like(qr/Mojolicious/i);

done_testing();
