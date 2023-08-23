import io
from time import time

from julia.api import Julia

try:
    jl = Julia()
except:
    ### Example of specifying a specific Julia executable
    jl = Julia(runtime="/Applications/Julia-1.8.app/Contents/Resources/julia/bin/julia")

from julia import Pkg

Pkg.activate("PhyloNetworks")

import ParentheticalConvertorNaman
import ServerAction
from flask import Flask, jsonify, make_response, request, send_file
from flask_cors import CORS, cross_origin
from julia import Julia
from julia import Main as Julia
from julia.PhyloNetworks import (deleteleaf_b, nameinternalnodes_b,
                                 readTopology, rootatnode_b,
                                 undirectedOtherNetworks, writeTopology)

app = Flask(__name__)
cors = CORS(app, resources={r"/api/*": {"origins": "*"}})


def quotifyTheFile(fileName):
    strF = ""
    with open(fileName, 'r') as f:
        strF = f.read()

    writeContent = ""

    for line in strF.split('\n'):
        if line.__contains__("->"):
            arr = line.split(" -> ")
            line = "\"" + arr[0] + "\" -> \"" + arr[1] + "\""

        writeContent += line
        print(line)

    return writeContent


# POST
@app.route('/uploadHyde/<thresh>/<eNewick>', methods=['POST'])
@cross_origin()
def uploadHyde(thresh, eNewick):
    json = request.get_json()
    if len(json['text']) == 0:
        return jsonify({'error': 'File format is incorrect'}), 401

    hyde = json['text']
    
    print('parenthetical =', eNewick)
    print('Threshold =', thresh)

    #test_user.testHyde("HydeInput.txt",hyde,thresh)
    triplets = ServerAction.parseHydeToTriplets(hyde, float(thresh), eNewick)

    # TODO: uncomment the following done
    print("uploadHyde.triplets: ", triplets)
    newick = ServerAction.tripletsToNewick(triplets)

    return jsonify({'stat':"executing", 'newick': newick})


# POST
@app.route('/getPDF/', methods=['POST'])
@cross_origin()
def getPDF():
    json = request.get_json()
    if len(json['svg']) == 0:
        return 'error invalid input'
    svg_dat = json['svg']
    
    pdf_bytes = ServerAction.pdfFromSVG(svg_dat)
    
    return send_file(io.BytesIO(pdf_bytes),
                     download_name='vis.pdf',
                     as_attachment=True)


# TODO: check for errors from PhyloNetworks (not sure how to do this via PyJulia, probably just the usual Python try-except clause)
# POST
@app.route('/getUserAdjustedParenthetical/', methods=['POST'])
@cross_origin()
def getUserAdjustedParenthetical():
    # The parenthetical to be adjusted is in request.get_json()
    json = request.get_json()

    if len(json['text']) == 0:
        return 'error invalid input'
    parenthetical = json['text']

    try:
        # Load the parenthetical into Julia
        print("parenthetical: \"", parenthetical, "\"", sep="")
        net = readTopology(parenthetical)
    except Exception as e:
        print(e)
        return jsonify({'result':'error','errmsg':"Failed to read parenthetical format of \"" + parenthetical + "\""})

    print("removing leaves...")
    # removed_nodes should be a string of leaf names
    if len(json['removed_nodes']) != 0:
        removed_nodes = json['removed_nodes']

        for node_name in removed_nodes:
            try:
                deleteleaf_b(net, node_name, keeporiginalroot=False)
            except Exception as e:
                print(e)
                return jsonify({'result':'error','errmsg':"Failed when removing node " + node_name})

    print("re-rooting...")
    # re-root the network
    if len(json['new_root']) != 0:
        new_root = json['new_root']
        try:
            rootatnode_b(net, new_root)
        except:
            u_nets = undirectedOtherNetworks(net)
            j = 0
            for i in range(len(u_nets)):
                try:
                    rootatnode_b(u_nets[i], new_root)
                    net = u_nets[i]
                    break
                except:
                    j = i
            
            if j == len(u_nets) - 1:
                # we were unable to re-root the network
                return jsonify({'result':'error','errmsg':"Failed to re-root network at " + new_root})
            

    if net.node[net.root-1].name == '':
        Julia.net = net
        Julia.eval("net.node[net.root].name = \"root\"")  # set the name to root, so we know which node is the root

    return jsonify({'result':'success','newick':writeTopology(net),'new_root':net.node[net.root-1].name})


