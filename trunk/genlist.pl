### This tools build the list files used for CoNLL
### Construit la liste des fichiers de train dev et test

### First you avec to build the ready to use dev and test files according to construction process described on the Conll website
### http://conll.bbn.com/index.php/data.html
### This will generate the ready to use document in a folder

### You then have to generate some lists of document to feed Poly-co
### on Ubuntu use command such as :
#   find /home/eric/conll-st-2011-v1/conll-2011/v2/ -name "*conll" > test-liste.txt
#   find /home/eric/conll-st-2011-v1/conll-2011/v2-mentions/ -name "*conll" > test-mentions-liste.txt
### Then you use the generated list to build the Poly-co files 

open(in, "yourpath/test-list.txt") || die "no log file\n"; ## Change the path here
open(out, ">test.list.txt") || die "no out log file\n"; ## Change the output name here

while(<in>){

	my $line = $_;

	my @inline = split(/\s/, $line); 
	
	## python .py parse  skel conll -edited -text
	print out "$inline[4]\n";
	print "$inline[4]\n";

}

close(out);


### You can also replace the path in the pre-generated lists of files provided:
#
### dev_auto.list -> predicted dev corpora
### dev_gold.list -> gold dev corpora
### train_gold.list -> gold train corpora
### test.list.txt -> the test files used for evaluation
#
### ie : 
### home/eric/conll-st-2011-v1/conll-2011/v1/data/train/data/english/annotations/nw/wsj/10/wsj_1094.v1_gold_conll
### put your path :
### mypathtocorpora//v1/data/train/data/english/annotations/nw/wsj/10/wsj_1094.v1_gold_conll

