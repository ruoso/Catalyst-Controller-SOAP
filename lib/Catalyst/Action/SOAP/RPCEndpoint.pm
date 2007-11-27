{ package Catalyst::Action::SOAP::RPCEndpoint;

  use base qw/Catalyst::Action::SOAP/;

  sub execute {
      my $self = shift;
      my ( $controller, $c ) = @_;

      $self->prepare_soap_helper($c);
      $self->prepare_soap_xml_post($c);
      unless ($c->stash->{soap}->fault) {
          my $envelope = $c->stash->{soap}->parsed_envelope;
          my ($body) = $envelope->getElementsByTagName('Body',0);
          my @children = $body->getChildNodes();
          if (scalar @children != 1) {
              $c->stash->{soap}->fault
                ({ code => { 'env:Sender' => 'env:Body' },
                   reason => 'Bad Body', detail =>
                   'RPC messages should contain only one element inside body'})
            } else {
                my $operation = $children[0]->nodeName();
                my $arguments = $children[0]->getChildNodes();
                $c->stash->{soap}->arguments($arguments);
                if (!grep { /RPC(Encoded|Literal)/ } @{$controller->action_for($operation)->attributes->{ActionClass}}) {
                    $c->stash->{soap}->fault
                      ({ code => { 'env:Sender' => 'env:Body' },
                         reason => 'Bad Operation', detail =>
                         'Invalid Operation'})
                } else {
                    # this is our RPC action
                    $c->forward($operation);
                }
            }
      }
  }
};

1;

__END__

=head1 NAME

Catalyst::Action::SOAP::RPCEndpoint - RPC Dispatcher

=head1 SYNOPSIS

  # not used directly.

=head1 DESCRIPTION

This class is used by L<Catalyst::Controller::SOAP> to dispatch to the
RPC operations inside a controller. These operations are quite
different from the others, as they are seen by Catalyst as this single
action. During the registering phase, the soap rpc operations are
included in the hash that is sent to this object, so they can be
invoked later.

=head1 TODO

Almost all the SOAP protocol is unsupported, only the method
dispatching and, optionally, the soap-decoding of the arguments are
made.

=head1 AUTHORS

Daniel Ruoso <daniel.ruoso@verticalone.pt>

=head1 BUG REPORTS

Please submit all bugs regarding C<Catalyst::Controller::SOAP> to
C<bug-catalyst-controller-soap@rt.cpan.org>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

