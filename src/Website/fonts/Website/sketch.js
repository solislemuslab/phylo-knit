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
// As with JSON, use the Fetch API & ES6

//const { testHyde } = require("../testUserInput");

var removeNodeBool = false;
var totalLeafNodes = [];
var trackRemovedNodes = [];
var trackRemovedLinks = [];
var newickFr = ""

var btnUpdateNet = document.getElementById("updateNetwork");
// btnUpdateNet.style.visibility = "hidden";
btnUpdateNet.disabled = true;

var e = document.getElementById("textThreshold");
e.style.visibility = "hidden";
var m = document.getElementById("symb");
m.style.visibility = "hidden";

var newickField = document.getElementById("parenthetical");
newickField.style.visibility = "hidden";

var createNetworkSelector = document.getElementById("createNetwork");
// createNetworkSelector.style.visibility = "hidden";
createNetworkSelector.disabled = true;
var parentheticalSelector = document.getElementById("parenthetical");
parentheticalSelector.style.visibility = "hidden";

var selectbutton = document.getElementById("transfer_reason");

var refresher = document.getElementById("refresh");
// refresher.style.visibility="hidden";
refresher.disabled = true;
var globalhydeFileData = "";

function formdata() {
    var firstname1 = document.getElementById("rNodes").value;

    // document.writeln(firstname1 + "<br>");
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

// var lineD3 = d3.line();
// .curve(d3.curveCatmullRom.alpha(0.5));

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

        // add the links and the arrows
        var path = svg
            .append("svg:g")
            .attr("class", "links")
            .selectAll("path")
            .data(graph.links)
            .enter()
            .append("svg:path")
            //    .attr("class", function(d) { return "link " + d.type; })
            .attr("marker-end", "url(#end)");
        // alert(Object.values(graph.nodes.name));
        // alert(graph.nodes);
        nodeNum = graph.nodes.length;

        var node = svg
            .append("g")
            .selectAll("circle")
            .data(graph.nodes)
            .enter()
            .append("g");

        node.append("circle")
            //.attr("r", 10)
            .attr("r", function (d) {
                var valueOfNode = d.id.toString();
                if (!reg1000P.test(valueOfNode))
                    // if (valueOfNode < 1000)
                    nodeVal.push(valueOfNode);
                // return (parseInt(d.id.toString()) <= 1000) ? 10 : 5;
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
                // return (parseInt(d.id.toString()) < 1000) ? "blue" : (parseInt(d.id.toString()) === 1000) ? "red" : "gray";
                var valueOfNode = d.id.toString();
                if (typeof targetCounts.get(valueOfNode) != "undefined") {
                    if (reg1000P.test(valueOfNode)) {
                        if (targetCounts.get(valueOfNode).length === 2) {
                            return "yellow";
                        }
                    }
                    // if (targetCounts.get(valueOfNode).length === 2) {
                    //     return "yellow"
                    // }
                }
                //else{
                return regHash.test(valueOfNode)
                    ? "green"
                    : valueOfNode === "internal1000"
                    ? "red"
                    : reg1000P.test(valueOfNode) ||
                      regInternalHybrid.test(valueOfNode)
                    ? "gray"
                    : "blue";
                //}
            })
            //.attr("fill", function(d) { return color(d.group); })
            .call(
                d3
                    .drag()
                    .on("start", dragstarted)
                    .on("drag", dragged)
                    .on("end", dragended)
            );

        // alert(nodeVal);
        // add the text
        node.append("text")
            .attr("x", 12)
            .attr("dy", ".35em")
            .text(function (d) {
                // return d.id;
                var valueOfNode = d.id.toString();
                // return (!reg1000P.test(valueOfNode)) ? d.id : "";
                // return (parseInt(d.id.toString()) < 1000) ? d.id : "";
                return d.id;
            });

        simulation.nodes(graph.nodes).on("tick", ticked);

        simulation.force("link").links(graph.links);

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

    // document.elementFromPoint(x, y).click();///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
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

function setup() {
    noCanvas();
    // createFileInput creates a button in the window
    // that can be used to select files
    // The first argument is the callback function
    // The 'multiple' flag allows more than one file to be selected
    // elt = document.getElementById("here");
    inp = createFileInput(gotFile, "multiple");
    inp.position(400, 40);
    inp.addClass("chooseButton");
    inp.attribute("id", "file");
    // inp.parent(elt)

    // inpputForHyde = createFileInput(gotHydeFile, 'multiple');

    textAlign(CENTER);
    textSize(50);
}

function selectInputType(val) {
    selectedDropDown = val;

    // location.reload();
    if (val === "HYDE format") {
        document.getElementById("instruct").innerHTML =
            "Please upload a HYDE format file and provide threshold";
        removeGraph();
        // document.getElementById("parenthetical").style.visibility ="hidden";
        // location.reload(true);
        // d.style.visibility = "visible";

        createNetworkSelector.style.visibility = "visible";
        createNetworkSelector.disabled = false;
        e.style.visibility = "visible";
        m.style.visibility = "visible";
        newickField.style.visibility = "hidden";
        let x = document.getElementById("file");
        if (x.style.display === "none") {
            x.style.display = "block";
        } else {
            x.style.visibility = "visible";
        }
    } else if (val === "Triplets") {
        document.getElementById("instruct").innerHTML =
            "Please upload a triplet format file";
        removeGraph();
        // document.getElementById("parenthetical").style.visibility ="hidden";
        // location.reload(true);
        // var e = document.getElementById("textThreshold");
        newickField.style.visibility = "hidden";
        e.style.visibility = "hidden";
        let x = document.getElementById("file");
        // createNetworkSelector.style.visibility = "visible";
        createNetworkSelector.disabled = false;
        if (x.style.display === "none") {
            x.style.display = "block";
        } else {
            x.style.visibility = "visible";
        }
    } else if (val === "pf") {
        document.getElementById("instruct").innerHTML =
            "Please upload a file in Newick format OR type an expression";
        removeGraph();
        e.style.visibility = "hidden";
        // location.reload(true);
        newickField.style.visibility = "visible";
        parentheticalSelector.style.visibility = "visible";
        createNetworkSelector.style.visibility = "visible";
        let x = document.getElementById("file");
        x.style.visibility = "visible";
        // createNetworkSelector.style.visibility = "visible";
        createNetworkSelector.disabled = false;
    }
}

function simulateClick(x, y) {
    jQuery(document.elementFromPoint(315, 205)).click();
    // alert("clicking" + x + " " + y);
}

function createboxes() {
    // b.style.visibility= "hidden";
    // btnRemoveNodes.disabled= true;
    createNetworkSelector.disabled = true;
    // createNetworkSelector.style.visibility = "hidden";
    // c.style.visibility = "visible";
    // btnUpdateNet.style.visibility = "visible";

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
        var y = document.createElement("p");
        var text = document.createTextNode("" + element);
        y.appendChild(text);
        // alert(y.textContent);
        if (!y.textContent.includes("Hash")) {
            totalLeafNodes.push(y.textContent);
        }
        // alert(totalLeafNodes);
        if (
            !y.textContent.includes("Hash") &&
            !y.textContent.includes("internal")
        ) {
            document.getElementById("placeholder").appendChild(checkbox);
            document.getElementById("placeholder").appendChild(y);
            document.getElementById("placeholder").appendChild(linebreak);
        }
        // document.body.appendChild(y);
        // console.log(x.id);
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
    // .attr("style", "outline: thin solid red;")   //This will do the job
    // .call(d3.zoom().on("zoom", function () {
    //     d3.event.transform.x = Math.min(0, Math.max(d3.event.transform.x, 1900 - 1900 * d3.event.transform.k));
    //     d3.event.transform.y = Math.min(0, Math.max(d3.event.transform.y, 1500 - 1500 * d3.event.transform.k));
    //     svg.attr("transform", d3.event.transform);;
    // }))

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
        
        // document.getElementById("graph").click();
        // alert("hello");
        document.getElementById("graph").dispatchEvent(new MouseEvent("click"));
        // var img = document.getElementById("graph");
        // var rect = img.getBoundingClientRect();
        // document.elementFromPoint(rect.left, rect.top).click();
    }
    createboxes();
    // simulateClick();
    // simulateClick(309, 203);
    // var coordinates = document.getElementById("graph").getBoundingClientRect();
    // simulateClick(coordinates.left, coordinates.top);
}