# POST
@app.route('/uploadNewick/', methods=['POST'])
@cross_origin()
def uploadParentheticalAndReturnDot():
    """
    predicts requested text whether it is ham or spam
    :return: json
    """
    json = request.get_json()
    if len(json['text']) == 0:
        return jsonify({'error', 'ERROR: Invalid input text.'}), 401

    parenthetical = json['text']

    # Replace blank node names with `internal####` so that
    # re-rooting can work
    readnet_time = time()       # timing portions
    net = 0
    try:
        net = readTopology(parenthetical)
    except:
        try:
            net = readTopology(parenthetical + ";")
        except:
            return jsonify({'error': 'ERROR: Invalid newick input. If your input is valid, please report this issue with the link on the left sidebar.'}), 401
    readnet_time = time() - readnet_time
    
    adjustment_time = time()
    try:
        nameinternalnodes_b(net, "unnamed")
        parenthetical = writeTopology(net)
    except:
        return jsonify({'error': 'ERROR: An unknown error occurred. Please report this issue with the link on the left sidebar.'}), 401
    adjustment_time = time() - adjustment_time

    try: 
        dotconversion_time = time()
        dotString = ParentheticalConvertorNaman.newickToDot(parenthetical)
        dotconversion_time = time() - dotconversion_time
        
        total_time = readnet_time + adjustment_time + dotconversion_time
        print("Time to read net: " + str(round(readnet_time, 2)) + "s (" + str(readnet_time / total_time) + ")")
        print("Time to adjust net names: " + str(round(adjustment_time, 2)) + "s (" + str(readnet_time / total_time) + ")")
        print("Time to convert to dot: " + str(round(dotconversion_time, 2)) + "s (" + str(readnet_time / total_time) + ")")
        
        # parenthetical convertor uploads as upload.dot
        return jsonify({'stat': "executing",'dot': dotString,'newick':parenthetical,'rootname':net.node[net.root-1].name})
    except:
        return jsonify({'error': 'ERROR: An error occurred when converting from newick to .dot format. Please report this issue with the link on the left sidebar.'}), 401


# POST
@app.route('/upload/', methods=['POST'])
@cross_origin()
def uploadTripletsAndReturnDot():
    """
    predicts requested text whether it is ham or spam
    :return: json
    """
    json = request.get_json()
    print(json)
    if len(json['text']) == 0:
        return 'error invalid input'

    triplets = json['text']
    
    newick = ServerAction.tripletsToNewick(triplets)

    # if ServerAction.checkTripletErrors(triplets) == 401:
    #     return jsonify({'error': 'File format is incorrect'}), 401

    # print("triplets printed are \n", triplets, "\n")
    # with open('retrievedTriplets.txt', 'w+') as f:
    #     f.write(triplets)

    # ServerAction.tripletsToDot('retrievedTriplets.txt')
    # dotFile = ServerAction.returnReducedDotFile('cExample1.dot')

    # print("triplets to dot is \n", dotFile, "\n end")
    # with open('upload.dot', 'w+') as f:
    #     f.write(dotFile)

    return jsonify({'stat': "executing", 'newick': newick})

# ISSUE: threaded=False seems to be required right now for PyJulia to work,
#        but this also seems to make the server intermittently but consistently hang...
if __name__ == '__main__':
    app.run(host='127.0.0.1', port=5001, threaded=False)