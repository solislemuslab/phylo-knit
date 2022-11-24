var nodeNum = 0;
var nodeVal = [];
var nodesCheckedStr = "";
var paraText = "";
var reg1000P = new RegExp("internal([0-9]{4})");
var regInternalHybrid = new RegExp("internal[a-zA-Z]");
var reqStatus;
var regHash = new RegExp("Hash[A-Za-z]+");
var targetCounts = new Map();
var paraDiv;
var removeNodeBool = false;
var totalLeafNodes = [];
var trackRemovedNodes = [];
var trackRemovedLinks = [];

// Page elements for later reference
var btnUpdateNet = document.getElementById("updateNetwork");
var textThresh = document.getElementById("textThreshold");
var divText = document.getElementById("textDiv");
var symbolElement = document.getElementById("symb");
var newickField = document.getElementById("parenthetical");
var createNetworkSelector = document.getElementById("createNetwork");
var selectbutton = document.getElementById("transfer_reason");
var refresher = document.getElementById("refresh");
var displayedLeaves = document.getElementById("displayed-leaves");

// zoom constants
var min_zoom = 0.1;
var max_zoom = 7;

// specify d3 elements
var fill = d3.scaleOrdinal(d3.schemeCategory20);
var force = d3.forceSimulation();

// make sure we can use the file the user selected when they select a file
const fileInput = document.getElementById("file");
var currFile;          // the file currently populating the input box
var fileText;          // the text of the last file read
fileInput.addEventListener("change", saveFile, false);
function saveFile() {
    currFile = this.files[0];
    console.log(currFile);
}

// 
var svg = d3.select("svg"),
    width = +svg.attr("width"),
    height = +svg.attr("height");

// this is the chart where nodes and links are drawn, contained w/in `svg`
var chart = $("#chartId"),
    aspect = chart.width() / chart.height(),
    container = chart.parent(); 

// we want to resize the chart whenever the window is resized
$(window).on("resize", function () {
    var targetWidth = container.width() * 0.8;
    chart.attr("width", targetWidth);
    chart.attr("height", Math.round(targetWidth / aspect));
}).trigger("resize");

// this variable essentially instantiates the physics of d3's chart
var simulation = d3.forceSimulation()


