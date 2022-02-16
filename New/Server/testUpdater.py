
from ete3 import Tree

t = Tree.from_parent_child_table([line.split() for line in open("tester.txt")] )
print (t.write())