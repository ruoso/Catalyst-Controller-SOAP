{ package Catalyst::Action::SOAP::DocumentLiteral;

  use base qw/Catalyst::Action::SOAP/;
  use constant NS_SOAP_ENV => "http://www.w3.org/2003/05/soap-envelope";

  sub execute {
      my $self = shift;
      my ( $controller, $c ) = @_;
      $self->prepare_soap_helper($c);
      $self->prepare_soap_xml_post($c);
      unless ($c->stash->{soap}->fault) {
          my $envelope = $c->stash->{soap}->parsed_envelope;
          my ($body) = $envelope->getElementsByTagNameNS(NS_SOAP_ENV, 'Body');
          $self->NEXT::execute($controller, $c, $body);
      }
  }
};

1;

__END__

=head1 NAME

Catalyst::Action::SOAP::DocumentLiteral - Document Literal service

=head1 SYNOPSIS

  # not used directly.

=head1 DESCRIPTION

This action implements a simple parse of the envelope and passing the
body to the service as a xml object.

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

