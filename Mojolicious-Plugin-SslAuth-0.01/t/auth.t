use Mojo::IOLoop;
use Test::More;
use Test::Mojo;

# Make sure sockets are working
plan skip_all => 'working sockets required for this test!'
  unless Mojo::IOLoop->new->generate_port;    # Test server

plan tests => 6;

# Lite app
use Mojolicious::Lite;

# Silence
app->log->level('error');

plugin 'ssl_auth';

get '/' => sub {
    my $self = shift;

    return $self->render_text('ok')
      if $self->ssl_auth(
        sub {
            return 1 if shift->peer_certificate('cn') eq 'client';
        }
      );

    $self->render(text => '', status => 401);
};

my $loop   = Mojo::IOLoop->singleton;
my $server = Mojo::Server::Daemon->new(app => app, ioloop => $loop);
my $port   = Mojo::IOLoop->generate_port;
$server->listen(
    [       "https://localhost:$port"
          . ':t/certs/server.crt'
          . ':t/certs/server.key'
          . ':t/certs/ca.crt'
    ]
);
$server->prepare_ioloop;

# Success - expected common name
my $client = Mojo::Client->new(
    ioloop => $loop,
    cert   => 't/certs/client.crt',
    key    => 't/certs/client.key'
);
my $t = Test::Mojo->new(app => app, client => $client);
$t->get_ok("https://localhost:$port")->status_is(200)->content_is('ok');

# Fail - different common name
$t->client(
    Mojo::Client->new(
        ioloop => $loop,
        cert   => 't/certs/anotherclient.crt',
        key    => 't/certs/anotherclient.key'
    )
);
$t->get_ok("https://localhost:$port")->status_is(401)->content_is('');
