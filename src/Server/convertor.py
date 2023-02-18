import re
import os

# def dotToNewick(dotString):
#     print(dotString)
#     #filepath = 'cExample1.dot'
#     newick = ""

#     for line in dotString.split("\n"):
#         if "eNewick output" in line.strip():
#             r = str(line.strip())
#             r = r.split(":")
#             #r[len(r)-1] = r[len(r)-1].replace(";","")
#             newick = r[len(r)-1]
#             break

#     return newick