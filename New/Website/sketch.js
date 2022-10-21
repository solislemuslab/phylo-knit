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
var btnUpdateNet = document.getElementById("updateNetwork");
var textThresh = document.getElementById("textThreshold");
var divText = document.getElementById("textDiv");
var symbolElement = document.getElementById("symb");
var newickField = document.getElementById("parenthetical");
var createNetworkSelector = document.getElementById("createNetwork");
var parentheticalSelector = document.getElementById("parenthetical");
var selectbutton = document.getElementById("transfer_reason");
var refresher = document.getElementById("refresh");
var globalhydeFileData = "";
var originalNewick = "";

// initialize variables
function varSetup(){
    btnUpdateNet.disabled = true;
    textThresh.style.visibility = "hidden";
    divText.style.visibility = "hidden";
    symbolElement.style.visibility = "hidden";
    newickField.style.visibility = "hidden";
    createNetworkSelector.disabled = true;
    parentheticalSelector.style.visibility = "hidden";
    refresher.disabled = true;
}

function formdata() {
    var firstname1 = document.getElementById("rNodes").value;
    alert(firstname1);
}

var chart = $("#chartId"),
    aspect = chart.width() / chart.height(),
    container = chart.parent();
$(window)
    .on("resize", function () {
        var targetWidth = container.width();
        chart.attr("width", targetWidth);
        chart.attr("height", Math.round(targetWidth / aspect));
    })
    .trigger("resize");

var svg = d3.select("svg"),
    width = +svg.attr("width"),
    height = +svg.attr("height");

var colorD3 = d3.scaleOrdinal(d3.schemeCategory20);

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

function createD3Graph(
    nodesRemoveArr,
    newCheckedArray,
    isRemoveSelected,
    isAddSelected
) {
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
            if (
                typeof targetCounts.get(graph.links[i].target) === "undefined"
            ) {
                temp = [graph.links[i].source];
                targetCounts.set(graph.links[i].target, temp);
            } else if (
                targetCounts
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

//End of D3 code
var bool = 0;
var selectedDropDown = "Triplets";

// creates choose file button
function setup() {
    noCanvas();
    inp = createFileInput(gotFile);
    inp.position(400, 80);
    inp.addClass("btn  btn-tertiary  btn-round chooseButton");
    inp.attribute("id", "file");
    textAlign(CENTER);
    textSize(50);
}

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
        // backboneNewick.style.visibility = "visible";
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
        parentheticalSelector.style.visibility = "visible";
        createNetworkSelector.style.visibility = "visible";
        let fileDiv = document.getElementById("file");
        fileDiv.style.visibility = "visible";
        createNetworkSelector.disabled = false;
    }
}

function simulateClick(x, y) {
    jQuery(document.elementFromPoint(315, 205)).click();
}

function createboxes() {
    createNetworkSelector.disabled = true;
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

        checkbox.onclick = checking;
        paraDiv = document.createElement("p");
        var text = document.createTextNode("" + element);
        paraDiv.appendChild(text);
        if (!paraDiv.textContent.includes("Hash")) {
            totalLeafNodes.push(paraDiv.textContent);
        }
        if (
            !paraDiv.textContent.includes("Hash") &&
            !paraDiv.textContent.includes("internal")
        ) {
            document.getElementById("placeholder").appendChild(checkbox);
            document.getElementById("placeholder").appendChild(paraDiv);
            document.getElementById("placeholder").appendChild(linebreak);
        }

    });
}

function checking() {
    if (this.checked) {
        nodesCheckedStr += this.id.toString() + ",";
    }
    // alert(nodesCheckedStr);
}

function onClickCreateNetwork() {
var svg = d3.select("body").select("svg")
    parentheticalSelector.disabled = true;
    createNetworkSelector.disabled = true;
    document.getElementById("loader").style.visibility = "visible";
    document.getElementById("instruct").innerHTML = "";
    if (TestUserInput(selectedDropDown) > 0) {
        return;
    }
    if (selectedDropDown === "pf") {
        var parentheticalText = document.getElementById("parenthetical").value;
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
        pushHydeToServer(globalhydeFileData, threshold);
    } else if (selectedDropDown == "Triplets") {
        paraText = document.getElementsByClassName("text")[0].innerHTML;
        console.log(paraText)
        pushStringToServer(paraText);
        document.getElementById("graph").dispatchEvent(new MouseEvent("click"));
    }
    createboxes();
}

function changeRootAction() {
    var flag = inputForFlag.value();
    var tripRoot = input2.value();
    pushChangeRootToServer(flag, tripRoot);
}

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

