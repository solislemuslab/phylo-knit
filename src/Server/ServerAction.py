import io
import os
import subprocess
import tempfile
from uuid import uuid4

import pandas as pd
from reportlab.graphics import renderPDF
from svglib.svglib import svg2rlg


# The jar files live next to this script; locate them from here so the
# server can be started from any working directory.
SERVER_DIR = os.path.dirname(os.path.abspath(__file__))
LEV1ATHAN_JAR = os.path.join(SERVER_DIR, "Lev1athan.jar")
NEWICK_TO_TRIPLET_JAR = os.path.join(SERVER_DIR, "NewickToTriplet.jar")


# Temporary files go to the system temp folder, not the working directory
def getRandomFileName():
    return os.path.join(tempfile.gettempdir(), "phyloknit-" + str(uuid4()) + ".tmp")


# for every pair in the set (of strings) of taxon pairs, 
# check if a and b are contained in the set
def isDup(pairs, a, b):
    for pair in pairs:
        if a in pair and b in pair:
            return 1
    return 0


def pdfFromSVG(svg_dat):
    # Convert the SVG text to a PDF
    svg_file = io.StringIO(svg_dat)
    drawing = svg2rlg(svg_file)
    return renderPDF.drawToString(drawing)


# Removes duplicate triplets from a triplet file, overwriting the original file
# where leaf1 leaf2 | outgroup is the pattern of each of the triples, we remove
# duplicates as defined as (leaf1 leaf2 | outgroup) == (leaf2 leaf1 | outgroup)
def removeDupTriplets(tripletString):
    result = dict()
    toRemove = []

    lines = tripletString.split("\n")
    for triple in lines:
        if triple.strip() == '':
            continue

        names = triple.split()
        if len(names) < 3:
            raise ValueError("Each triplet line needs three taxon names, but this "
                             "line has " + str(len(names)) + ": \"" + triple.strip() + "\"")
        leaf1, leaf2, outgroup = names[0], names[1], names[2]
        
        if outgroup in result:
            pairs = result[outgroup]
            if isDup(pairs, leaf1, leaf2):
                # do not add duplicate triple to file
                # print("duplicate in " , pairs, " and ", leaf1, leaf2)
                toRemove.append(triple)
            else: # not a duplicate, add to set of leaf pairs with that outgroup.
                pairs.append([leaf1, leaf2])
            result[outgroup] = pairs
        else: # create new outgroup->pairs dict entry
            result[outgroup] = [[leaf1, leaf2]]

    # remove duplicates and return the string
    for item in toRemove:
        lines.remove(item)
    newString = ""
    for item in lines:
        newString += item + "\n"

    return newString


# ensures duplicate triples do not get added when parsing through HyDe file.
# when provided without a backbone tree
# these can erroneously add hybrid relationships
def containsTriple(triple_set, leaf1, leaf2, outgroup):
    for triplet in triple_set:
        #print(triplet , "is triplet. does it have", leaf1, leaf2, outgroup)
        if leaf1 in triplet and leaf2 in triplet and outgroup in triplet:
            return 1
    return 0

# From a HyDe output file (fileName) and a p-value (threshold), 
# generate and extract triplets via the following guidelines:
#   if the triplet's p-value is below the threshold:
#       add two triples with outgroups as both parents
#   else add only a single triple
#
# unfiltered HyDe files contain all possible triples, which will result in an arbitrary tree. 
# thus a backbone is necessary to provide an informative tree. 
#
# Raises ValueError, with a message for the user, if hydeContent is not HyDe
# output in one of these formats.
HYDE_FORMAT_ERROR = ("This does not look like HyDe output. Expected either lines like "
                     "\"Hybrid: 3 Parents: 2 and 4  <z-score>  <p-value>\" or HyDe's table "
                     "with the columns P1, Hybrid, P2, Zscore, Pvalue, Gamma, ...")
NEW_HYDE_COLUMNS = {'P1', 'Hybrid', 'P2', 'Pvalue'}