// Main function for generating the D3 graph
function createD3Graph(nodesRemoveArr, newCheckedArray, isRemoveSelected, isAddSelected) {
    // clear the current list of nodes
    nodeVal = [];

    // if the chart is already populated, clear it.
    if (!isAddSelected) {
        removeGraph();
    }

    document.getElementById("loader").style.visibility = "hidden";
    selectbutton.disabled = true;
    refresher.style.visibility = "visible";
    refresher.disabled = false;

    selectbutton.disabled = true;
    d3.dot("http://localhost:5001/readDot", function (error, graph) {
        if (error) {
            alert(error);
        }
        console.log("graph prints");
        console.log(graph);

        for (var i = 0; i < graph.links.length; i++) {
            if (typeof targetCounts.get(graph.links[i].target) === "undefined") {
                temp = [graph.links[i].source];
                targetCounts.set(graph.links[i].target, temp);
            } else if (targetCounts
                      .get(graph.links[i].target)
                      .includes(graph.links[i].source)
            ) {
                continue;
            } else {
                targetCounts
                    .get(graph.links[i].target)
                    .push(graph.links[i].source);
            }
        }
        console.log(targetCounts);

        if (isRemoveSelected) {
            for (let i = 0; i < graph.nodes.length; i++) {
                for (let j = 0; j < nodesRemoveArr.length; j++) {
                    if (graph.nodes[i].id === nodesRemoveArr[j]) {
                        trackRemovedNodes.push(graph.nodes[i]);
                        console.log("remove");
                        console.log(graph.nodes[i])
                        graph.nodes.splice(i, 1); //remove 1 item at index i
                    }
                }
            }
            for (let i = 0; i < graph.links.length; i++) {
                for (let j = 0; j < nodesRemoveArr.length; j++) {
                    if (graph.links[i].target === nodesRemoveArr[j]) {
                        trackRemovedLinks.push(graph.links[i]);
                        graph.links.splice(i, 1); //remove 1 item at index i
                    }
                }
            }

            if (isAddSelected) {
                for (let i = 0; i < trackRemovedNodes.length; i++) {
                    for (let j = 0; j < newCheckedArray.length; j++) {
                        if (trackRemovedNodes[i].id === newCheckedArray[j]) {
                            console.log("add");
                            console.log(trackRemovedNodes[i]);
                            graph.links.add(trackRemovedNodes[i]); //remove 1 item at index i
                        }
                    }
                }
                for (let i = 0; i < trackRemovedLinks.length; i++) {
                    for (let j = 0; j < newCheckedArray.length; j++) {
                        if (
                            trackRemovedLinks[i].target === newCheckedArray[j]
                        ) {
                            graph.links.add(trackRemovedLinks[i]); //remove 1 item at index i
                        }
                    }
                }
            }
        }
        console.log("GRAPH HERE")
        console.log(graph)

        // Get source and target updates
        var targetVals = ""
        var sourceVals = ""
        
        for(var i = 0 ; i < graph.links.length; i++){
            sourceVals = sourceVals + " " + graph.links[i].source
            targetVals = targetVals + " " + graph.links[i].target
        }

        // Pass all data variables through here for leaf file update
       
        console.log("SOURCEVALS-TARGETVALS")
        console.log(sourceVals)
        console.log(targetVals)
        //getLeafUpdate(sourceVals,targetVals);

        var path = svg
            .append("svg:g")
            .attr("class", "links")
            .selectAll("path")
            .data(graph.links)
            .enter()
            .append("svg:path")
            .attr("marker-end", "url(#end)")
            .attr("fill", "none")
            .attr("stroke", "black");
        nodeNum = graph.nodes.length;

        var node = svg
            .append("g")
            .attr("class", "nodes")
            .selectAll("circle")
            .data(graph.nodes)
            .enter()
            .append("g");

        node.append("circle")
            .attr("r", function (d) {
                var valueOfNode = d.id.toString();
                if (!reg1000P.test(valueOfNode))
                    nodeVal.push(valueOfNode);
                return (!reg1000P.test(valueOfNode) ||
                    valueOfNode === "internal1000") &&
                    !regInternalHybrid.test(valueOfNode)
                    ? 30
                    : 30;
            })

            .style("fill", function (d) {
                if (removeNodeBool === false) {
                    createboxes();
                    removeNodeBool = true;
                }
                var valueOfNode = d.id.toString();
                if (typeof targetCounts.get(valueOfNode) != "undefined") {
                    if (reg1000P.test(valueOfNode)) {
                        if (targetCounts.get(valueOfNode).length === 2) {
                            return "yellow";
                        }
                    }

                }
                return regHash.test(valueOfNode)
                    ? "green"
                    : valueOfNode === "internal1000"
                    ? "red"
                    : reg1000P.test(valueOfNode) ||
                      regInternalHybrid.test(valueOfNode)
                    ? "gray"
                    : "blue";
                
            })
            .call(
                d3
                    .drag()
                    .on("start", dragstarted)
                    .on("drag", dragged)
                    .on("end", dragended)
            );
        node.append("text")
            .attr("x", 12)
            .attr("dy", ".35em")
            .text(function (d) {
                var valueOfNode = d.id.toString();
                return d.id;
            });

        simulation.nodes(graph.nodes).on("tick", ticked);
        console.log("link check")
        console.log(graph.links)

        // These functions set of the physics between nodes
        simulation.force('link', d3.forceLink(graph.links).distance(150).id(n => n.id))     // edges
        simulation.force('charge', d3.forceManyBody().strength(0));                         // node repulsion/attraction
        simulation.force('center', d3.forceCenter(width / 2, height / 2));                  // network centering
        simulation.force('collision', d3.forceCollide().radius(25));                        // stop collisions

        let linkGen = d3
            .linkVertical()
            .x(function (d) {
                return d.x;
            })
            .y(function (d) {
                return d.y;
            });

        var linkRad = d3
            .linkRadial()
            .angle(function (d) {
                return d.x;
            })
            .radius(function (d) {
                return d.y;
            });

        function ticked() {
            path.attr("d", function (d) {
                return (
                    "M" +
                    d.source.x +
                    "," +
                    d.source.y +
                    "L" +
                    d.target.x +
                    "," +
                    d.target.y
                );
            });
            node.attr("transform", function (d) {
                return "translate(" + d.x + "," + d.y + ")";
            });
        }
    });
}