function addNodesAction() {
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
    createD3Graph(uncheckedNodes, uniqueArray, false, true);
}

function removeGraph() {
    $("#chartId").empty();
}

function refreshGraph() {
    createD3Graph();
}

// file is a p5.File object that has metadata, and the file's contents
function gotFile(file) {

    refresher.disabled = false;
    selectbutton.disabled = true;
    refresher.disabled = false;
    var fileDiv = createDiv(
        file.name +
            " " +
            file.type +
            " " +
            file.subtype +
            " " +
            file.size +
            " bytes"
    );
    fileDiv.style.visibility = "hidden";
    fileDiv.class("files");
    var hideinfo = document.getElementsByClassName("files");
    if (file.type === "image") {
        alert("image not accepted");
    } else if (file.type === "text") {
        if (selectedDropDown === "HYDE format") {
            var par = createP(file.data);
            par.class("text");
            var texts = selectAll(".text");
            paraText = document.getElementsByClassName("text")[0].innerHTML;
            globalhydeFileData = paraText;
        } else if (selectedDropDown == "Triplets") {
            // Make a paragraph of text
            var par = createP(file.data);
            par.class("text");
            var texts = selectAll(".text");
            var paraText = document.getElementsByClassName("text").innerHTML;
            // paraText = document.getElementsByClassName('text')[0].innerHTML;

            // pushStringToServer(paraText);
        } else if (selectedDropDown == "pf") {
            // Make a paragraph of text
            var par = createP(file.data);
            par.class("text");
            var texts = selectAll(".text");
            var paraText = document.getElementsByClassName("text").innerHTML;
        }
    }
    var boxnums = document.getElementsByClassName("boxText1");
}


// remove unchecked leaves and create new visualization
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

    function processRequest(e) {
        console.log("check ");
        // var x = JSON.parse(request.responseText);
        // newickFr = x.newick

        //alert(e);
        // document.write("This is Working <p>");
       
   

}
}



function pushHydeToServer(hydeInput, thresh) {
    var data = JSON.stringify({
        text: hydeInput,
    });
    flag = 0;
    var request = new XMLHttpRequest();
    request.open("POST", "http://127.0.0.1:5001/uploadHyde/" + thresh);
    request.setRequestHeader("Content-Type", "application/json");
    request.addEventListener("readystatechange", processRequest, false);
    request.send(data);
    console.log(data);

    function processRequest(e) {
        console.log("check ");
        var x = JSON.parse(request.responseText);
        originalNewick = x.newick;
        newickFr = originalNewick; 

        //alert(e);
        // document.write("This is Working <p>");
        if (request.readyState === 4 && request.status === 200) {
            document.getElementById("dwn-btn").style.visibility = "visible";
            document.getElementById("dwn-div").style.visibility = "visible";
            document.getElementById("downloadPng").style.visibility = "visible";
            createD3Graph();
        } else if (request.status === 401) {
            reqStatus = request.status;
            document.getElementById("loader").style.visibility = "hidden";
            document.getElementById("instruct").innerHTML =
                "Error in file input please try uploading a file in the correct HYDE format";
        }
    }
    paraT = document.getElementsByClassName("text")[0].id = "nodeTxt";
    var tempNodeText = document.getElementById("nodeTxt");
    tempNodeText.remove();

}

// creates parenthetical 
function pushParentheticalToServer(parenthetical) {
    var data = JSON.stringify({
        text: parenthetical,
    });

    var request = new XMLHttpRequest();
    request.open("POST", "http://127.0.0.1:5001/uploadNewick/");
    request.setRequestHeader("Content-Type", "application/json");
    request.addEventListener("readystatechange", processRequest, false);
    request.send(data);

    function processRequest(e) {
        if (request.readyState === 4 && request.status === 200) {
            var x = JSON.parse(request.responseText);
            newickFr = x.newick    
            document.getElementById("downloadPng").style.visibility = "visible"

            createD3Graph();
            var x = JSON.parse(request.responseText);
            newickFr = x.newick
    
        } else if (request.readyState === 4) {
        }
    }
}

