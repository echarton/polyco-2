This tool his the co-reference detector deployed during the CoNLL Shared task 2011 by the Polytechnic School of Montreal.

Our system integrates a multilayer perceptron classiﬁer in a pipeline approach. We describe the heuristic used to select the pairs of coreference candidates that are feeded to the network for training, and our feature selection method. The features used in our approach are based on similarity and identity measures, ﬁltering informations, like gender and number, and other syntactic information.

Original paper :
http://aclweb.org/anthology-new/W/W11/W11-1915.pdf

Results :
http://conll.bbn.com/

Rectifications on metrics and definitive score :
http://code.google.com/p/reference-coreference-scorers/

If you use it please cite in English:
http://aclweb.org/anthology-new/W/W11/W11-1915.bib

```
@InProceedings{charton-gagnon:2011:CoNLL-ST,
  author    = {Charton, Eric  and  Gagnon, Michel},
  title     = {Poly-co: a multilayer perceptron approach for coreference detection},
  booktitle = {Proceedings of the Fifteenth Conference on Computational Natural Language Learning: Shared Task},
  month     = {June},
  year      = {2011},
  address   = {Portland, Oregon, USA},
  publisher = {Association for Computational Linguistics},
  pages     = {97--101},
  url       = {http://www.aclweb.org/anthology/W11-1915}
  software  = {http://http://code.google.com/p/polyco-2/},
}
```

You can cite in French http://aclweb.org/anthology//F/F13/F13-2014.pdf:

```
@Proceedings{F13-2014,
  author    = {Charton, Eric and Gagnon, Michel and Jean-Louis, Ludovic},
  title     = {Semantic annotation influence on coreference detection using perceptron approach (Influence des annotations s{\'e}mantiques sur un syst{\`e}me de d{\'e}tection de cor{\'e}f{\'e}rence {\`a} base de perceptron multi-couches) [in French]},
  series    = {Proceedings of TALN 2013 (Volume 2: Short Papers)},
  year      = {2013},
  publisher = {ATALA},
  pages     ={612-619},
  location  ={Les Sables d'Olonne, France}, 
  url       ={http://aclweb.org/anthology/F13-2014},
}
```

You can contact Dr Eric Charton for questions related to this software.

Personal site : http://www.echarton.com/
Twitter : http://twitter.com/ericcharton

## Help ##
Have a look at the [wiki ](https://code.google.com/p/polyco-2/wiki/Index)