import os
import re

import numpy as np
import pandas as pd
import pydot

# import ParentheticalToDot
# from Launcher import removeDup
import ParentheticalToDot

# for every pair in the set (of strings) of taxon pairs, 
# check if a and b are contained in the set
def isDup(pairs, a, b):
    for pair in pairs:
        if a in pair and b in pair:
            return 1
    return 0

# Removes duplicate triplets from a triplet file, overwriting the original file
# where leaf1 leaf2 | outgroup is the pattern of each of the triples, we remove
# duplicates as defined as (leaf1 leaf2 | outgroup) == (leaf2 leaf1 | outgroup)
def removeDupTriplets(filename):
    with open(filename) as f:
        filecontents = f.readlines()
    result = dict()
    file = open(filename, "w")

    for triple in filecontents:
        outgroup = triple.split()[2]
        leaf1 = triple.split()[0]
        leaf2 = triple.split()[1]
        
        if outgroup in result:
            pairs = result[outgroup]
            if isDup(pairs, leaf1, leaf2):
                # do not add duplicate triple to file
                print("duplicate in " , pairs, " and ", leaf1, leaf2)
            else: # not a duplicate, add to set of leaf pairs with that outgroup.
                file.write(leaf1 + " " + leaf2 + " " + outgroup + "\n")
                pairs.append([leaf1, leaf2])
            result[outgroup] = pairs
        else: # create new outgroup->pairs dict entry
            file.write(leaf1 + " " + leaf2 + " " + outgroup + "\n")
            result[outgroup] = [[leaf1, leaf2]]
    file.close()
    print("This is the triplet result", result)


def parseHydeToTriplets(fileName, threshold):
    f = open(fileName,'r')
    lines = f.readlines()
    result = []
    for x in lines:
        result.append(x.split(" "))
    dataset = pd.read_table(fileName, delim_whitespace=True, header=None)
    tripletsFromLess1 = ""
    tripletsFromLess2 = ""
    tripletsFromMore1 = ''

    trip = set()
    if len(dataset.columns) == 8:
        dataset.columns = ['a0', 'a1', 'a2', 'a3', 'a4', 'a5', 'a6', 'a7']
        datasetLess = dataset.loc[dataset['a7'] < threshold]
        datasetMore = dataset.loc[dataset['a7'] > threshold]
        tripletsFromLess1 = datasetLess.values[:, [1, 3, 5]]
        tripletsFromLess2 = datasetLess.values[:, [1, 5, 3]]
        tripletsFromMore1 = datasetMore.values[:, [1, 5, 3]]
     
    
        for i in range(len(tripletsFromLess1)):
            trip.add(tuple(tripletsFromLess1[i]))
        for j in range(len(tripletsFromLess2)):
            trip.add(tuple(tripletsFromLess2[j]))
        userVals = backBoneToTriplets()
        print("BACKBONE TREE")
        print("TRIPLETS FROM BACKBONE",userVals)
        print(" ")
        print(" ")
        print("HYDE FILE TRIPLETS",tripletsFromMore1)
        for k in range(len(tripletsFromMore1)):
            #TODO:
            # TRIPLET CHECKING WILL BE ADDED HERE

            tempTriplet = ()
            #Swapping of parents
            tempTriplet = tempTriplet + (tripletsFromMore1[k][0],tripletsFromMore1[k][2],tripletsFromMore1[k][1])
            print(tempTriplet in userVals, tempTriplet)
            
            #trip.add(tuple(tripletsFromMore1[k]))
            
            if tempTriplet in userVals:
                trip.add(tuple(tempTriplet))
            else:
                trip.add(tuple(tripletsFromMore1[k]))
            
        re = []
        print(trip)
        print("set main")
        for i,val in enumerate(trip):
            re.append(list(val))
        re = np.array(re)
        np.savetxt('Triplets4.txt', re, fmt='%d', delimiter=" ")
        
        
        
    elif len(dataset.columns) == 21:
        dataset = pd.read_table(fileName, delim_whitespace=True, header=None,skiprows=[0])
        datasetLess = dataset.loc[dataset[4] < threshold]
        datasetMore = dataset.loc[dataset[4] > threshold]
        tripletsFromLess1 = datasetLess.values[:, [1, 0, 2]]
        tripletsFromLess2 = datasetLess.values[:, [1, 2, 0]]
        tripletsFromMore1 = datasetMore.values[:, [1, 0, 2]]
        userVals = backBoneToTriplets()
        print("BACKBONE TREE")
        print("TRIPLETS FROM BACKBONE",userVals)
        print(" ")
        print(" ")
        print("HYDE FILE TRIPLETS",tripletsFromMore1)
        for k in range(len(tripletsFromMore1)):
            #TODO:
            # TRIPLET CHECKING WILL BE ADDED HERE

            tempTriplet = ()
            #Swapping of parents
            tempTriplet = tempTriplet + (tripletsFromMore1[k][0],tripletsFromMore1[k][2],tripletsFromMore1[k][1])
            print(tempTriplet in userVals, tempTriplet)
            
            #trip.add(tuple(tripletsFromMore1[k]))
            
            if tempTriplet in userVals:
                trip.add(tuple(tempTriplet))
            else:
                trip.add(tuple(tripletsFromMore1[k]))
            
        re = []
        print(trip)
        print("set main")
        for i,val in enumerate(trip):
            re.append(list(val))
        re = np.array(re)
        np.savetxt('Triplets4.txt', re, fmt='%d', delimiter=" ")
    else:
        return 401
    # make 2 types of triplets from the dataset less than the threshold
    #print(tripletsFromLess1)
    #(tripletsFromLess2)

    # Writing Triplets from Less in 2 parts
    np.savetxt('Triplets1.txt', tripletsFromLess1, fmt='%d', delimiter=" ")
    np.savetxt('Triplets2.txt', tripletsFromLess2, fmt='%d', delimiter=" ")

    # Working with dataset more than the threshold
    

    np.savetxt('Triplets3.txt', tripletsFromMore1, fmt='%d', delimiter=" ")

    #print(tripletsFromMore1)

    read_files = ['Triplets4.txt']

    with open("HydeToTriplets.txt", "wb") as outfile:
        for f in read_files:
            with open(f, "rb") as infile:
                outfile.write(infile.read())
    outfile.close()
    removeDupTriplets("HydeToTriplets.txt")
    return 0

