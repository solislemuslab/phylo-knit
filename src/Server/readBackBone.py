import os


def backBoneToTriplets():
    cmd = 'java -jar NewickToTriplet.jar < userTriplets.txt > NewickToTriplet.txt'
    os.system(cmd)
    userTriplets = set()
    with open("NewickToTriplet.txt") as f:
        contents = f.readlines()
    for line in contents:
        if "//" in line:
            continue
        userTriplets.add(tuple(line.strip().split()))
    print(userTriplets)
backBoneToTriplets()