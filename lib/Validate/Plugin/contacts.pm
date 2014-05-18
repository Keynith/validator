package Validate::Plugin::contacts;

use strict;
use YAML::Syck;

my %exceptions = map { $_ => 1 } qw(
  test-ipv6.com
  test-ipv6.ams.vr.org
  test-ipv6.chi.vr.org
  test-ipv6.iad.vr.org
  test-ipv6.sjc.vr.org
  );

sub new {
    my $classname = shift;
    my $self      = {};
    bless( $self, $classname );
    $self->{validate} = shift;
    return $self;
}

sub run {
    my $self     = shift;
    my $validate = $self->{validate};
    my $config   = $validate->{config};

    my $name = $validate->{server};
    my %config = %$config;
    
    my $found="";
    my $expect=<<"EOF";
 site->contact not pointing to jfesler
 site->mailto not pointing to jfesler
EOF

     my $notes_ignore = "ignored for this site";
    my  $notes_bad = <<"EOF";

Please make sure that your <code>/site/config.js</code> has reasonable
values for <code>site->contact</code> and <code>site->mailto</code>.  These are used
for users to send feedback.  

If you truely wish to leave this pointed at jfesler, please ask for an
exception to this audit rule, so we stop flagging on this audit rule.
EOF

my $notes_good = "";


    my $contact = $config{"site"}{"contact"};
    my $mailto  = $config{"site"}{"mailto"};
    my $found = <<"EOF";
 site->contact=$contact
 site->mailto=$mailto
EOF

    if ( exists $exceptions{$name} ) {
      return { status=>"ok", expect=>"exception made",found=>$found,notes=>"Skipped for this site"};
    }
    if (($contact =~ /fesler/i) || ($mailto =~ /fesler/i)) {
      return { status=>"bad", expect=>$expect,found=>$found,notes=>$notes_bad};
    }    
    return { status=>"ok",expect=>$expect,found=>$found,notes=>$notes_good};
    
}

1;
__END__
{"config":{"options":{"comment_html":1,"show_stats":"/stats.html","comment":"/comment.php","survey":"/survey.php","ip":"/ip/"},"site":{"mailto":"jfesler@test-ipv6.com","name":"test-ipv6.com","contact":"Jason Fesler"},"twitter":{"enable":1,"name":"testipv6com"},"facebook":{"fb_admins":"688631212","enable":1},"load":{"ipv6":"2001:470:1:18::119","domain":"test-ipv6.com","ipv4":"216.218.228.119"},"footer":{"#link":"http://gigo.com","#operator":"Jason Fesler","#logo":"http://gigo.com/w/images/thumb/2/2d/Notice.jpg/120px-Notice.jpg","#html":"/site/footer.html"}}}
