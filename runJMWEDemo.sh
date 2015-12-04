#!/bin/bash

# Script to demo the jMWE usage in Stanford CoreNLP
# author: Tomasz Oliwa

set -o nounset

if [ "$#" -eq 0 ]
then
    echo "Running demo.JMWEAnnotatorDemo with a predefined text"
    java -cp javanlp-core.jar:lib/* demo.JMWEAnnotatorDemo "lib/mweindex_wordnet3.0_semcor1.6.data"
else
    echo "Running demo.JMWEAnnotatorDemo with input text. The input should be enclosed in \" \" symbols, example usage:  $ ./runJMWEDemo.sh \"She looked up the world record.\""
    java -cp javanlp-core.jar:lib/* demo.JMWEAnnotatorDemo "lib/mweindex_wordnet3.0_semcor1.6.data" "$1"
fi
