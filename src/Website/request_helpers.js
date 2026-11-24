/*
 *  This file contains all functions that communicate with the server (and the function for downloading the SVG).
 *  Most functions just send the input data to the server and then draw the graph.
 * 
 *  The image downloading fxn is also included at the end of the file.
 */


// Send Hyde input to the server and draws the resulting network if there is one, else throws an error
function pushHydeToServer(hydeInput, thresh, eNewick) {
    // The backbone goes in the request body, not the URL: extended Newick
    // contains "#", which a URL treats as the start of a fragment
    var data = JSON.stringify({
        text: hydeInput,
        threshold: thresh,
        backbone: eNewick,
    });

    var request = new XMLHttpRequest();
    request.open("POST", "http://127.0.0.1:5001/uploadHyde/");
    request.setRequestHeader("Content-Type", "application/json");
    request.addEventListener("readystatechange", processRequest, false);
    startLoading();
    request.send(data);

    var alreadySent = false;  // we usually receive the response twice, so let's only send once.
    function processRequest(e) {
        if(request.responseText == "")
            return;
        console.log("check ");
        console.log(request.responseText);
        var x = JSON.parse(request.responseText);

        if (request.readyState === 4 && request.status === 200) {
            if(typeof(x.newick) != 'undefined') {
                originalNewick = x.newick.trim();
                userAdjustedNewick = "";
            }

            pushParentheticalToServer(originalNewick);
            doneLoading();
        } else if (request.status === 401) {
            reportRequestError(request);
        }
    }

}

// Sends SVG string to server which returns PDF string
function pushSVGToServer(svg_string) {
    var data = JSON.stringify({
        'svg': svg_string
    });

    var request = new XMLHttpRequest();
    request.open("POST", "http://127.0.0.1:5001/getPDF/");
    request.setRequestHeader("Content-Type", "application/json");
    request.addEventListener("readystatechange", processRequest, false);
    request.responseType = 'blob';
    request.send(data);

    function processRequest(e) {
        if(request.readyState == 4 && request.status == 200) {
            // download the PDF contents to the user
            dataBlob = new Blob([request.response], {'type':'application/pdf'})
            saveAs(dataBlob, 'network.pdf')
        } else if(request.status == 401) {
            document.getElementById("instruct").innerHTML = "ERROR: no response from server.";
            reportRequestError(request);
        }
    }
}

// Sends parenthetical input to the server and draws the resulting network if there is one, else throws an error
function pushParentheticalToServer(parenthetical, updateLeafBox) {
    if(typeof(updateLeafBox) == "undefined")
        updateLeafBox = true;

    var data = JSON.stringify({
        text: parenthetical.replaceAll(" ", ""),
    });

    var request = new XMLHttpRequest();
    request.open("POST", "http://127.0.0.1:5001/uploadNewick/");
    request.setRequestHeader("Content-Type", "application/json");
    request.addEventListener("readystatechange", processRequest, false);
    startLoading();
    request.send(data);

    function processRequest(e) {
        if (request.readyState === 4 && request.status === 200) {
            var x = JSON.parse(request.responseText);
            console.log(x);
            
            if('rootname' in x) {
                ROOT_NAME = x['rootname'];
            } else if('new_root' in x) {
                ROOT_NAME = x['new_root'];
            }

            console.log(x["dot"]);
            createD3Graph(updateLeafBox, x["dot"]);

            // if updateLeafBox is false then we are just updating to a user adjustment,
            // so this is the edited Newick
            if(updateLeafBox) {
                originalNewick = x["newick"].replaceAll(" ", "").trim();
                userAdjustedNewick = "";
            } else
                userAdjustedNewick = x["newick"].replaceAll(" ", "")

            doneLoading();
        } else if (request.status == 401) {
            reportRequestError(request);
        }
    }
}


