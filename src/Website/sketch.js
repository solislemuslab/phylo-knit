var nodeNum = 0;
var nodeVal = [];
var nodesCheckedStr = "";
var threshold;
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
var newickFr = "";

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

// values for storing input data
var globalhydeFileData = "";
var originalNewick = "";

// zoom constants
var min_zoom = 0.1;
var max_zoom = 7;

// specify d3 elements
var zoom = d3.zoom().scaleExtent([min_zoom, max_zoom])
var fill = d3.scaleOrdinal(d3.schemeCategory20);
var force = d3.forceSimulation();

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
    var targetWidth = container.width();
    chart.attr("width", targetWidth);
    chart.attr("height", Math.round(targetWidth / aspect));
}).trigger("resize");

// this variable essentially instantiates the physics of d3's chart
// ...I think...
var simulation = d3
    .forceSimulation()
    .force(
        "link",
        d3
            .forceLink()
            .distance(100)
            .id(function (d) {
                return d.id;
            })
    )
    .force("charge", d3.forceManyBody().strength(-10))
    .force("collide", d3.forceCollide(50))
    .force("center", d3.forceCenter(width / 2, height / 2));


// Main function for generating the D3 graph
function createD3Graph(nodesRemoveArr, newCheckedArray, isRemoveSelected, isAddSelected) {
    // clear the current list of nodes
    // (semi-experimental, not sure how this will interact with existing code)
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

        // build the arrow.
        svg.append("svg:defs")
            .selectAll("marker")
            .data(["end"]) // Different link/path types can be defined here
            .enter()
            .append("svg:marker") // This section adds in the arrows
            .attr("id", String)
            .attr("viewBox", "10 10 10 10")
            .attr("refX", 15)
            .attr("refY", -0.5)
            .attr("markerWidth", 6)
            .attr("markerHeight", 6)
            .attr("orient", "auto")
            .attr("preserveAspectRatio", "xMinYMin meet")

            .append("svg:path")

            .append("div")
            .append("rect")
            .attr("d", "M0,-5L10,0L0,5");

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
            .attr("marker-end", "url(#end)");
        nodeNum = graph.nodes.length;

        var node = svg
            .append("g")
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
        // simulation = d3.forceSimulation(data['nodes'])
        //     .force('link', d3.forceLink(data.edges).id(function(n) {return n.id; }))
        // simulation.force("link").links(graph.links);
        simulation.force('link', d3.forceLink(graph.links).id(function(n) {return n.id; }))
        simulation.force('charge', d3.forceManyBody())
        simulation.force('center', d3.forceCenter(width / 2, height / 2));
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
    
    // if the user input is bad, quit the fxn. the `testUserInput` fxn will
    // provide the proper error message on its own
    if (testUserInput(selectedDropDown) > 0) {
        return;
    }

    // according to which input type is selected, push the input data to the server,
    // and then generate the Displayed Leaves box
    // each of the `pushXToServer(...)` functions will call `createD3Graph` if no errors occur
    if (selectedDropDown === "pf") {
        var parentheticalText = newickField.value;
        if (parentheticalText === "") {
            paraText = document.getElementsByClassName("text")[0].innerHTML;
            console.log("paraText");
            console.log(paraText);
            pushParentheticalToServer(paraText);
        } else {
            pushParentheticalToServer(parentheticalText);
        }
    } else if (selectedDropDown === "HYDE format") {
        threshold = document.getElementById("textThreshold").value;
        var parentheticalText = newickField.value;      //optional backbone
        console.log("parenthetical text input is " + parentheticalText);
        if (parentheticalText === "") {
            parentheticalText = "";
        }
        pushHydeToServer(globalhydeFileData, threshold, parentheticalText);
    } else if (selectedDropDown == "Triplets") {
        paraText = document.getElementsByClassName("text")[0].innerHTML;
        console.log(paraText)
        pushStringToServer(paraText);
        document.getElementById("graph").dispatchEvent(new MouseEvent("click"));
    }
    createboxes();
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
    if (originalNewick.length > 0){
        getLeafUpdate(originalNewick,uncheckedNodes)

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