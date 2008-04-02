use Test::More tests => 8;
use File::Spec::Functions;
use HTTP::Response;
use IPC::Open3;
use Symbol;

my $response;

$response = soap_xml_post
  ('/ws/hello',
   '<Envelope xmlns="http://schemas.xmlsoap.org/soap/envelope/"><Body>World</Body></Envelope>'
  );

ok($response->content =~ /Hello World/, 'Document Literal correct response: '.$response->content);

$response = soap_xml_post
  ('/ws2',
   '<Envelope xmlns="http://schemas.xmlsoap.org/soap/envelope/"><Body><hello>World</hello></Body></Envelope>'
  );
ok($response->content =~ /Hello World/, 'RPC Literal Correct response: '.$response->content);

$response = soap_xml_post
  ('/ws/foo',
   '<Envelope xmlns="http://schemas.xmlsoap.org/soap/envelope/"><Body>World</Body></Envelope>'
  );
ok($response->content =~ /\<foo\>\<bar\>\<baz\>Hello World\!\<\/baz\>\<\/bar\>\<\/foo\>/, 'Literal response: '.$response->content);

$response = soap_xml_post
  ('/withwsdl/Greet',
   '<Envelope xmlns="http://schemas.xmlsoap.org/soap/envelope/"><Body><GreetingSpecifier><who>World</who><greeting>Hello</greeting></GreetingSpecifier></Body></Envelope>'
  );
ok($response->content =~ /greeting\>Hello World\!\<\//, 'Literal response: '.$response->content);

$response = soap_xml_post
  ('/withwsdl2/Greet','
    <Envelope xmlns="http://schemas.xmlsoap.org/soap/envelope/">
         <Body>
            <Greet>
               <who>World</who>
               <greeting>Hello</greeting>
            </Greet>
         </Body>
    </Envelope>
  ');
ok($response->content =~ /greeting[^>]+\>Hello World\!\<\//, 'Literal response: '.$response->content);

$response = soap_xml_post
  ('/withwsdl2/Greet','
    <Envelope xmlns="http://schemas.xmlsoap.org/soap/envelope/">
         <Body>
               <GreetingSpecifier>
                   <who><Big>W</Big><Small>orld</Small></who>
                   <greeting>Hello</greeting>
               </GreetingSpecifier>
         </Body>
    </Envelope>
  ');
ok($response->content =~ /Fault/, 'Fault on malformed body for RPC-Literal: '.$response->content);

$response = soap_xml_post
  ('/withwsdl/Greet',
   '<Envelope xmlns="http://schemas.xmlsoap.org/soap/envelope/"><Body><GreetingSpecifier><name>World</name><greeting>Hello</greeting></GreetingSpecifier></Body></Envelope>'
  );
ok($response->content =~ /Fault/, 'Fault on malformed body for Document-Literal: '.$response->content);

$response = soap_xml_post
  ('/ws/bar',
   '<Envelope xmlns="http://schemas.xmlsoap.org/soap/envelope/"><Body>World</Body></Envelope>'
  );
ok($response->content =~ /Fault/, 'Fault for uncaugh exception: '.$response->content);



sub soap_xml_post {
    my $path = shift;
    my $content = shift;

    local %ENV;
    $ENV{REMOTE_ADDR} ='127.0.0.1';
    $ENV{CONTENT_LENGTH} = length $content;
    $ENV{CONTENT_TYPE} ='application/soap+xml';
    $ENV{SCRIPT_NAME} = $path;
    $ENV{QUERY_STRING} = '';
    $ENV{CATALYST_DEBUG} = 0;
    $ENV{REQUEST_METHOD} ='POST';
    $ENV{SERVER_PORT} ='80';
    $ENV{SERVER_NAME} ='pitombeira';

    my ($writer, $reader, $error) = map { gensym() } 1..3;
    my $pid = open3($writer, $reader, $error,
                    $^X, (map { '-I'.$_ } @INC),
                    catfile(qw(t PostApp script postapp_cgi.pl)));

    print {$writer} $content;
    close $content;

    my $response_str = join '', <$reader>;
    map { warn '# '.$_ } <$error>;

    close $reader;
    close $error;
    waitpid $pid, 0;
    return HTTP::Response->parse($response_str);
}

1;
