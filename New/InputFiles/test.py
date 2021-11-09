import os
cmd = 'java -jar NewickToTriplet.jar < f.txt > NewickToTriplet.txt'
os.system(cmd)
userTriplets = set()
with open("NewickToTriplet.txt") as f:
    contents = f.readlines()
for line in contents:
    if "//" in line:
        continue
    userTriplets.add(tuple(line.strip().split()))
print(userTriplets)