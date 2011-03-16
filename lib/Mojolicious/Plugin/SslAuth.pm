package Mojolicious::Plugin::SslAuth;

use strict;
use warnings;
use Mojo::IOLoop;

our $VERSION = '0.03';

use base 'Mojolicious::Plugin';

sub register {
    my ( $plugin, $app ) = @_;

    $app->helper(
        ssl_auth => sub {
            my $self     = shift;
            my $callback = shift;

            my $id     = $self->tx->connection;
            my $handle = Mojo::IOLoop->singleton->handle($id);

            # Not SSL connection
            return if ref $handle ne 'IO::Socket::SSL';

            return $callback->($handle);
        }
    );
}

1;
__END__

=head1 NAME

Mojolicious::Plugin::SslAuth - SSL client certificate auth helper

=head1 DESCRIPTION

L<Mojolicous::Plugin::SslAuth> is a helper for authenticating client ssl certificates against CA's (certificate authorities)

=head1 USAGE

    use Mojolicious::Lite;

    plugin 'ssl_auth';

    get '/' => sub {
        my $self = shift;

        return $self->render_text('ok')
          if $self->ssl_auth(
            sub {
                return 1 if shift->peer_certificate('commonName') eq 'client';
            }
          );
    };

    app->start;

L<IO::Socket::SSL> connection passed as parameter.

See L<IO::Socket::SSL> for available methods. (You're most likely looking for ->peer_certificate and/or ->get_cipher)

=head1 METHODS

L<Mojolicious::Plugin::SslAuth> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 C<register>

    $plugin->register;

Register condition in L<Mojolicious> application.

=head1 SEE ALSO

L<Mojolicious>

=head1 DEVELOPMENT

L<http://github.com/tempire/mojolicious-plugin-sslauth>

=head1 VERSION

0.03

=head1 AUTHOR

Glen Hinkle tempire@cpan.org

=cut
