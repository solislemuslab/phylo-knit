import re
import os
def reader(filepath='cExample1.dot'):
    #filepath = 'cExample1.dot'
    newick = ""
    with open(filepath) as fp:
        line = fp.readline()
        cnt = 1
        while line:
            if "eNewick output" in line.strip():
                r = str(line.strip())
                r = r.split(":")
                #r[len(r)-1] = r[len(r)-1].replace(";","")
                newick = r[len(r)-1]
                break

            line = fp.readline()
            cnt += 1
    return newick