// Some event handlers
// -------------------------------------------------------
function dragstarted(d) {
    if (!d3.event.active) simulation.alphaTarget(0.3).restart();
    d.fx = d.x;
    d.fy = d.y;

    console.log("DRAGSTARTED");
    console.log(d);
}

function dragged(d) {
    d.fx = d3.event.x;
    d.fy = d3.event.y;
}

function dragended(d) {
    if (!d3.event.active) simulation.alphaTarget(0);
    d.fx = null;
    d.fy = null;
}

d3.select('svg').call(d3.zoom().on('zoom', function() {
        d3.select('svg g.links').attr('transform', d3.event.transform);
        d3.select('svg g.nodes').attr('transform', d3.event.transform);
    }))
// -------------------------------------------------------



// ------------------ End of D3 code ---------------------

// this function adjusts the left-side buttons when the user chooses a different input type
function selectInputType(val) {
    selectedDropDown = val;
    if (val === "HYDE format") {
        document.getElementById("instruct").innerHTML =
            "Please upload a HYDE format file and provide threshold";
        removeGraph();
        createNetworkSelector.style.visibility = "visible";
        createNetworkSelector.disabled = false;
        textThresh.style.visibility = "visible";
        divText.style.visibility ="visible";
        symbolElement.style.visibility = "visible";
        newickField.style.visibility = "visible"; // for optional backbone tree
        let fileDiv = document.getElementById("file");
        if (fileDiv.style.display === "none") {
            fileDiv.style.display = "block";
        } else {
            fileDiv.style.visibility = "visible";
        }
    } else if (val === "Triplets") {
        document.getElementById("instruct").innerHTML =
            "Please upload a triplet format file";
        removeGraph();
        newickField.style.visibility = "hidden";
        textThresh.style.visibility = "hidden";
        divText.style.visibility = "hidden";
        let fileDiv = document.getElementById("file");
        createNetworkSelector.disabled = false;
        if (fileDiv.style.display === "none") {
            fileDiv.style.display = "block";
        } else {
            fileDiv.style.visibility = "visible";
        }
    } else if (val === "pf") {
        document.getElementById("instruct").innerHTML =
            "Please upload a file in Newick format OR type an expression";
        removeGraph();
        textThresh.style.visibility = "hidden";
        divText.style.visibility = "hidden";
        newickField.style.visibility = "visible";
        createNetworkSelector.style.visibility = "visible";
        let fileDiv = document.getElementById("file");
        fileDiv.style.visibility = "visible";
        createNetworkSelector.disabled = false;
    }
}

// Populates the "Displayed Leaves" box
function createboxes() {
    // Enable the create network button.
    // Why was this disabled up to this point to begin with?
    // Who knows.
    createNetworkSelector.disabled = false;
    
    // Clear the box, except for its title.
    var childList = displayedLeaves.children;
    for(var i = childList.length-1; i>1; i--) {
        displayedLeaves.removeChild(childList[i]);
    }
    
    totalLeafNodes = [];
    btnUpdateNet.disabled = false;
    nodeVal.forEach(function (element) {
        console.log("element: " + element);

        linebreak = document.createElement("hr");

        var checkbox = document.createElement("input");
        checkbox.type = "checkbox";
        checkbox.name = element;
        checkbox.id = element;
        checkbox.value = element;
        checkbox.checked = true;

        paraDiv = document.createElement("p");
        var text = document.createTextNode("" + element);
        paraDiv.appendChild(text);
        if (!paraDiv.textContent.includes("Hash")) {
            totalLeafNodes.push(paraDiv.textContent);
        }
        if (!paraDiv.textContent.includes("Hash") && !paraDiv.textContent.includes("internal")) {
            displayedLeaves.appendChild(linebreak);
            displayedLeaves.appendChild(checkbox);
            displayedLeaves.appendChild(paraDiv);
        }
    });
}


