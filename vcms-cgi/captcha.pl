#!/usr/bin/perl -w



use strict;
use CGI  qw/param/;
use Image::Magick; 
use lib "./modules/";
use lib "../../../perl/usr/lib/perl5/x86_64-linux-thread-multi";
use cmlmain;

&cmlmain::init('.');

 
 
sub CreateCapImage($){
	my($cap_string) = @_;
	my $font = 'other/times.ttf';
	my $pointsize = 70;
	my $image = new Image::Magick;
	$image->Set(size => '300x100');
	$image->ReadImage('xc:white');
	$image->Set(
           type        => 'TrueColor',
           antialias   =>   'True',
           fill        =>   'black',
           font        =>   $font,
           pointsize   =>   $pointsize,
    );
	$image->Draw(
            primitive   =>   'text',
            points      =>   '20,70',
            text        =>   $cap_string,
    );
	$image->Extent(
            geometry    =>   '400x120', 
    );
	$image->Roll(
            x           =>   101+int(rand(4)),
    );
	$image->Swirl(
            degrees     =>   int(rand(14))+37,
    );
	$image->Extent(
            geometry    =>   '600x140',
    );
	$image->Roll(
            x           =>   3-int(rand(4)),
    );
	$image->Swirl(
            degrees     =>   int(rand(15))+20,,
    );
	$image->Crop('300x100+100+17');
	$image->Resize('150x50');
	return $image;
}

srand(time ^ $$);
my $image=CreateCapImage(&cmlmain::get_sec_key(param('id')) || '00000');
print "Content-type: image/png\n\n";
binmode STDOUT;
$image->Write('png:-');
undef $image;