// Used for re-rooting and showing/hiding nodes from the network
function pushUpdatedParentheticalToServer(data) {
    var request = new XMLHttpRequest();
    request.open("POST", "http://127.0.0.1:5001/getUserAdjustedParenthetical/");
    request.setRequestHeader("Content-Type", "application/json");
    request.addEventListener("readystatechange", processRequest, false);
    request.send(data);

    function processRequest(e) {
        if(request.readyState == 4 && request.status == 200) {
            var x = JSON.parse(request.responseText);
            console.log(x);
            console.log('rootname' in x)
            console.log('new_root' in x)

            if(x.result == 'success') {
                // change to new root
                if('rootname' in x) {
                    ROOT_NAME = x['rootname'];
                } else if('new_root' in x) {
                    ROOT_NAME = x['new_root'];
                }
                
                // reset highlighted node var
                highlightedNode = null;

                // push the parenthetical
                pushParentheticalToServer(x.newick, false);
        
                // re-enable Create/Update network buttons
                enableButtons();
            } else {
                reportRequestError(request);
            }
        } else if(request.status == 401) {
            reportRequestError(request);
        }
    }
}


// Send triplet input to the server and draws the resulting network if there is one, else throws an error
function pushTripletsToServer(triplets) {
    var data = JSON.stringify({
        "text": triplets,
    });

    var request = new XMLHttpRequest();
    request.open("POST", "http://127.0.0.1:5001/upload/");
    request.setRequestHeader("Content-Type", "application/json");
    request.addEventListener("readystatechange", processRequest, false);
    startLoading();
    request.send(data);

    function processRequest(e) {
        if (request.readyState === 4 && request.status === 200) {
            var x = JSON.parse(request.responseText);
            if(typeof(x.newick) != 'undefined') {
                originalNewick = x.newick.trim();
                userAdjustedNewick = "";
            }
            pushParentheticalToServer(originalNewick);
            doneLoading();
        } else if (request.status === 401) {
            reportRequestError(request);
        }
    }
}


