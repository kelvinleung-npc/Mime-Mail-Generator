#!/opt/bcgov/bin/perl

use Getopt::Std;
#########################################
# given the 3 inputs, the function adds #
# the image inline into the mail        #
#########################################
sub MimeInlineImage {
   my $imagename = $_[0]; 
   my $imagetype = $_[1];
   my $contentidcount = $_[2];
   my $base64content = `base64 $imagename.$imagetype`;
   print SMTP "Content-Type: image/$imagetype;             name=\"$imagename.$imagetype\"\n";
   print SMTP "Content-Transfer-Encoding: base64\n";
   print SMTP "Content-ID: <$contentidcount>\n";
   print SMTP "Content-Disposition: inline; filename=\"$imagename.$imagetype\"\n";
   print SMTP "Content-Location: $imagename.$imagetype\n";
   print SMTP "\n";
   print SMTP "$base64content\n";
}

##############################################
# given the name of a file and type          # 
# (if txt or image) adds as downloadable file#
##############################################
sub MimePlainTextAttach {
   my $attachmentname = $_[0];
   my $attachmenttype = $_[1];
   my $base64content = `base64 $attachmentname.$attachmenttype`;
   if( $attachmentype eq "txt" or "csv" or "log"){
      print SMTP "Content-Type: text/plain;             name=\"$attachmentname.$attachmenttype\"\n";
   } else {
      print SMTP "Content-Type: image/$attachmenttype;             name=\"$attachmentname.$attachmenttype\"\n";
   }
   print SMTP "Content-Transfer-Encoding: base64\n";
   print SMTP "Content-Disposition: attachment; filename=\"$attachmentname.$attachmenttype\"\n";
   print SMTP "Content-Location: $attachmentname.$attachmenttype\n";
   print SMTP "\n";
   print SMTP "$base64content\n";
}

$USAGE     = "\nUsage: $0 -t <to> -f <from> [-c <cc>] -s <subject> [-h <html input>] [-T <text>]\n\n".
             "\tt - comma separated list of email addresses\n".
             "\tc - comma separated list of email addresses\n".
             "\tf - source email address\n".
             "\ts - subject of email note\n".
             "\th - html body (if not present then STDIN)\n".
             "\tT - text body (if not present, then duplicate html)\n\n";
getopts("t:c:f:s:h:i:a:T:D") || die $USAGE;

die $USAGE if !$opt_s || !$opt_t || !$opt_f;

if( $opt_h ) {
   chomp(@html = `cat $opt_h`);
}
else {
   while(<>) {
      chomp;
      push @html,$_;
   }
}

die "Need to send SOMETHING\n" if !@html;

if( $opt_T ) {
   chomp(@text = `cat $opt_T`);
}
else {
   @text = @html;
}

if( $opt_i ) {
   @list = split(/,/,$opt_i);
   @images;
   for my $entry ( @list ){
      ($name,$type) = ($entry =~ /(.*)\.(.*)/);
      push(@images, [$name,$type]);
   }
}else {
   @images; 
}

if ( $opt_a ){
   @list = split(/,/,$opt_a);
   @attachments;
   for my $entry ( @list ){
      ($name,$type) = ($entry =~ /(.*)\.(.*)/);
      push(@attachments, [$name,$type]);
   }
}else{
   @attachments; 
}

chomp($hostname = `hostname`);
($username = `id`) =~ s/^[^(]+\(([^)]+)\).*/$1/;
$mailFrom = $username." - ".uc($hostname)." <".$opt_f.">";
$text = &Quote(@text);
$html = &Quote(@html);
$Stamp = time;
$DateStamp = scalar(localtime($Stamp));

#####################################################################
# Generates the MIME mail to be sent off. As the program allows for #
# html text display, inline images, and external file transfer      #
# the program requires 3 layers of boundaries so the Mail Agent     #
# receiving the packets knows how to separate the data              #
# The html structure in the body must label its cid: in ascending   #
# order                                                             #                                                      
#####################################################################

###################################################################################################################
# SendMail takes a hash of parameters as input. If debug is found, then                                           #
# print out to standard output. Images and attachments get put in comma                                           #
# separated.                                                                                                      #
# Example:                                                                                                        #
# my %emailhash = (  Subject     =>    "Test",                                                                    #
#                To          =>    "kelvin.leung\@gov.bc.ca",                                                     #
#                From        =>    "iappsup\@gov.bc.ca",                                                          #
#                Body        =>    <h1>By Servers</h1><img src=\"cid:1\"><h1>By Priority</h1><img src=\"cid:2\">, #
#                Images      =>    image1.jpg,image2.png                                                          #
#                Attachments =>    example.txt,server.jpg                                                         #
#             );                                                                                                  #                                                        
################################################################################################################### 

