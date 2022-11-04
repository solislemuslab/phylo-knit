/*
 *  This file contains all functions that communicate with the server (and the function for downloading the SVG).
 *  Most functions just send the input data to the server and then draw the graph.
 */


// Send Hyde input to the server and draws the resulting network if there is one, else throws an error
function pushHydeToServer(hydeInput, thresh, eNewick) {
    var data = JSON.stringify({
        text: hydeInput,
    });
    flag = 0;
    var request = new XMLHttpRequest();
    if (eNewick === "") {
        eNewick = "none_provided";
    }
    request.open("POST", "http://127.0.0.1:5001/uploadHyde/" + thresh + "/" + eNewick);
    request.setRequestHeader("Content-Type", "application/json");
    request.addEventListener("readystatechange", processRequest, false);
    request.send(data);
    console.log(data);

    function processRequest(e) {
        console.log("check ");
        var x = JSON.parse(request.responseText);
        originalNewick = x.newick;
        newickFr = originalNewick; 

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


// Sends parenthetical input to the server and draws the resulting network if there is one, else throws an error
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


// Send triplet input to the server and draws the resulting network if there is one, else throws an error
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


// not sure this is actually used anywhere at the moment??
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
 * This method is responsible to test the inputs of the user and return errors on the website. It checks things such as missing input values and return personalized error messages.
 * This method is a front-end check (values inputted or files inputted) and the back-end user input testing relates to files format/standards
 * @param formatType : Chosen file format (triplet,parenthetical,Hyde)
 */
 function testUserInput(formatType) {
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
            var pText = document.getElementById("parenthetical");
            var parData = document.getElementsByClassName("text")[0];

            if (pText.value === "" && (parData=== undefined|| parData.innerHTML === undefined || typeof parData === "undefined" || parData.innerHTML.length === 0 )) {
                errMsg =
                "Parenthical format was not found. Please choose a Parenthical file or enter Newick format and try again";
                errors = 1;
            }
            // if the Newick is missing a semicolon: add a semicolon
            if(pText.value[pText.value.length-1] != ';') {
                pText.value = pText.value + ';';
                newickWarningLabel.style.visibility = "visible";
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