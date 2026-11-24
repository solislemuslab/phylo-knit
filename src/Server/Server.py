import io
from time import time

# Julia is called through juliacall. The Julia packages it needs (PhyloNetworks)
# are listed in juliapkg.json and installed automatically on first run.
from juliacall import Main as jl

jl.seval("using PhyloNetworks")
# juliacall maps a trailing "_b" to Julia's "!", e.g. rootatnode_b -> rootatnode!
readnewick, writenewick = jl.readnewick, jl.writenewick
deleteleaf_b, nameinternalnodes_b, rootatnode_b = jl.deleteleaf_b, jl.nameinternalnodes_b, jl.rootatnode_b
majortree = jl.majortree

import ParentheticalConvertorNaman
import ServerAction
from flask import Flask, jsonify, request, send_file
from flask_cors import CORS, cross_origin

app = Flask(__name__)
cors = CORS(app, resources={r"/api/*": {"origins": "*"}})


# POST
# JSON body: {"text": HyDe output, "threshold": p-value,
#             "backbone": backbone Newick, or "" if there is none}
@app.route('/uploadHyde/', methods=['POST'])
@cross_origin()
def uploadHyde():
    json = request.get_json()
    if len(json['text'].strip()) == 0:
        return jsonify({'error': 'ERROR: The HyDe file is empty.'}), 400

    hyde = json['text']
    try:
        thresh = float(json['threshold'])
    except (TypeError, ValueError):
        return jsonify({'error': 'ERROR: The p-value threshold must be a number.'}), 400
    eNewick = json.get('backbone') or "none_provided"

    # The triplet code needs a backbone tree: a backbone network is reduced to
    # its major tree (each hybrid keeps its parent with the larger gamma)
    if eNewick != "none_provided":
        try:
            backbone = readnewick(eNewick)
        except Exception as e:
            print(e)
            return jsonify({'error': 'ERROR: Failed to read the backbone Newick.'}), 400
        if backbone.numhybrids > 0:
            eNewick = writenewick(majortree(backbone))
    
    print('parenthetical =', eNewick)
    print('Threshold =', thresh)

    try:
        triplets = ServerAction.parseHydeToTriplets(hyde, thresh, eNewick)
    except ValueError as e:
        return jsonify({'error': 'ERROR: ' + str(e)}), 400

    print("uploadHyde.triplets: ", triplets)
    try:
        newick = ServerAction.tripletsToNewick(triplets)
    except ValueError as e:
        return jsonify({'error': 'ERROR: ' + str(e)}), 400

    return jsonify({'stat':"executing", 'newick': newick})


# POST
@app.route('/getPDF/', methods=['POST'])
@cross_origin()
def getPDF():
    json = request.get_json()
    if len(json['svg']) == 0:
        return jsonify({'error': 'ERROR: There is no network to save.'}), 400
    svg_dat = json['svg']
    
    pdf_bytes = ServerAction.pdfFromSVG(svg_dat)
    
    return send_file(io.BytesIO(pdf_bytes),
                     download_name='vis.pdf',
                     as_attachment=True)