###############################################################################################################################################################
# EXAMPLE CALLING MODIFIED MIMEMAIL
# my $mailfile = 'PathToMIMEMAIL/ModifiedMimeMail.pl';
# sub sendMail {
#    my(%parms) = @_;
#    my $to             = (exists($parms{To})     ?$parms{To}     :"kelvin.leung\@gov.bc.ca");
#    my $from           = (exists($parms{From})   ?$parms{From}   :"NNRAdmin\@gov.bc.ca");
#    my $subject        = (exists($parms{Subject})?$parms{Subject}:"Unspecified subject");
#    my $body           = (exists($parms{Body})   ?$parms{Body}   :"Unspecified Body");
#    my $images         = (exists($parms{Images})   ?$parms{Images}   :"No Images Given");
#    my $attachments    = (exists($parms{Attachments})   ?$parms{Attachments}   :"No Attachments Given");
#    printf STDERR "to=\"$to\"\n".
#                  "from=\"$from\"\n".
#                  "subject=\"$subject\"\n".
#                  "body has %d characters\n",length($body) if exists($parms{Debug});
#     if( open(MAIL,"| $mailfile -f $from -t $to -i $images -a $attachments -s \"$subject\"".(exists($parms{Debug}) ?"":" 2>/dev/null >/dev/null")) ) {
#       printf MAIL $body;
#       close(MAIL);
#    }
#    else {
#       printf STDERR "ERROR: Failed to open MAIL, cannot send\n";
#    }
# }
# sendMail(%emailhash);
###############################################################################################################################################################

if ( open( SMTP, "| /usr/bin/telnet localhost 25") ){
   print SMTP "HELO net.gov.bc.ca\n";
   print SMTP "MAIL FROM: $mailFrom\n";
   foreach $email (split(",",$opt_t)) {
      print SMTP "RCPT TO: <$email>\n" if $email;
   }
   foreach $email (split(",",$opt_c)) {
      print SMTP "RCPT TO: <$email>\n" if $email;
   }
   print SMTP "DATA\n";
   print SMTP "FROM: <$opt_f>\n";
   print SMTP "To: <$opt_t>\n";
   print SMTP "Subject: $opt_s \n";
   print SMTP "Date: $DateStamp\n";
   print SMTP "MIME-Version: 1.0\n";
   print SMTP "Content-Type: multipart/mixed; boundary=\"1\"\n";
   print SMTP "\n";
   print SMTP "--1\n";
   print SMTP "Content-Type: multipart/related; boundary=\"2\"\n";
   print SMTP "\n";
   print SMTP "--2\n";
   print SMTP "Content-Type: multipart/alternative; boundary=\"3\"\n";
   print SMTP "\n";
   print SMTP "--3\n";
   print SMTP "Content-Type: text/plain;            charset=\"utf-8\"\n";
   print SMTP "Content-Transfer-Encoding: quoted-printable\n";
   print SMTP "\n";
   print SMTP "$text\n";
   print SMTP "\n";
   print SMTP "--3\n";
   print SMTP "Content-Type: text/html;            charset=\"utf-8\"\n";
   print SMTP "Content-Transfer-Encoding: quoted-printable\n";
   print SMTP "\n";
   print SMTP "$html\n";
   print SMTP "--3--\n";
   my $contentid = 1;
   if (scalar(@images) > 0){
      for my $image (@images){
         print SMTP "--2\n";
         MimeInlineImage( $image->[0],$image->[1],$contentid );
         $contentid++;
      }
   }

   print SMTP "--2--\n";
   print SMTP "\n";
   if (scalar(@attachments) > 0){
      for my $item (@attachments){
         print SMTP "--1\n";
         MimePlainTextAttach( $item->[0],$item->[1] );
      }
   }
   print SMTP "--1--\n";
   print SMTP ".\n";
   print SMTP "quit\n";
   close(SMTP);
}

exit;

##################################################
# Encodes mime mail text into quoted-printable   #
##################################################
sub Quote {
   my(@Lines) = @_;
   my($Line,@Result,$Result);

   @Result = ();
   foreach $Line (@Lines) {
      $Result="";
      while( ($Byte,$Line) = ($Line =~ /^(.)(.*)$/) ) {
         if( length($Result) >= 71 ) {
            $Result = ".".$Result if $Result =~ /^\./;
            push @Result,$Result."=";
            $Result = "";
         }
         $Num = ord($Byte);
         if( ($Byte ne "=") &&
             ((($Num >= 33) && ($Num <= 126)) ||
              ((($Num == 9) || ($Num == 32)) && $Line)) ) {
            $Result .= $Byte;
         }
         else {
            $Result .= sprintf("=%02X",$Num);
          }
      }
      $Result = ".".$Result if $Result =~ /^\./;
      push @Result,$Result if $Result;
   }
   printf STDERR "\nQUOTED: %s\n\n",join("\nQOUTED: ",@Result) if $opt_D;
   return join("\n",@Result);
}