def returnParentheticalFormat(fileName):
    parentheticalFormat = ''
    for line in reversed(list(open(fileName))):
        if line.__contains__('eNewick'):
            parentheticalFormat = line[28:]
            # print(parentheticalFormat)
            # print(line.rstrip())
    return parentheticalFormat.rstrip()


def convertDotToPNG(fileName):
    (graph,) = pydot.graph_from_dot_file(fileName)
    graph.write_png('cExample1.png')


def convertDotToPNGJulia(fileName, flag=''):
    paren = returnParentheticalFormat(fileName)
    with open("NetworkParen.net", "w") as text_file:
        text_file.write(paren)
    # write it to a file
    # then use the julia command
    cmd = 'julia plot-network.jl NetworkParen.net ' + flag
    os.system(cmd)


def removeLeavesJulia(leafNodes):
    with open("leaves.txt", "w") as text_file:
        text_file.write(leafNodes)
    # write it to a file
    # then use the julia command
    cmd = 'julia remove-leaves.jl  NetworkParen.net  leaves.txt'
    os.system(cmd)
    # convert Parenthetical format to png
    cmd = 'julia plot-network.jl reduced-net.txt'
    os.system(cmd)


def parentheticalFormatToPNG(parentheticalFormat, flag=''):
    with open("NetworkParen.net", "w") as text_file:
        text_file.write(parentheticalFormat)
    # write it to a file
    # then use the julia command
    cmd = 'julia plot-network.jl NetworkParen.net ' + flag
    os.system(cmd)

    # assumes that the triplets are in the parenthetical format in hte NetworkParen.net text file


# converts
def changeRoot(flag, newRoot):
    cmd = 'julia change-root.jl NetworkParen.net ' + flag + ' ' + newRoot + ' '
    os.system(cmd)
    # convert Parenthetical format to png
    cmd = 'julia plot-network.jl new-net.txt'
    os.system(cmd)


# julia change-root.jl test.net outgroup 3

"""There is a problem in the following method. I tried the same commmand via the terminal and that generates a different
dot file as compared the same command via Python.

update oct19: Lev1athan output shows that:
"// Terminating because in normal usage duplicate triplets in input not allowed."
following this, we attempt to remove duplicate triplets before calling Lev1athan
"""