function changeRootAction() {
    var flag = inputForFlag.value();
    var tripRoot = input2.value();

    pushChangeRootToServer(flag, tripRoot);
    // greeting.html('Flag=  '+ flag +' Root='+ tripRoot);
}

function removeNodesAction() {
    // unselected node
    nodesCheckedStr = nodesCheckedStr.substr(0, nodesCheckedStr.length - 1);
    console.log(nodesCheckedStr);

    var newCheckedNodes = nodesCheckedStr.split(",");

    // TODO not updating every time
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

    // newCheckedArray = "";
    // alert(totalLeafNodes + " t: " + uniqueArray);
    createD3Graph(uncheckedNodes, uniqueArray, true, false);
    // pushLeavesToServer(nodesCheckedStr)
}

function addNodesAction() {
    // unselected node
    nodesCheckedStr = nodesCheckedStr.substr(0, nodesCheckedStr.length - 1);
    console.log(nodesCheckedStr);

    var newCheckedNodes = nodesCheckedStr.split(",");

    // TODO not updating every time
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

    // newCheckedArray = "";
    // alert(totalLeafNodes + " t: " + uniqueArray);
    createD3Graph(uncheckedNodes, uniqueArray, false, true);
    // pushLeavesToServer(nodesCheckedStr)
}

