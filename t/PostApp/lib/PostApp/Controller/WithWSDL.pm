package PostApp::Controller::WithWSDL;

use strict;
use warnings;
use base 'Catalyst::Controller::SOAP';

__PACKAGE__->config->{wsdl} = 't/hello.wsdl';

sub Greet : Local SOAP('DocumentLiteral') {
    my ( $self, $c, $args ) = @_;
    my $who = $args->{parameters}{who};
    my $grt = $args->{parameters}{greeting};
    $c->stash->{soap}->compile_return({ details => { greeting => $grt.' '.$who.'!' }});
}

1;
