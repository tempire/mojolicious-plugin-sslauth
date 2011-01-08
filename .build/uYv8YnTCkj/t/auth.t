use Mojo::IOLoop;
use Test::More;
use Test::Mojo;
use Data::Dumper;

# Make sure sockets are working
plan skip_all => 'working sockets required for this test!'
  unless Mojo::IOLoop->new->generate_port;    # Test server

#plan tests => 1;


# Lite app
use Mojolicious::Lite;

# Silence
app->log->level('error');

plugin 'ssl_auth';

get '/' => sub {
    my $self = shift;

    return $self->render_text('ok')
      if $self->ssl_auth(
        sub { return 1 if shift->peer_certificate('cn') eq 'client' });

    return $self->render(text => '', status => 401);
};

my $loop   = Mojo::IOLoop->singleton;
my $server = Mojo::Server::Daemon->new(app => app, ioloop => $loop);
my $port   = Mojo::IOLoop->generate_port;
my $client;
my $error;
$server->listen(
    [       "https://localhost:$port"
          . ':t/certs/server/server.crt'
          . ':t/certs/server/server.key'
          . ':t/certs/ca/ca.crt'
    ]
);
$server->prepare_ioloop;

# Success - accepted common name
$loop->connect(
    address    => 'localhost',
    port       => $port,
    tls        => 1,
    tls_cert   => 't/certs/client/client.crt',
    tls_key    => 't/certs/client/client.key',
    on_connect => sub {
        shift->write(shift, "GET / HTTP/1.1\r\n\r\n");
    },
    on_read => sub { $client = pop },
);
$loop->timer(1 => sub { shift->stop });
$loop->start;

like $client, qr/\nok$/, 'common name accepted';

# Failure - different common name
$client = '';
$loop->connect(
    address    => 'localhost',
    port       => $port,
    tls        => 1,
    tls_cert   => 't/certs/anotherclient/anotherclient.crt',
    tls_key    => 't/certs/anotherclient/anotherclient.key',
    on_connect => sub {
        shift->write(shift, "GET / HTTP/1.1\r\n\r\n");
    },
    on_read => sub { $client = pop }
);
$loop->timer(1 => sub { shift->stop });
$loop->start;
like $client, qr/401 Unauthorized/, 'different common name';

done_testing;