function removeGraph() {
    $("#chartId").empty();
}

function refreshGraph() {
    // svg.selectAll("svg").remove();
    createD3Graph();
}

// function downloadImage() {
//     var url = document.getElementsByClassName('thumb')[0].getAttribute('src');//response;//img.src.replace(/^data:image\/[^;]+/, 'data:application/octet-stream');
//     url = document.getElementsByClassName('thumb')[0].src;//url.replace(/^data:image\/[^;]+/, 'data:application/octet-stream');
//     url = url.replace(/^data:image\/[^;]+/, 'data:application/octet-stream');
//     window.open(url, 'image.png');
// //  window.location= "buf/image.png";
// }

// file is a p5.File object that has metadata, and the file's contents
function gotFile(file) {
    // document.getElementById("loader").style.visibility = "visible";
    // refresher.style.visibility = "visible";
    refresher.disabled = false;
    // selectbutton.style.visibility = "hidden";
    selectbutton.disabled = true;

    // refresher.style.visibility="visible";
    refresher.disabled = false;
    // selectbutton.style.visibility="hidden";
    // Make a div to display info about the file
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
    // fileDiv.addClass("boxText1");

    // Assign a CSS class for styling (see index.html)
    fileDiv.class("files");
    var hideinfo = document.getElementsByClassName("files");

    // Hanlde image and text differently
    if (file.type === "image") {
        alert("image not accepted");
    } else if (file.type === "text") {
        if (selectedDropDown === "HYDE format") {
            //HYDE Selected
            var par = createP(file.data);
            par.class("text");
            var texts = selectAll(".text");
            // var paraText=  document.getElementsByClassName('text').innerHTML;
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
            // paraText = document.getElementsByClassName('text')[0].innerHTML;

            // pushStringToServer(paraText);
        }
    }
    var boxnums = document.getElementsByClassName("boxText1");
}

function pushHydeToServer(hydeInput, thresh) {
    //testHyde();
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
        newickFr = x.newick

        //alert(e);
        // document.write("This is Working <p>");
        if (request.readyState === 4 && request.status === 200) {
            document.getElementById("dwn-btn").style.visibility = "visible";
            document.getElementById("downloadPng").style.visibility = "visible";

            createD3Graph();
        } else if (request.status === 401) {
            reqStatus = request.status;
            document.getElementById("loader").style.visibility = "hidden";
            document.getElementById("instruct").innerHTML =
                "Error in file input please try uploading a file in the correct HYDE format";

            // document.write("<p>Error : " + request.status + "," + request.statusText);
        }
    }
}

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
        
        // document.write("This is Working <p>");
        if (request.readyState === 4 && request.status === 200) {
            var x = JSON.parse(request.responseText);
            newickFr = x.newick    
            document.getElementById("downloadPng").style.visibility = "visible"

            createD3Graph();
            var x = JSON.parse(request.responseText);
            newickFr = x.newick
    
        } else if (request.readyState === 4) {
            // document.write("<p>Error : " + request.status + "," + request.statusText);
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
        // document.write("This is Working <p>");
        if (request.readyState === 4 && request.status === 200) {
            createD3Graph();
        } else if (request.readyState == 4) {
            // document.write("<p>Error : " + request.status + "," + request.statusText);
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
        // document.write("This is Working <p>");
        if (request.readyState === 4 && request.status === 200) {
            var response = request.responseText;
            //        document.write(response);
            // Convert Base64 to Image
            var img = createImg();
            img.class("thumb");
            document
                .getElementsByClassName("thumb")[0]
                .setAttribute("src", "data:image/png;base64," + response);
        } else if (request.readyState === 4) {
            // document.write("<p>Error : " + request.status + "," + request.statusText);
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

// Start file download.
document.getElementById("dwn-btn").addEventListener("click", function(){
    // Generate download of hello.txt file with some content
    var text = newickFr;
    var filename = "Newick.txt";
    
    download(filename, text);
}, false);


var checkbox = document.querySelector("input[name=checkbox]");

checkbox.addEventListener('change', function() {
  if (this.checked) {
    
    console.log("Checkbox is checked..");
  } else {
      createD3Graph()
    console.log("Checkbox is not checked..");
  }
});

