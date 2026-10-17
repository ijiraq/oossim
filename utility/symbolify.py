#!/usr/bin/python

# symbolify.py
#
# 10/21/01 
# this program scans a gnuplot-produced postscript file
# and makes the necessary adjustments so that greek letters
# are displayed as greek letters in the event that
# gnuplot for whatever reason doesn't parse it correctly
#

import re
import string
import sys

def get_text_generating_lines(postscript):
    # find all of the parts of the gnuplot postscript which
    # result in text: they can be recognized because they
    # look like [(fontname) # # word word (text)]
    
    pattern = '\[' + \
              '\(.*\)' + \
              '.*' + \
              '\(.*\)' + \
              '.*' + \
              '\]'
    
    lines = re.findall(pattern, text)

    return lines

def build_character_dictionary():
    
    # greek-roman mapping
    greek_roman = {'alpha':'a',
                   'beta':'b',
                   'chi':'c',
                   'delta':'d',
                   'epsilon':'e',
                   'phi':'f',
                   'gamma':'g',
                   'eta':'h',
                   'iota':'i',
                   'kappa':'k',
                   'lambda':'l',
                   'mu':'m',
                   'nu':'n',
                   'omicron':'o',
                   'pi':'p',
                   'theta':'q',
                   'rho':'r',
                   'sigma':'s',
                   'tau':'t',
                   'upsilon':'u',
                   'omega':'w',
                   'xi':'x',
                   'psi':'y',
                   'zeta':'z'}

    for key in greek_roman.keys():
        greekcap = string.capitalize(key)
        romancap = string.capitalize(greek_roman[key])

        # add fontname
        greek_roman[key] = ('Symbol', greek_roman[key])
        
        greek_roman.update({greekcap:\
                            ('Symbol', romancap)})

    chardict = greek_roman
    return chardict

def listsplit(line, list):
    # which keys are present?
    keys = []
    for key in list:
        loc = string.find(line,key)
        if not (loc == -1):
            # we found one!
            keys.append((loc, key))
    keys.sort()
    
    # exclude any keys that overlap, choosing the left one
    goodkeys = keys[0:1]
    for i in range(1,len(keys)):
        key0 = keys[i-1]
        key1 = keys[i]

        after0 = key0[0] + len(key0[1])
        start1 = key1[0]

        if (after0 <= start1):
            # no overlap!
            goodkeys.append(key1)

    returnlist = []
    index = 0
    for key in goodkeys:
        #print key
        start = key[0]
        length = len(key[1])

        # add what comes before the key
        prekey = line[index:start]
        returnlist.append((prekey,'nokey'))

        # add the key itself
        returnlist.append((key[1],'key'))

        # increment index
        index = start + length

    returnlist.append((line[index:],'nokey'))

    # make sure there are no '' elements
    rl2 = []
    for x in returnlist:
        if not (x[0] == ''):
            rl2.append(x)
    return rl2

def parse_line(line, chardict):

    # temporary hack
    first_left = string.find(line,'(')
    first_right = string.find(line,')')
    second_left = string.find(line,'(',first_left+1)
    last_right = string.rfind(line,')')
                             
    fontname = line[first_left+1:first_right]
    numbers = line[first_right+1:second_left]
    linetext = line[second_left+1:last_right]

    print fontname, numbers, linetext

    # split by letters
    
    tokens = listsplit(linetext, chardict.keys())

    newline = ''
    for token in tokens:
        token_word = token[0]
        token_flag = token[1]
        
        if token_flag == 'nokey':
            # just ordinary text:
            newline = newline + \
                      '[(' + fontname + ')' + numbers + \
                      '(' + token_word + ')]\n'

        elif token_flag == 'key':
            # special text
            newline = newline + \
                      '[(' + chardict[token_word][0] + ')' \
                      + numbers + \
                      '(' + chardict[token_word][1] + ')]\n'
    print newline[:-1]
    return newline


# handle arguments

if len(sys.argv) == 2:
    # set default output filename
    inname = sys.argv[1]
    outname = 'output.ps'
elif len(sys.argv) == 3:
    inname = sys.argv[1]
    outname = sys.argv[2]
elif len(sys.argv) == 1:
    print 'usage: symbolify input.ps output.ps'
    sys.exit()

# get file

try:
    fp = open(inname,'r')
    text = fp.read()
    fp.close()
except IOError:
    print 'error reading',inname
    sys.exit()

# do the work

chardict = build_character_dictionary()
lines = get_text_generating_lines(text)

replacements = []
for line in lines:
    newline = parse_line(line, chardict)
    replacements.append([line, newline])

newtext = text
for repl in replacements:
    newtext = string.replace(newtext, repl[0],repl[1])

# write output file
fp = open(outname,'w')
fp.write(newtext)
fp.close()

# done!
