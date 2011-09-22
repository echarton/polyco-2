### Construit la liste des fichiers de tests
# python skeleton2conll.py /home/eric/conll-st-2011-v1/ontonotes-release-4.0/data///english/annotations/bn/cnn/00/cnn_0079.parse /home/eric/conll-st-2011-v1/conll-2011/test/conll-2011/v2/data/test/data/english/annotations/bn/cnn/00/cnn_0079.v2_auto_skel /home/eric/conll-st-2011-v1/conll-2011/test/conll-2011/v2/data/test/data/english/annotations/bn/cnn/00/cnn_0079.v2_auto_conll -edited --text

open(in, "/home/eric/conll-st-2011-v1/conll-2011/scripts/test.log") || die "no log file\n";
open(out, ">test.list.txt") || die "no out log file\n";

while(<in>){

	my $line = $_;

	my @inline = split(/\s/, $line); 
	
	## python .py parse  skel conll -edited -text
	print out "$inline[4]\n";
	print "$inline[4]\n";

}

close(out);