// called when the "Create Network" button is pressed;
// does all the calls that populate the D3 graph
function onClickCreateNetwork() {
    var svg = d3.select("body").select("svg")

    // don't let the user press the create network button again while we're working...
    createNetworkSelector.disabled = true;

    // show the loading icon and clear out any previous warning messages
    document.getElementById("loader").style.visibility = "visible";
    document.getElementById("instruct").innerHTML = "";
    
    // ------------------------------------------------------------------------------------------
    // according to which input type is selected, push the input data to the server,
    // and then generate the Displayed Leaves box
    // each of the `pushXToServer(...)` functions will call `createD3Graph` if no errors occur
    // ------------------------------------------------------------------------------------------
    // if we're reading parenthetical text, that's easy; do that and leave.
    if(selectedDropDown == "pf" && newickField.value != "") {
        pushParentheticalToServer(newickField.value);
        return;
    }
    
    // otherwise, we need a file reader
    var fr = new FileReader();
    fr.onload = function() {
        // read the text and get rid of carriage returns
        fileText = fr.result.replaceAll("\r", "");
        
        // if the user input is bad, quit the fxn. the `testUserInput` fxn will
        // provide the proper error message on its own
        if (testUserInput(selectedDropDown) > 0) {
            return;
        }
        
        // process data w/ the appropriate fxn
        if(selectedDropDown == "pf") {
            console.log("----");
            console.log(fileText);
            console.log("----");
            pushParentheticalToServer(fileText);
        } else if(selectedDropDown == "HYDE format") {
            pushHydeToServer(fileText, textThresh.value, newickField.value);
        } else {
            // triplets
            pushTripletsToServer(fileText);
        }

        // populate the leaf box
        createboxes();
    }
    fr.readAsText(currFile);
}

// changes the root node; not actually called anywhere yet.
function changeRootAction() {
    var flag = inputForFlag.value();
    var tripRoot = input2.value();
    pushChangeRootToServer(flag, tripRoot);
}

// called when "Update Network" is pressed; only selected leaves are kept in the network
function removeNodesAction() {
    nodesCheckedStr = nodesCheckedStr.substr(0, nodesCheckedStr.length - 1);
    console.log(nodesCheckedStr);
    var newCheckedNodes = nodesCheckedStr.split(",");
    var uncheckedNodes = [];
    var checkedNodes = [];
    for (let i = 0; i < totalLeafNodes.length; i++) {
        var test = document.getElementById(totalLeafNodes[i]);
        console.log(test.checked);
        if (!test.checked) {
            uncheckedNodes.push(totalLeafNodes[i]);
        } else {
            checkedNodes.push(totalLeafNodes[i]);
        }
    }
    for (let i = 0; i < newCheckedNodes.length; i++) {
        var test = document.getElementById(newCheckedNodes[i]);

        if (newCheckedNodes[i] == "" || !test.checked) {
            newCheckedNodes.splice(i, 1);
        }
    }
    uniqueArray = newCheckedNodes.filter(function (item, pos, self) {
        return self.indexOf(item) == pos;
    });
    console.log("unchecked Nodes1: " + uncheckedNodes);
    console.log("checked Nodes1: " + uniqueArray);
    if (newickField.value.length > 0){
        getLeafUpdate(newickField.value,uncheckedNodes)

    }
    createD3Graph(uncheckedNodes, uniqueArray, true, false);
}


// clear the chart
function removeGraph() {
    $("#chartId").empty();
}

// removes unchecked leaves before the new visualization is created
// called from within the removeNodesAction() function, which is called
// when the "Update Network" button is pressed
function getLeafUpdate(origNewick,removedVals) {
    var data = JSON.stringify({
        source: origNewick,
        target: removedVals
    });
    flag = 0;
    var request = new XMLHttpRequest();
    request.open("POST", "http://127.0.0.1:5001/updateNewick/");
    request.setRequestHeader("Content-Type", "application/json");
    request.addEventListener("readystatechange", processRequest, false);
    request.send(data);
    console.log(data);

    function processRequest(e) {}
}