## Table of Contents
**[Stanford CoreNLP Extensions](#stanford-corenlp-extensions)**  
**[Installation](#installation)**  
**[Demo](#demo)**  
**[Annotator properties](#annotator-properties)**  
**[MWE detectors](#mwe-detectors)**  
**[License](#license)**  
**[Author information](#author-information)**  
**[Original Stanford CoreNLP README](#original-stanford-corenlp-readme)**

# Stanford CoreNLP Extensions

This fork of [Stanford CoreNLP](https://github.com/stanfordnlp/CoreNLP) enables the user to capture Multi-Word Expressions (MWE) from plain text. Under the hood, it uses [jMWE](http://projects.csail.mit.edu/jmwe/), which itself employs a database generated through processing [WordNet](https://wordnet.princeton.edu/).

For example, given the input sentence 

    She traveled to Las Vegas and looked up the world record.
    
the detected MWEs information could include:

    1. travel_to_V={traveled_VBD,to_TO},    token.isInflected(): true,  token.getForm(): traveled_to
    2. las_vegas_N={Las_NNP,Vegas_NNP},     token.isInflected(): false, token.getForm(): las_vegas
    3. las_vegas_P={Las_NNP,Vegas_NNP},     token.isInflected(): false, token.getForm(): las_vegas
    4. look_up_V={looked_VBD,up_RP},        token.isInflected(): true,  token.getForm(): looked_up
    5. world_record_N={world_NN,record_NN}, token.isInflected(): false, token.getForm(): world_record

Detecting MWEs can be useful in a number of applications, such as: 

1. Extracting a subset of n-grams from a corpus for topic modeling and information retrieval purposes.
2. Word Sense Disambiguation problems, see the publications on [jMWE](http://projects.csail.mit.edu/jmwe/) for more information.

This extension is realized as a [new annotator](http://nlp.stanford.edu/software/corenlp.shtml#newannotators) in Stanford CoreNLP, and can therefore be easily integrated into any further downstream NLP processing the same way as any other already existing CoreNLP annotator.

## Installation

### Get Stanford CoreNLP Extensions

1. Clone the project:

        git clone https://github.com/toliwa/CoreNLP
    
2. As usual, get the current models and copy them to the lib folder:
    
        wget http://nlp.stanford.edu/software/stanford-corenlp-models-current.jar -P CoreNLP/lib

### Add jMWE

From [jMWE](http://projects.csail.mit.edu/jmwe/), download:

3. Either ``edu.mit.jmwe_1.0.2.jar`` (binary) or  ``edu.mit.jmwe_1.0.2_jdk.jar`` (binary and src)

4. The Standard MWE Index data file ``mweindex_wordnet3.0_semcor1.6.data``

and copy them to CoreNLP/lib.

Done!

### Compiling, jar packaging and unit tests
1. To compile the project, go inside the CoreNLP folder and run

        ant 

2. To run the demo, first create the jar files with:

        ant jar
    
3. To run the unit tests, run: 

        ant clean && ant test
        
Running the unit tests should output something similar to

```
    [junit] Testsuite: edu.stanford.nlp.pipeline.JMWEAnnotatorTest
    [junit] Tests run: 12, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 4.019 sec
```

to indicate that all tests have passed.
    
    
## Demo

The class ``JMWEAnnotatorDemo`` in the package ``demo`` shows a basic use case of the new annotator, given a String it will detect and print out MWE information.

If jar files have been created (see above), you can also run the ``runJMWEDemo.sh`` shell script, it can call the ``JMWEAnnotatorDemo`` with a predefined text if no further input is given, or use the commandline first argument as input. To get the output as described in the first section, type:

```./runJMWEDemo.sh "She traveled to Las Vegas and looked up the world record."```

The following method from ``JMWEAnnotatorDemo`` shows how to programmatically access detected MWEs. The way to do so mirrors accessing other annotators such as TokensAnnotation as described for the [Stanford CoreNLP demo](http://nlp.stanford.edu/software/corenlp.shtml).

```java
    /**
     * jMWE Demo, prints out discovered MWEs from the text
     * @param index the index
     * @param text the text
     */
    public static void jmweDemo(String index, String text) {
        // creates the properties for Stanford CoreNLP: tokenize, ssplit, pos, lemma, jmwe
        Properties props = new Properties();
        props.setProperty("annotators", "tokenize, ssplit, pos, lemma, jmwe");
        props.setProperty("customAnnotatorClass.jmwe", "edu.stanford.nlp.pipeline.JMWEAnnotator");
        props.setProperty("customAnnotatorClass.jmwe.verbose", "false");
        props.setProperty("customAnnotatorClass.jmwe.underscoreReplacement", "-");
        props.setProperty("customAnnotatorClass.jmwe.indexData", index);
        props.setProperty("customAnnotatorClass.jmwe.detector", "CompositeConsecutiveProperNouns");
        StanfordCoreNLP pipeline = new StanfordCoreNLP(props);
        
        // put the text in the document annotation 
        Annotation doc = new Annotation(text);
        
        // run the CoreNLP pipeline on the document
        pipeline.annotate(doc);
        
        // loop over the sentences
        List<CoreMap> sentences = doc.get(SentencesAnnotation.class);
        System.out.println();
        for(CoreMap sentence: sentences) {
            System.out.println("Sentence: "+sentence);
            // loop over all discovered jMWE token and perform some action
          for (IMWE<IToken> token: sentence.get(JMWEAnnotation.class)) {
              System.out.println("IMWE<IToken>: "+token+", token.isInflected(): "+token.isInflected()+", token.getForm(): "+token.getForm());
            }
          System.out.println();
        }        
    }
```

## Annotator properties

As can be seen in the example above, the JMWEAnnotator has several properties to be set:

    props.setProperty("annotators", "tokenize, ssplit, pos, lemma, jmwe");
"jmwe" is the reference name of the annotator, it has to be called after lemmatization.
    
    props.setProperty("customAnnotatorClass.jmwe", "edu.stanford.nlp.pipeline.JMWEAnnotator")
The full path to its class needs to be set.
 
    props.setProperty("customAnnotatorClass.jmwe.verbose", "false");
By default, verbose is false. If set to true, Annotator information and MWEs will be output during the detection stage.

    props.setProperty("customAnnotatorClass.jmwe.underscoreReplacement", "-");
jMWE 1.0.2 throws an IllegalArgumentException when given a "_" symbol, so underscores have to be replaced during detection. A possible choice would be the hyphen symbol "-".

    props.setProperty("customAnnotatorClass.jmwe.indexData", index);
indexData needs a path to the ``mweindex_wordnet3.0_semcor1.6.data`` file.

    props.setProperty("customAnnotatorClass.jmwe.detector", "CompositeConsecutiveProperNouns");
The type of the MWE detector needs to be defined, currently implemented are "Consecutive", "Exhaustive", "ProperNouns", "Complex" and "CompositeConsecutiveProperNouns".


## MWE detectors

[jMWE](http://projects.csail.mit.edu/jmwe/) comes with a straight-forward way to write and combine detectors, filters and resolvers for MWE discovery. A detailed introduction about this is given in the [jMWE user manual](edu.mit.jmwe_1.0.2_manual.pdf).

The class JMWEAnnotator contains the following method, where the MWE detectors are setup. Adding more detectors is only a matter of adding another switch case and instantiating the desired setup as introduced in the [jMWE user manual](edu.mit.jmwe_1.0.2_manual.pdf).

The choice of the right MWE detector will greatly impact the retrieved MWEs, on the [jMWE](http://projects.csail.mit.edu/jmwe/) page there are jMWE publications, wich provide precision, recall and f-measures for different implemented detectors.


```java
    /**
     * Get the detector.
     * 
     * @param index
     *            the index
     * @param detector 
     *            the detector, \"Consecutive\", \"Exhaustive\", \"ProperNouns\", \"Complex\" or \"CompositeConsecutiveProperNouns\" are supported
     * @return the detector
     */
    public IMWEDetector getDetector(IMWEIndex index, String detector) {
        IMWEDetector iMWEdetector = null;
        switch (detector) {
        case "Consecutive":
            iMWEdetector = new Consecutive(index);
            break;
        case "Exhaustive":
            iMWEdetector = new Exhaustive(index);
            break;
        case "ProperNouns":
            iMWEdetector = ProperNouns.getInstance();
            break;
        case "Complex":
            iMWEdetector = new CompositeDetector(ProperNouns.getInstance(),
                    new MoreFrequentAsMWE(new InflectionPattern(new Consecutive(index))));
            break;
        case "CompositeConsecutiveProperNouns":
            iMWEdetector = new CompositeDetector(new Consecutive(index), ProperNouns.getInstance());            
            break;
        default:
            throw new IllegalArgumentException("Invalid detector argument " + detector
                    + ", only \"Consecutive\", \"Exhaustive\", \"ProperNouns\", \"Complex\" or \"CompositeConsecutiveProperNouns\" are supported.");
        }
        return iMWEdetector;
    }
```

## License

This fork has the same license as the original Stanford CoreNLP, which states on https://github.com/stanfordnlp/CoreNLP :
"The Stanford CoreNLP code is written in Java and licensed under the GNU General Public License (v3 or later)."

The jMWE files (not included here, available from http://projects.csail.mit.edu/jmwe/ ) have the following note on their page:
"The software is distributed under the Creative Commons Attribution 4.0 International License that makes it free to use for any purpose, as long as proper copyright acknowledgement is made."

Name, copyright and other acknowledgements for "jMWE" under the http://creativecommons.org/licenses/by/4.0/ from the page and author of Finlayson, M.A. at http://projects.csail.mit.edu/jmwe/ : 

Finlayson, M.A. and Kulkarni,
N. (2011) Detecting Multi-Word Expressions Improves Word Sense
Disambiguation, Proceedings of the 8th Workshop on Multiword Expressions,
Portland, OR. pp. 20-24. 

Kulkarni, N. and Finlayson, M.A. jMWE: A Java
Toolkit for Detecting Multi-Word Expressions, Proceedings of the 8th Workshop
on Multiword Expressions, Portland, OR. pp. 122-124.

Hereby proper copyright acknowledgement is made as required. 

The GNU Project states that GPL and the Creative Commons Attribution 4.0 license are compatible: http://www.gnu.org/licenses/license-list.en.html#OtherLicenses

## Author information

Stanford CoreNLP Extensions are developed by Tomasz Oliwa at the Center for Research Informatics (CRI), University of Chicago.





## Original Stanford CoreNLP README

Original Stanford CoreNLP README.md from https://github.com/stanfordnlp/CoreNLP :

Stanford CoreNLP
================

Stanford CoreNLP provides a set of natural language analysis tools written in Java. It can take raw human language text input and give the base forms of words, their parts of speech, whether they are names of companies, people, etc., normalize and interpret dates, times, and numeric quantities, mark up the structure of sentences in terms of phrases or word dependencies, and indicate which noun phrases refer to the same entities. It was originally developed for English, but now also provides varying levels of support for (Modern Standard) Arabic, (mainland) Chinese, French, German, and Spanish. Stanford CoreNLP is an integrated framework, which make it very easy to apply a bunch of language analysis tools to a piece of text. Starting from plain text, you can run all the tools with just two lines of code. Its analyses provide the foundational building blocks for higher-level and domain-specific text understanding applications. Stanford CoreNLP is a set of stable and well-tested natural language processing tools, widely used by various groups in academia, industry, and government. The tools variously use rule-based, probabilistic machine learning, and deep learning components.

The Stanford CoreNLP code is written in Java and licensed under the GNU General Public License (v3 or later). Note that this is the full GPL, which allows many free uses, but not its use in proprietary software that you distribute to others.

You can find releases of Stanford CoreNLP on [Maven Central](http://search.maven.org/#browse%7C11864822).

You can find more explanation and documentation on [the Stanford CoreNLP homepage](http://nlp.stanford.edu/software/corenlp.shtml#Demo).

The most recent models associated with the code in the HEAD of this repository can be found [here](http://nlp.stanford.edu/software/stanford-corenlp-models-current.jar).

For information about making contributions to Stanford CoreNLP, see the file [CONTRIBUTING.md](CONTRIBUTING.md).

Questions about CoreNLP can either be posted on StackOverflow with the tag [stanford-nlp](http://stackoverflow.com/questions/tagged/stanford-nlp), 
  or on the [mailing lists](http://nlp.stanford.edu/software/corenlp.shtml#Mail).