def parseHydeToTriplets(hydeContent, threshold, backboneNewick):
    try:
        # check if this is the old format
        dataset = pd.read_table(io.StringIO(hydeContent), sep=" ", header=None)
        if not len(dataset.columns) == 8:
            # dataset could be delimited by tabs, spaces, ..., so we have to read like this
            datareader = pd.read_table(io.StringIO(hydeContent), sep=None, iterator=True, engine='python')
            dataset = datareader.read()
    except (pd.errors.ParserError, pd.errors.EmptyDataError) as e:
        raise ValueError(HYDE_FORMAT_ERROR) from e


    tripletsFromLess1 = ""
    tripletsFromLess2 = ""
    tripletsFromMore1 = ""

    trip = [] # storage for all triples
    
    # Older HyDe format that lists only putative parents, hybrid, z scores and p-values
    if len(dataset.columns) == 8:
        dataset.columns = ['a0', 'hybrid', 'a2', 'parent1', 'a4', 'parent2', 'z-score', 'p-value']
        dataset['hybrid'] = dataset['hybrid'].astype(str)
        dataset['parent1'] = dataset['parent1'].astype(str)
        dataset['parent2'] = dataset['parent2'].astype(str)

        # significant: p < threshold; everything else (including p == threshold) is not
        datasetLess = dataset.loc[dataset['p-value'] < threshold]
        datasetMore = dataset.loc[dataset['p-value'] >= threshold]
        tripletsFromLess1 = datasetLess.values[:, [1, 3, 5]]
        tripletsFromLess2 = datasetLess.values[:, [1, 5, 3]]
        tripletsFromMore1 = datasetMore.values[:, [1, 5, 3]]
    # Newer HyDe format that contains site pattern frequencies
    elif len(dataset.columns) == 21 and NEW_HYDE_COLUMNS <= set(dataset.columns):
        dataset['P1'] = dataset['P1'].astype(str)
        dataset['P2'] = dataset['P2'].astype(str)
        dataset['Hybrid'] = dataset['Hybrid'].astype(str)

        datasetLess = dataset.loc[dataset['Pvalue'] < threshold]
        datasetMore = dataset.loc[dataset['Pvalue'] >= threshold]
        tripletsFromLess1 = datasetLess.values[:, [1, 0, 2]]
        tripletsFromLess2 = datasetLess.values[:, [1, 2, 0]]
        tripletsFromMore1 = datasetMore.values[:, [1, 0, 2]]
    else:
        raise ValueError(HYDE_FORMAT_ERROR)
    
    # Add all triplets that indicate a hybrid relationship given p-value
    for i in range(len(tripletsFromLess1)):
        trip.append([tripletsFromLess1[i][0], tripletsFromLess1[i][1], tripletsFromLess1[i][2]])
    for j in range(len(tripletsFromLess2)):
        trip.append([tripletsFromLess2[j][0], tripletsFromLess2[j][1], tripletsFromLess2[j][2]])

    userVals = []
    print("backboneNewick is :", backboneNewick)
    if backboneNewick != "none_provided":
        # NewickToTriplet.jar would read a hybrid label ("#H1") as a taxon
        if "#" in backboneNewick:
            raise ValueError("The backbone must be a tree; reduce a network "
                             "to its major tree first")
        userVals = backBoneToTriplets(backboneNewick)
    
    # if backbone tree is provided, use backbone (nexus/parenthetical)
    # throw away any "tripletsfrommore" (don't use at all)
    if len(userVals) > 0:
        # trips = triplets from less, triplets from more, PLUS backbone triplets
        for triple in userVals:
            trip.append([str(triple[0]), str(triple[1]), str(triple[2])])
    else: 
        oldleaf1 = ""
        oldleaf2 = ""
        oldoutgroup = ""
        for k in range(len(tripletsFromMore1)):
            leaf1 = str(tripletsFromMore1[k][0])
            leaf2 = str(tripletsFromMore1[k][1])
            outgroup = str(tripletsFromMore1[k][2])
            # if trip contains a triple with values in "tripletsFromMore1", do not add.
            old_triple = [[oldleaf1, oldleaf2, oldoutgroup]]
            if not (containsTriple(trip, leaf1, leaf2, outgroup) or 
                    containsTriple(old_triple, leaf1, leaf2, outgroup)):
                trip.append([leaf1, leaf2, outgroup])
            oldleaf1 = leaf1
            oldleaf2 = leaf2
            oldoutgroup = outgroup
            
    triplets = ""
    for triple in trip:
        triplets += str(triple[0]) + " " + str(triple[1]) + " " + str(triple[2]) + "\n"


    print("\n\n------\ntriplets: ", triplets)
    triplets = removeDupTriplets(triplets)
    return triplets

def fetchNewick(levFile):
    newick = ""

    with open(levFile, 'r') as f:
        lines = f.readlines()
    
    for line in lines:
        if "eNewick output" in line.strip():
            r = str(line.strip())
            r = r.split(":")
            #r[len(r)-1] = r[len(r)-1].replace(";","")
            newick = r[len(r)-1]
            break

    return newick


# This used to be triplets to dot BUT it turns out that the Newick output from Lev1athan is correct,
# but the dot file output does not reflect what we want ours to look like. So, we just take the
# newick and pass it back into our other machinery instead.
#
# Raises ValueError, with a message for the user, if there are no triplets or
# Lev1athan cannot build a network from them.
def tripletsToNewick(tripletsString):
    tripletsString = removeDupTriplets(tripletsString).strip()
    if tripletsString == "":
        raise ValueError("No triplets were given.")

    trip_filename = getRandomFileName()
    lev_filename = getRandomFileName()
    try:
        with open(trip_filename, "w+") as f:
            f.write(tripletsString)

        with open(lev_filename, "w") as lev_file:
            subprocess.run(["java", "-jar", LEV1ATHAN_JAR, trip_filename, "--nopostprocess"],
                           stdout=lev_file)

        newick = fetchNewick(lev_filename)
        if newick == "":
            with open(lev_filename) as f:
                reason = lev1athanError(f.read())
            raise ValueError("Lev1athan could not build a network from these "
                             "triplets: " + reason)
    finally:
        for filename in (trip_filename, lev_filename):
            if os.path.exists(filename):
                os.remove(filename)

    return newick


# Lev1athan reports problems in its normal output (and still exits with
# status 0). Pick out the lines that say what went wrong.
def lev1athanError(levOutput):
    reasons = []
    for line in levOutput.splitlines():
        line = line.strip()
        if line.startswith("//") and "Terminating" not in line:
            continue        # an ordinary comment
        if line == "" or line.startswith("Problem reading file"):
            continue        # the file name is a temporary file, not useful to the user
        reasons.append(line.lstrip("/ "))
    return " ".join(reasons) or "it produced no network."

# Runs NewickToTriplet.jar on a backbone Newick string (passed on stdin)
# and returns the set of triplets it prints
def backBoneToTriplets(backboneNewick):
    result = subprocess.run(["java", "-jar", NEWICK_TO_TRIPLET_JAR],
                            input=backboneNewick, capture_output=True, text=True)
    userTriplets = set()
    for line in result.stdout.splitlines():
        if "//" in line:
            continue
        currLine = line.strip().split()
        for i in range(len(currLine)):
            currLine[i] = (currLine[i]).strip()
        userTriplets.add(tuple(currLine))
    return userTriplets
