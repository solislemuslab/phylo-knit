using PhyloNetworks


x = " "
open("tester.txt") do f
 
    # line_number
    line = 0  
    
    # read until end of file
    while ! eof(f) 
   
       # read a new / next line for every iteration          
       s = readline(f)    
       u = split(s," ")
       println(u)
       tree = u[2] # some tree in extended newick format, I think it should be the string taken from the original output of Lev1athan

       net = readTopology(tree) # Should be used instead of level 1; readTopology is more generic, and stores it as a hybrid network

       for i in 3:length(u)
            PhyloNetworks.deleteleaf!(net, u[i], keeporiginalroot=true) # now, net is updated without the specified leaf ("1")
    
       end
       curr_newick = writeTopology(net)
       io = open("hereTest.txt", "w+");
       truncate(io,0)
       write(io, curr_newick);


    end
   
end

