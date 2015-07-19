# Introduction #

This is the coreference resolution system Poly-co submitted to the closed track of the CoNLL-2011 Shared Task. Our system integrates a multilayer perceptron classiﬁer in a pipeline approach. We describe the heuristic used to select the pairs of coreference candidates that are feeded to the network for training, and our feature selection method. The features used in our approach are based on similarity and identity measures, ﬁltering informations, like gender and number, and other syntactic information.

**!!! Warning !!!
This is an experimental tool, built to make ... experiments ! It's not easy to configure and use.**

# Requirements #

## Software ##
PERL

WEKA

SVMLib encapsultated in Weka (only if you use SVM option)

## Datas ##
DATA fron ConLL websites

Ontonotes 4.0 (not public, provided by LDC)

gender.data provided by Shane Bergsma and Dekang Lin (http://conll.bbn.com/download/gender.data.gz)

### Configuring document files ###
The utility ''Gentlist.pl'' gives instructions to generate lists of document used by Poly-co
Please read the comments inside carrefully. Consider that you have to complete the configuration
of CoNLL documents before using this tool.

Put the generated CoNLL files in the folder ./conll-2011  \\
The outputs folder of Poly-co is ./outputs

### Configuration of Poly-co ###
You will need the last version of Perl to run polyco, and Weka tools (needs Sun Java VM). This will be sufficient to use the Perceptron and Tree models. To use the SVM classifier option, you will need to encapsulate LibSVM in Weka (read  http://weka.wikispaces.com/LibSVM).

To let perls scripts calling Weka classifiers, don't forget the path's :

export CLASSPATH=/usr/share/java/weka.jar:/usr/share/java/libsvm.jar

To have definitive path, include the following line at the end of your bashrc:

CLASSPATH=$CLASSPATH:/usr/share/java/weka.jar:/usr/share/java/libsvm.jar

# Files #

The main tool is writen in perl. It is divided in to part, a training software ( '''conll-train.pl''' ) and a co-reference detection software ('''conll-expe.pl''').

The precalculated models used in the campaign are in the models folder. So you mostly don't have to use the conll-train.pl tool to label coreferences.