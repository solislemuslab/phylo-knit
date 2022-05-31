import base64
from ete3 import Tree
import os
from flask import Flask, request, Response
from flask_cors import CORS, cross_origin
from flask import jsonify, make_response
import ParentheticalConvertorNaman
import ServerAction
import test_user
import convertor

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

@app.route('/updateNewick/', methods=['POST'])
@cross_origin()
def updateNewick():
    json = request.get_json()
    source = json["source"]
    target = json["target"]
    tar = ""
    for i in target:
        tar = tar +" " + i
    tar = tar.strip()
    print("source",source,"target",target)
    with open('tester.txt','r+') as myfile:
        data = myfile.read()
        myfile.seek(0)
        myfile.write(source + " " + tar)
        myfile.truncate()
    cmd = 'julia tester.jl'
    os.system(cmd)
    first = ""
    with open("hereTest.txt") as f:
        lines = f.read() ##Assume the sample file has 3 lines
        first = lines.split('\n', 1)[0]

    return jsonify({'newick':first})
    '''
    connections = []
    for i in range(len(source)):
        connections.append(source[i]+ " " + target[i])
    t = Tree.from_parent_child_table([line.split() for line in connections] )

   
    return jsonify({'stat': "executing",'newick':t.write()})
    '''

# POST
@app.route('/uploadLeaves/', methods=['POST'])
@cross_origin()
def uploadLeavesToBeRemoved():
    """
    predicts requested text whether it is ham or spam
    :return: json
    """
    json = request.get_json()
    print(json)
    if len(json['text']) == 0:
        return 'error invalid input'

    leaves = json['text']

    print(leaves)

    ServerAction.removeNodes(leaves)

    return "working"


@app.route('/changeRoot/<root>', methods=['POST'])
def uploadRootToBeChanged(root):
    print('root= ', root)
    json = request.get_json()
    print(json)
    if len(json['text']) == 0:
        return 'error invalid input'

    flag = json['text']

    print(flag)

    ServerAction.changeRoot(flag, root)
    with open("net.png", "rb") as image_file:
        encoded_string = base64.b64encode(image_file.read())
    print(encoded_string)
    return encoded_string


@app.route('/getParenthetical/')
def getParenthetical():
    """
    this serves as a demo purpose
    :param user:
    :return: str
    """
    parenthetical = ServerAction.returnParentheticalFormat('cExample.dot')
    print(parenthetical)
    return "Hello parenthetical is here" + parenthetical


# POST
@app.route('/uploadHyde/<thresh>', methods=['POST'])
@cross_origin()
def uploadHyde(thresh):
    json = request.get_json()
    if len(json['text']) == 0:
        return jsonify({'error': 'File format is incorrect'}), 401

    hyde = json['text']

    print('Threshold =', thresh)

    print(hyde)
    with open('HydeInput.txt', 'w+') as f:
        f.write(hyde)
    #test_user.testHyde("HydeInput.txt",hyde,thresh)
    ServerAction.parseHydeToTriplets("HydeInput.txt", float(thresh))
    '''
    try:
        if ServerAction.parseHydeToTriplets("HydeInput.txt", float(thresh)) == 401:
             return jsonify({'error': 'File format is incorrect'}), 401
    except:
        return jsonify({'error': 'File format is incorrect'}), 401
    '''

    # TODO: uncomment the following done
    ServerAction.tripletsToDot('HydeToTriplets.txt')
    # ServerAction.tripletsToDot('hydetotriplets.out')
    dotFile = ServerAction.returnReducedDotFile('cExample1.dot')

    with open('upload.dot', 'w+') as f:
        f.write(dotFile)
    print("dot file")
    print(dotFile)
    return jsonify({'stat': "executing",'newick':convertor.reader()})


# POST
@app.route('/uploadNewick/', methods=['POST'])
@cross_origin()
def uploadParentheticalAndReturnDot():
    """
    predicts requested text whether it is ham or spam
    :return: json
    """
    json = request.get_json()
    print(json)
    if len(json['text']) == 0:
        return 'error invalid input'

    parenthetical = json['text']

    # print(parenthetical)
    #parenthetical = ServerAction.symbolReplacement(parenthetical)
    print(parenthetical)

    ParentheticalConvertorNaman.newickToDot(parenthetical)

    #return jsonify({'stat': "executing",'newick':convertor.reader()})


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
    
    if ServerAction.checkTripletErrors(triplets) == 401:
        return jsonify({'error': 'File format is incorrect'}), 401

    print(triplets)
    with open('retrievedTriplets.txt', 'w+') as f:
        f.write(triplets)

    ServerAction.tripletsToDot('retrievedTriplets.txt')
    dotFile = ServerAction.returnReducedDotFile('cExample1.dot')

    with open('upload.dot', 'w+') as f:
        f.write(dotFile)

    return dotFile
    #return jsonify({'stat': "executing",'newick':convertor.reader()})


# GET
@app.route('/readDot')
@cross_origin()
def receiveDot():
    print('Sending Dot')
    # TODO change done
    # dotFile = returnReducedDotFile('cExample1.dot')

    # with open('upload.dot', 'w+') as newickField:
    #     newickField.write(dotFile)

    # with open("upload1.dot", "r") as newickField:
    print("THIS IS HERE")
    print(quotifyTheFile('upload.dot'))
    return Response(quotifyTheFile('upload.dot'), mimetype='text/plain')

    # return "working"

@app.route('/readDot2')
@cross_origin()
def receiveDot2():
    print('Sending Dot')
    # TODO change done
    # dotFile = returnReducedDotFile('cExample1.dot')

    # with open('upload.dot', 'w+') as newickField:
    #     newickField.write(dotFile)

    # with open("upload1.dot", "r") as newickField:
    return jsonify({'dotData':quotifyTheFile("upload.dot")})

if __name__ == '__main__':
    app.run(host='127.0.0.1', port=5001)