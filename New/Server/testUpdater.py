
from ete3 import Tree


connections = ["internal1000 internal1001",
"internal1000 2",
"internal1001 internal1002",
"internal1001 6",
"internal1002 internal1003",
"internal1002 5",
"internal1003 4"]

t = Tree.from_parent_child_table([line.split() for line in connections] )
print (t.write())