function reportRequestError(request) {
    // error, probably just couldn't talk to server
    var data = JSON.parse(request.responseText);
    if('error' in data) {
        document.getElementById("instruct").textContent = data['error'];
    } else {
        document.getElementById("instruct").innerHTML = "ERROR: An unknown error occurred. Please report this issue with the link on the left sidebar.";
    }

    doneLoading();
    enableButtons();
    disableCreateNetworkButton();
    $("#create-network-loading-icon").addClass("d-none");
    $("#create-network-notloading-icon").removeClass("d-none");
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
        var hydeData = fileText;

        if (threshold.length === 0) {
            errMsg =
                "The Threshold value is missing for the Hyde Format; please try again ";
            createNetworkSelector.disabled = false;
            errors = 1;
        }
        if (isNaN(threshold)) {
            errMsg = 
                "The p-value is not a number. Please try again.";
            errors = 1;
        }
        if (hydeData === undefined || typeof hydeData === "undefined" || hydeData.length === 0) {
            errMsg =
                "The Hyde format file was not uploaded. Please choose a Hyde file and try again";
            errors = 1;
        }
    }
    if (formatType === "Triplets"){
        var tripData = fileText;
        console.log(fileText);
        console.log(tripData);
        console.log("reached over here ")
        if (tripData === undefined || typeof tripData === "undefined" || tripData.length === 0) {
            errMsg =
                "The Triplet format file was not uploaded. Please choose a Triplet file and try again";
            errors = 1;
        }
    }
    if (formatType === "pf"){
            var pText = document.getElementById("parenthetical");
            var parData = fileText;

            if (pText.value === "" && (parData=== undefined || typeof parData === "undefined" || parData.length === 0 )) {
                errMsg =
                "Parenthical format was not found. Please choose a Parenthical file or enter Newick format and try again";
                errors = 1;
            }
            // if the Newick is missing a semicolon: add a semicolon
            if(pText.value.length >= 1 && pText.value[pText.value.length-1] != ';') {
                pText.value = pText.value + ';';
                document.getElementById("instruct").innerHTML = "(NOTICE: Semi-colon auto-appended to Newick)";
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


// ---------------------------------------------------------------------------
// Image exporting functionalities courtesy of the following:
// http://bl.ocks.org/Rokotyan/0556f8facbaf344507cdc45dc3622177
// ---------------------------------------------------------------------------

// Function for downloading Newick
function downloadNewick() {
    var returnNewick;
    if(userAdjustedNewick != "")
        returnNewick = userAdjustedNewick.trim();
    else
        returnNewick = originalNewick.trim();

    // remove all unnamed/internal nodes
    var tempNewick;
    while(returnNewick.localeCompare(tempNewick = returnNewick.replace(regUnnamed, '')) != 0) { returnNewick = tempNewick; }
    while(returnNewick.localeCompare(tempNewick = returnNewick.replace(reg1000P, '')) != 0) { returnNewick = tempNewick; }
    download("eNewick.txt", returnNewick.trim());
}

function saveImg() {
    var svgString = getSVGString(d3.select('svg').node()); 
    svgString2Image(svgString, 5*width, 5*height, 'png', save);

    function save(dataBlob, filesize) {
        saveAs(dataBlob, 'vis.png');
    }
}


function savePDF() {
    var svgString = getSVGString(d3.select('svg').node());
    pushSVGToServer(svgString);
}



// Below are the functions that handle actual exporting:
// getSVGString ( svgNode ) and svgString2Image( svgString, width, height, format, callback )
function getSVGString( svgNode ) {
	svgNode.setAttribute('xlink', 'http://www.w3.org/1999/xlink');
	var cssStyleText = getCSSStyles( svgNode );
	appendCSS( cssStyleText, svgNode );

	var serializer = new XMLSerializer();
	var svgString = serializer.serializeToString(svgNode);
	svgString = svgString.replace(/(\w+)?:?xlink=/g, 'xmlns:xlink='); // Fix root xlink without namespace
	svgString = svgString.replace(/NS\d+:href/g, 'xlink:href'); // Safari NS namespace fix

	return svgString;

	function getCSSStyles( parentElement ) {
		var selectorTextArr = [];

		// Add Parent element Id and Classes to the list
		selectorTextArr.push( '#'+parentElement.id );
		for (var c = 0; c < parentElement.classList.length; c++)
				if ( !contains('.'+parentElement.classList[c], selectorTextArr) )
					selectorTextArr.push( '.'+parentElement.classList[c] );

		// Add Children element Ids and Classes to the list
		var nodes = parentElement.getElementsByTagName("*");
		for (var i = 0; i < nodes.length; i++) {
			var id = nodes[i].id;
			if ( !contains('#'+id, selectorTextArr) )
				selectorTextArr.push( '#'+id );

			var classes = nodes[i].classList;
			for (var c = 0; c < classes.length; c++)
				if ( !contains('.'+classes[c], selectorTextArr) )
					selectorTextArr.push( '.'+classes[c] );
		}

		// Extract CSS Rules
		var extractedCSSText = "";
		for (var i = 0; i < document.styleSheets.length; i++) {
			var s = document.styleSheets[i];
			
			try {
			    if(!s.cssRules) continue;
			} catch( e ) {
		    		if(e.name !== 'SecurityError') throw e; // for Firefox
		    		continue;
		    	}

			var cssRules = s.cssRules;
			for (var r = 0; r < cssRules.length; r++) {
				if ( contains( cssRules[r].selectorText, selectorTextArr ) )
					extractedCSSText += cssRules[r].cssText;
			}
		}
		

		return extractedCSSText;

		function contains(str,arr) {
			return arr.indexOf( str ) === -1 ? false : true;
		}

	}

	function appendCSS( cssText, element ) {
		var styleElement = document.createElement("style");
		styleElement.setAttribute("type","text/css"); 
		styleElement.innerHTML = cssText;
		var refNode = element.hasChildNodes() ? element.children[0] : null;
		element.insertBefore( styleElement, refNode );
	}
}


function svgString2Image( svgString, width, height, format, callback ) {
	var format = format ? format : 'png';

	var imgsrc = 'data:image/svg+xml;base64,'+ btoa( unescape( encodeURIComponent( svgString ) ) ); // Convert SVG string to data URL

	var canvas = document.createElement("canvas");
	var context = canvas.getContext("2d");

	canvas.width = width;
	canvas.height = height;

	var image = new Image();
	image.onload = function() {
		context.clearRect ( 0, 0, width, height );
		context.drawImage(image, 0, 0, width, height);

		canvas.toBlob( function(blob) {
			var filesize = Math.round( blob.length/1024 ) + ' KB';
			if ( callback ) callback( blob, filesize );
		});

		
	};

	image.src = imgsrc;
}