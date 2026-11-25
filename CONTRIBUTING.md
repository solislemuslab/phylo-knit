# Contributing to phylo-knit

The following guidelines are designed for contributors to phylo-knit. 

## Reporting Issues

For reporting a bug or a failed function or requesting a new feature, you can simply open an issue in the [issue tracker](https://github.com/solislemuslab/phylo-knit/issues). If you are reporting a bug, please also include a minimal code example or all relevant information for us to replicate the issue.

## Contributing Code

To make contributions to phylo-knit, you need to set up your [GitHub](https://github.com) 
account if you do not have and sign in, and request your change(s) or contribution(s) via 
a pull request against the ``development``
branch of the [phylo-knit repository](https://github.com/solislemuslab/phylo-knit). 

Please use the following steps:

1. Open a new issue for new feature or failed function in the [Issue tracker](https://github.com/solislemuslab/phylo-knit/issues)
2. Fork the [phylo-knit repository](https://github.com/solislemuslab/phylo-knit)to your GitHub account
3. Clone your fork locally:
```
$ git clone https://github.com/your-username/phylo-knit.git
```   
4. Make your change(s) in the `master` (or `development`) branch of your cloned fork
5. Make sure that all tests are passed without any errors (upcoming automatic testing available in phylo-knit)
6. Push your change(s) to your fork in your GitHub account
7. [Submit a pull request](https://github.com/solislemuslab/phylo-knit/pulls) describing what problem has been solved and linking to the issue you had opened in step 1

Your contribution will be checked and merged into the original repository. You will be contacted if there is any problem in your contribution

Make sure to include the following information in your pull request:

* **Code** which you are contributing to this package.

* **Documentation** of this code if it provides new functionality.

**WARNING:** When you run the website locally, you will have many changes to `.pyc` local files that you should discard prior to any commit with `git checkout -- <file>` and new untracked files created when running the website locally should be deleted prior to any commit if you intent to contribute to the website. Make sure that your pull request do not include changes to these files.

## How the code is organized

phylo-knit is a Flask web server (`src/Server/`) plus a static web page
(`src/Website/`). The page sends the user's input to the server as JSON and
draws the network that the server sends back.

### Server (`src/Server/`)

- `Server.py`: the Flask app. It starts Julia through juliacall and uses
  PhyloNetworks to read, re-root and edit networks. It has one route per
  action:
  - `/uploadNewick/`: reads an extended Newick string, names its unnamed
    internal nodes, and returns the network as a DOT graph for the page to draw.
  - `/upload/`: builds a network from triplets with LEV1ATHAN and returns it
    in Newick format.
  - `/uploadHyde/`: turns HyDe results (and an optional backbone tree) into
    triplets, then builds a network the same way as `/upload/`.
  - `/getUserAdjustedParenthetical/`: re-roots the network or removes leaves.
  - `/getPDF/`: converts the drawn network (an SVG) to PDF.
- `ServerAction.py`: helpers for these routes. It converts HyDe results to
  triplets, runs the two jar files, and makes the PDF.
- `ParentheticalConvertorNaman.py`: converts a Newick string to the DOT graph
  that the page draws.
- `Lev1athan.jar`: [LEV1ATHAN](https://skelk.sdf-eu.org/lev1athan/), which
  builds a level-1 network from triplets.
- `NewickToTriplet.jar`: from the same package; it lists the triplets of a
  backbone tree.
- `juliapkg.json`: the Julia version and packages that juliacall installs.

When the user's input has a problem, the server answers with status 400 and a
JSON `error` message, which the page shows. Unexpected failures give status 500.

### Web page (`src/Website/`)

- `index.html`: the page layout: input forms, buttons and display settings.
- `sketch.js`: draws the network with d3's force layout, and handles what the
  user does on the page (buttons, clicking nodes, display settings).
- `request_helpers.js`: sends input to the server and handles its answers. It
  passes a DOT graph to `sketch.js` to draw, or shows the error message. It
  also handles the downloads (Newick, PNG and PDF).
- `libraries/d3-dot-graph.js`: parses DOT into the nodes and links that d3 draws.
- `css/`, `js/` and `vendor/`: the page template (SB Admin 2) and its
  libraries (Bootstrap, jQuery and Font Awesome).

Triplets, HyDe results, re-rooting and leaf removal all take two steps: the
server returns a Newick string, which the page then sends to `/uploadNewick/`
to get the DOT graph.

---

_These Contributing Guidelines have been adapted from the [Contributing Guidelines](https://github.com/atomneb/AtomNeb-py/blob/master/CONTRIBUTING.md) of [The Turing Way](https://github.com/atomneb/AtomNeb-py)! (License: MIT)_