def tripletsToDot(tripletsFName):
    removeDupTriplets(filename=tripletsFName)
    cmd = 'java -jar Lev1athan.jar ' + tripletsFName + ' > cExample1.dot --nopostprocess'
    os.system(cmd)


def symbolReplacement(inputStr):
    outputStr = ""
    for i in inputStr:
        asciiVal = ord(i)
        if (47 < asciiVal < 60) or (asciiVal == 0) or 96 < asciiVal < 123 or (57 < asciiVal < 60) or (
                64 < asciiVal < 91) or asciiVal == 40 or asciiVal == 41 or asciiVal == 44 or asciiVal == 35:
            outputStr += i
        else:
            inputStr.replace(i, str(asciiVal))

            strAsciiVal = str(asciiVal)
            if len(strAsciiVal) > 2:
                outputStr += "ASC" + strAsciiVal
            elif len(strAsciiVal) > 1:
                outputStr += "ASC0" + strAsciiVal
            else:
                outputStr += "ASC00" + strAsciiVal

    return outputStr


def removeNodes(nodes):
    output = ''
    nodes = nodes.split(',')

    with open("upload.dot", "r") as text_file:
        for line in text_file:
            try:
                for n in nodes:
                    if line.__contains__(" " + n + "\n"):
                        raise Exception()
            except Exception:
                continue
            output += line

    print(output)
    with open("upload.dot", "w+") as text_file:
        text_file.write(output)


def newickToDot(newick):
    dotFomat = ParentheticalToDot.newickToActualLabels(newick)
    with open("upload.dot", "w+") as text_file:
        text_file.write(dotFomat)


def returnReducedDotFile(fileName):
    retainActualLabels2(fileName)

    dotFormat = ''
    for line in list(open('cExample1_m.dot')):
        if line.__contains__('{') or line.__contains__('}') or line.__contains__('->'):
            dotFormat += line
    return dotFormat.rstrip()

def checkTripletErrors(triplets):
    if len(triplets) == 0:
        return 401
    triplets_arr = triplets.split("\n")
    for i in range(len(triplets_arr)):
        line = triplets_arr[i].split(" ")
        print("line")
        print(line)
        if len(line) != 3 and i != len(triplets_arr) - 1:
            return 401
        '''
        for j in range(len(line)):
            if line[j].isnumeric() == False:
                return 401
        '''
    return 0

def retainActualLabelDot(fileName):
    dotFormat = ''

    for line in list(open(fileName)):
        line = re.sub(r"(1[0-9][0-9][0-9])", r"internal\1", line)

        dotFormat += line
        # if line.__contains__('{') or line.__contains__('}') or line.__contains__('->'):
        #     dotFormat += line

    with open('cExample1_m.dot', 'w+') as f:
        f.write(dotFormat)

def backBoneToTriplets():
    cmd = 'java -jar NewickToTriplet.jar < userTriplets.txt > NewickToTriplet.txt'
    os.system(cmd)
    userTriplets = set()
    with open("NewickToTriplet.txt") as f:
        contents = f.readlines()
    for line in contents:
        if "//" in line:
            continue
        currLine = line.strip().split()
        for i in range(len(currLine)):
            currLine[i] = int(currLine[i])
        userTriplets.add(tuple(currLine))
    return userTriplets
def retainActualLabels2(fileName):
    dotFormat = ''
    dictionary = {}

    for line in list(open(fileName)):
        temp = re.search(r'("[0-9]+)', line)
        if temp:
            actualName = temp.group(1)
            temp2 = re.search(r'(\d+[\s]\[)', line)
            fakeName = temp2.group(1)
            # print(found[1] + "  :  " + found2[:-1])

            dictionary[fakeName[:-1].strip()] = actualName[1]

    print(dictionary)
    # newLine = ''
    # for line in open(fileName):
    with open(fileName, 'r') as file:
        fileStr = file.read()

    for key, value in dictionary.items():
        # newLine = line.replace(key, value)
        fileStr = fileStr.replace("\n" + key + " ", "\n" + value + "Δ ")
        fileStr = fileStr.replace(" " + key + "\n", " " + value + "Δ\n")

    fileStr = fileStr.replace('Δ', '')
    dotFormat = fileStr

    with open('cExample1_m.dot', 'w+') as f:
        f.write(dotFormat)

    retainActualLabelDot('cExample1_m.dot')


if __name__ == '__main__':
    print("Hello")

    matrix = [[0 for x in range(3)] for y in range(3)]

    print(matrix)