function pushStringToServer(triplets) {
    var data = JSON.stringify({
        text: triplets,
    });

    var request = new XMLHttpRequest();
    request.open("POST", "http://127.0.0.1:5001/upload/");
    request.setRequestHeader("Content-Type", "application/json");
    request.addEventListener("readystatechange", processRequest, false);
    request.send(data);

    function processRequest(e) {
        if (request.readyState === 4 && request.status === 200) {
            var x = JSON.parse(request.responseText);
            newickFr = x.newick
    
            document.getElementById("dwn-btn").style.visibility = "visible";
            document.getElementById("dwn-div").style.visibility = "visible";

            document.getElementById("downloadPng").style.visibility = "visible";
            createD3Graph();
        } else if (request.status === 401) {
            reqStatus = request.status;
            document.getElementById("loader").style.visibility = "hidden";
            document.getElementById("instruct").innerHTML =
                "Error in file input please try uploading a file in the correct triplet format";

            // document.write("<p>Error : " + request.status + "," + request.statusText);
        }
    }
}

function pushLeavesToServer(leaves) {
    var data = JSON.stringify({
        text: leaves,
    });

    var request = new XMLHttpRequest();
    request.open("POST", "http://127.0.0.1:5001/uploadLeaves/");
    request.setRequestHeader("Content-Type", "application/json");
    request.addEventListener("readystatechange", processRequest, false);
    request.send(data);

    function processRequest(e) {
        if (request.readyState === 4 && request.status === 200) {
            createD3Graph();
        } else if (request.readyState == 4) {
        }
    }
}

function pushChangeRootToServer(flag, tripRoot) {
    var data = JSON.stringify({
        text: flag,
    });
    var request = new XMLHttpRequest();
    request.open("POST", "http://127.0.0.1:5000/changeRoot/" + tripRoot);
    request.setRequestHeader("Content-Type", "application/json");
    request.addEventListener("readystatechange", processRequest, false);
    request.send(data);

    function processRequest(e) {
        if (request.readyState === 4 && request.status === 200) {
            var response = request.responseText;
            var img = createImg();
            img.class("thumb");
            document
                .getElementsByClassName("thumb")[0]
                .setAttribute("src", "data:image/png;base64," + response);
        } else if (request.readyState === 4) {
        }
    }
}

/** 
 * This method is responsible to test the inputs of the user and return errors on the website.It checks things such as missing input values and return personalized error messages.
 * This method is a front-end check (values inputted or files inputted) and the back-end user input testing relates to files format/standards
 * @param formatType : Chosen file format (triplet,parenthetical,Hyde)
 */
function TestUserInput(formatType) {
    var errMsg = "";
    var errors = 0;
    if (formatType === "HYDE format") {
        var threshold = document.getElementById("textThreshold").value;
        var hydeData = globalhydeFileData;

        if (threshold.length === 0) {
            errMsg =
                "The Threshold value is missing for the Hyde Format Please try again ";
            errors = 1;
        }
        if (isNaN(threshold)) {
            errMsg = 
                "The p-value is not a number. Please try again.";
            errors = 1;
        }
        if (hydeData === undefined || typeof hydeData === "undefined" || hydeData.length === 0) {
            errMsg =
                "The Hyde format file was not uploaded. Please choose a hyde file and try again";
            errors = 1;
        }
    }
    if (formatType === "Triplets"){
        var tripData = document.getElementsByClassName("text")[0];
        console.log("reached over here ")
        if (tripData === undefined|| tripData.innerHTML === undefined || typeof tripData === "undefined" || tripData.innerHTML.length === 0) {
            errMsg =
                "The Triplet format file was not uploaded. Please choose a Triplet file and try again";
            errors = 1;
        }
    }
    if (formatType === "pf"){

            var pText = document.getElementById("parenthetical").value;
            var parData = document.getElementsByClassName("text")[0];

            if (pText === "" && (parData=== undefined|| parData.innerHTML === undefined || typeof parData === "undefined" || parData.innerHTML.length === 0 )) {
                errMsg =
                "Parenthical format was not found. Please choose a Parenthical file or enter Newick format and try again";
                errors = 1;
            }
        
    }
    if (errors > 0) {
        document.getElementById("loader").style.visibility = "hidden";
        document.getElementById("instruct").innerHTML = errMsg;
        return errors;
    }
}
function download(filename, text) {
    var element = document.createElement('a');
    element.setAttribute('href', 'data:text/plain;charset=utf-8,' + encodeURIComponent(text));
    element.setAttribute('download', filename);

    element.style.display = 'none';
    document.body.appendChild(element);

    element.click();

    document.body.removeChild(element);
}
varSetup();

document.getElementById("dwn-btn").addEventListener("click", function(){
    var text = newickFr;
    var filename = "Newick.txt";
    download(filename, text);
}, false);

// document.getElementsByClassName("text")[0].id = "nodeTxt";
// paraGraph = document.getElementById("nodeTxt");
// paraGraph.remove();