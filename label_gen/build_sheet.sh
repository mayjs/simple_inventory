#!/usr/bin/env bash
mkdir codes
rm ./codes/*.png
python ./generate_labels.py -lf "$LABEL_FONT" -n 24 -b "http://inv/fridge/" codes
# generate_latex does not have to be called everytime
python ./generate_latex.py generated.tex
rm pdf/*
mkdir pdf
pdflatex -output-directory pdf latex_template.tex
mv pdf/latex_template.pdf "$(date +%y%m%d%H%M).pdf"
