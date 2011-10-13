#########################################
# 
# Polyco-2 
# v 0.9.0 - 22 sept 11
# 
# Maintained on:
# https://code.google.com/p/polyco-2/
#
# Mostly coded by Dr E.Charton 
# contributions by Pr M. Gagnon
#
#########################################

This tool have been developed for the CoNLL 2011 Shared Task and have been submited under the Polyco name (see http://conll.bbn.com/). 

This is the coreference resolution system Poly-co submitted to the closed track of the CoNLL-2011 Shared Task. Our system integrates a multilayer perceptron classiﬁer in a pipeline approach. We describe in the CoNLL paper the heuristic used to select the pairs of coreference candidates that are feeded to the network for training, and our feature selection method. The features used in our approach are based on similarity and identity measures, ﬁltering informations, like gender and number, and other syntactic information.

*** Warning *** 
This is an experimental tool, built to make ... experiences ! It's not easy to configure and use.  
Surely, it will be difficult to use for Master Student not familiar with evaluation campaign stuff and Linux. 
I can help but not doing it for you :-)

----------------------------
-   External Requirement
----------------------------
-Software
PERL
WEKA
SVMLib encapsultated in Weka (only if you use SVM option) 

- Datas
DATA fron ConLL websites
Ontonotes 4.0 (not public, provided by LDC) 
gender.data provided by Shane Bergsma and Dekang Lin (http://conll.bbn.com/download/gender.data.gz)

----------------------------
-     Configuring 
-     document files
----------------------------
The utility Gentlist.pl give you instructions to generate lists of document used by Poly-co
Please read the comments inside carrefully. Consider that you have to finish the configuration
of CoNLL documents before using this tool.  

Put the generated CoNLL files in the folder ./conll-2011
The outputs folder of Poly-co is ./outputs 

Put the gender.data resource in tthe resources folder

----------------------------
-     Configuration
-     of Poly-co tool
----------------------------

You will need the last version of Perl to run polyco, and Weka tools (needs Sun Java VM). This will be sufficient to use the Perceptron and Tree models. 
To use the SVM classifier option, you will need to encapsulate LibSVM in Weka (read http://weka.wikispaces.com/LibSVM).  

To let perls scripts calling Weka classifiers, don't forget the path's :

export CLASSPATH=/usr/share/java/weka.jar:/usr/share/java/libsvm.jar

To have definitive path, include the following line at the end of your bashrc:

CLASSPATH=$CLASSPATH:/usr/share/java/weka.jar:/usr/share/java/libsvm.jar

- Files

The main tool is writen in perl. It is divided in to part, a training software ( conll-train.pl ) and a co-reference detection software (conll-expe.pl).

- Help

Please visit the Google Code Wiki.

- Contact -
Dr Eric Charton : www.echarton.com