# Errors thrown by PhyloNetworks reach Python as juliacall.JuliaError exceptions,
# so the usual try/except blocks below catch them.
# POST
@app.route('/getUserAdjustedParenthetical/', methods=['POST'])
@cross_origin()
def getUserAdjustedParenthetical():
    # The parenthetical to be adjusted is in request.get_json()
    json = request.get_json()

    if len(json['text']) == 0:
        return jsonify({'error': 'ERROR: There is no network to adjust.'}), 400
    parenthetical = json['text']

    try:
        # Load the parenthetical into Julia
        print("parenthetical: \"", parenthetical, "\"", sep="")
        net = readnewick(parenthetical)
    except Exception as e:
        print(e)
        return jsonify({'error':"Failed to read parenthetical format of \"" + parenthetical + "\""}), 400

    # removed_nodes should be a list of leaf names
    removed_nodes = json.get('removed_nodes') or []
    if len(removed_nodes) != 0:
        print("removing leaves...")

        for node_name in removed_nodes:
            try:
                deleteleaf_b(net, node_name, keeporiginalroot=False)
            except Exception as e:
                print(e)
                return jsonify({'error':"Failed when removing node " + node_name}), 400

    # re-root the network
    new_root = json.get('new_root') or ""
    if len(new_root) != 0:
        if new_root[:4] == "Hash":
            new_root = new_root.replace("Hash", "", 1)

        if new_root not in [node.name for node in net.node]:
            return jsonify({'error': 'ERROR: There is no node named "' + new_root + '" in the network.'}), 400
            
        print("re-rooting at", new_root, "...")
        
        print("----- DEBUG -----")
        print(writenewick(net))
        print("new root:", new_root)
        print("----- DEBUG -----")
        
        try:
            rootatnode_b(net, new_root)
        except:
            return jsonify({'error':'ERROR: Failed to re-root network at selected node, most likely because re-rooting here would invert a reticulation.'}), 400

    if net.node[net.rooti-1].name == '':
        net.node[net.rooti-1].name = "root"  # set the name to root, so we know which node is the root

    return jsonify({'result':'success','newick':writenewick(net),'new_root':net.node[net.rooti-1].name})


# POST
@app.route('/uploadNewick/', methods=['POST'])
@cross_origin()
def uploadParentheticalAndReturnDot():
    """Read a (extended) Newick string and return it as a DOT graph for the
    web page to draw, with its internal nodes named."""
    json = request.get_json()
    if len(json['text']) == 0:
        return jsonify({'error': 'ERROR: Invalid input text.'}), 400

    parenthetical = json['text']

    # Unnamed internal nodes are named "unnamed1", ... so that re-rooting can
    # refer to them
    readnet_time = time()       # timing portions
    net = 0
    try:
        net = readnewick(parenthetical)
    except:
        try:
            net = readnewick(parenthetical + ";")
        except:
            return jsonify({'error': 'ERROR: Invalid newick input. If your input is valid, please report this issue with the link on the left sidebar.'}), 400
    readnet_time = time() - readnet_time
    
    adjustment_time = time()
    try:
        nameinternalnodes_b(net, "unnamed")
        parenthetical = writenewick(net)
    except:
        return jsonify({'error': 'ERROR: An unknown error occurred. Please report this issue with the link on the left sidebar.'}), 500
    adjustment_time = time() - adjustment_time

    try: 
        dotconversion_time = time()
        dotString = ParentheticalConvertorNaman.newickToDot(parenthetical)
        dotconversion_time = time() - dotconversion_time
        
        total_time = readnet_time + adjustment_time + dotconversion_time
        print("Time to read net: " + str(round(readnet_time, 2)) + "s (" + str(readnet_time / total_time) + ")")
        print("Time to adjust net names: " + str(round(adjustment_time, 2)) + "s (" + str(readnet_time / total_time) + ")")
        print("Time to convert to dot: " + str(round(dotconversion_time, 2)) + "s (" + str(readnet_time / total_time) + ")")
        
        return jsonify({'stat': "executing",'dot': dotString,'newick':parenthetical,'rootname':net.node[net.rooti-1].name})
    except:
        return jsonify({'error': 'ERROR: An error occurred when converting from newick to .dot format. Please report this issue with the link on the left sidebar.'}), 500


# POST
@app.route('/upload/', methods=['POST'])
@cross_origin()
def uploadTripletsAndReturnDot():
    """Build a network from triplets with Lev1athan and return its Newick string."""
    json = request.get_json()
    print(json)
    if len(json['text']) == 0:
        return jsonify({'error': 'ERROR: The triplets file is empty.'}), 400

    triplets = json['text']

    try:
        newick = ServerAction.tripletsToNewick(triplets)
    except ValueError as e:
        return jsonify({'error': 'ERROR: ' + str(e)}), 400

    return jsonify({'stat': "executing", 'newick': newick})

# threaded=False: juliacall must only be called from the main Python thread, so
# Flask handles one request at a time. (With PyJulia this setting was reported to
# make the server hang intermittently; not yet re-checked with juliacall.)
if __name__ == '__main__':
    app.run(host='127.0.0.1', port=5001, threaded=False)