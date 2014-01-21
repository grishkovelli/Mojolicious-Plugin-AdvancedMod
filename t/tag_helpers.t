use Mojo::Base -strict;

use Test::More;
use Test::Mojo;
use Mojolicious::Lite;

my $t = Test::Mojo->new;

plugin 'AdvancedMod';

get 'botton';

# bootom_to
diag("Tag: botton_to");
my $botton_to = $t->get_ok('/botton')->tx->res->dom;
is $botton_to->at('form')->attr('action'), '/api', 'action';
is $botton_to->at('form')->attr('method'), 'post', 'method';
is $botton_to->at('form')->attr('class'), 'foo bar', 'class';
is $botton_to->tree->[1][3][1][4][2]{name}, 'user', 'user field name';
is $botton_to->tree->[1][3][1][4][2]{value}, 'root', 'user field value';
is $botton_to->tree->[1][3][1][5][2]{name}, 'password', 'password field name';
is $botton_to->tree->[1][3][1][5][2]{value}, 'q1w2e3', 'password field value';
is $botton_to->tree->[1][3][1][6][2]{type}, 'submit', 'submit type';
is $botton_to->tree->[1][3][1][6][2]{value}, 'GoGo', 'submit value';
is $botton_to->tree->[1][3][1][6][2]{class}, 'btn', 'submit class';

done_testing();

__DATA__
@@ botton.html.ep
%== botton_to 'GoGo', action => '/api', class => 'foo bar', data => [qw/user root password q1w2e3/], submit_class => 'btn'


