{ package Catalyst::Action::SOAP;

  use base qw/Catalyst::Action/;
  use XML::LibXML;

  __PACKAGE__->mk_accessors(qw/xml_parser/);

  sub new {
      my $class = shift;
      my $self = $class->SUPER::new(@_);
      $self->xml_parser(XML::LibXML->new());
      return $self;
  }

  sub prepare_soap_helper {
      my ($self, $c) = @_;
      $c->stash->{soap} = Catalyst::Controller::SOAP::Helper->new();
  }

  sub prepare_soap_xml_post {
      my ($self, $c) = @_;
      if ($c->req->content_type =~ /application\/soap\+xml/ &&
          $c->req->method eq 'POST') {
          my $body = $c->req->body;
          my $xml_str = join '', <$body>;
          eval {
              $c->stash->{soap}->envelope($xml_str);
              $c->stash->{soap}->parsed_envelope($self->xml_parser->parse_string($xml_str));
          };
          if ($@) {
              $c->stash->{soap}->fault({ code => 'env:Sender', reason => 'Bad XML Message', detail => $@});
          }
      } else {
          $c->stash->{soap}->fault({ code => 'env:Sender', reason => 'Bad content-type/method'});
      }
  }
};

1;

__END__

=head1 NAME

Catalyst::Action::SOAP - Action superclass

=head1 SYNOPSIS

  # not used directly.

=head1 DESCRIPTION

This is the superclass used by the Document and the RPC actions.

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

