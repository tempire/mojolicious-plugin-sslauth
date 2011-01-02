use Mojo::IOLoop;
use Test::More;
use Test::Mojo;
use Data::Dumper;

# Make sure sockets are working
plan skip_all => 'working sockets required for this test!'
  unless Mojo::IOLoop->new->generate_port;    # Test server


# Lite app
use Mojolicious::Lite;

# Silence
app->log->level('error');

plugin 'ssl_auth';

get '/success' => sub {
    my $self = shift;

    return $self->render_text('ok')
      if $self->ssl_auth(sub { return 1 });

    #return 1 if pop->peer_certificate('cn') eq 'client'; } );
};

my $client = Mojo::Client->new;
my $loop   = $client->ioloop;
my $server = Mojo::Server::Daemon->new(app => app, ioloop => $loop);
my $port   = Mojo::IOLoop->generate_port;
$server->listen(
    [       "https://localhost:$port"
          . ':t/certs/server/server.crt'
          . ':t/certs/server/server.key'
          . ':t/certs/ca/ca.crt'
    ]
);
$server->prepare_ioloop;

#warn Dumper $client->get("https://localhost:$port/success/")->res;
$loop->connect(
    address    => 'localhost',
    port       => $port,
    tls        => 1,
    tls_cert   => 't/certs/client/client.crt',
    tls_key    => 't/certs/client/client.key',
    on_connect => sub {
        shift->write(shift, "GET /success HTTP/1.1\r\n\r\n");
    },
    on_read => sub { warn pop },
);
$loop->timer(1 => sub { shift->stop });
$loop->start;

done_testing;
