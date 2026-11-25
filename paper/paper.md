---
title: 'phylo-knit: interactive visualization of phylogenetic networks in the browser'
tags:
  - phylogenetics
  - phylogenetic networks
  - hybridization
  - visualization
  - Python
  - Julia
authors:
  - name: Nathan Kolbow
    orcid: 
    affiliation: 1
  - name: Marianne Bjørner
    orcid: 
    affiliation: 1
  - name: Harnoor Singh
    orcid: 
    affiliation: 2
  - name: Naman Kanwar
    orcid: 
    affiliation: 2
  - name: Fardeen Meeran
    orcid: 
    affiliation: 1
  - name: Claudia Solís-Lemus
    orcid: 
    affiliation: 1
    corresponding: true
affiliations:
  - name: AFFILIATION 1 (to fill in)
    index: 1
  - name: AFFILIATION 2 (to fill in)
    index: 2
date: 24 November 2026
bibliography: paper.bib
---

# Summary

The evolutionary history of a group of species is usually drawn as a tree, in
which lineages only split. Many groups of organisms, however, also exchange
genetic material through hybridization, introgression or horizontal gene
transfer, and their history is better described by a phylogenetic network: a
graph in which some lineages have two parents. Networks are harder to read and
to draw than trees, and the tools that infer them produce text formats that are
difficult to inspect by eye.

`phylo-knit` is a web application that turns these results into an interactive
picture. Users paste or upload a network in extended Newick format
[@cardona2008extended], a set of rooted triplets, or the output of the
hybridization-detection software HyDe [@blischak2018hyde], and `phylo-knit`
draws the network in the browser (\autoref{fig:screenshot}). The drawing can be
rearranged by dragging nodes, re-rooted by clicking on a node, pruned by hiding
leaves, restyled, and exported as a PNG or PDF figure or as an extended Newick
string for further analysis.

# Statement of need

Phylogenetic networks are now estimated routinely from genomic data, for
example with PhyloNetworks [@solislemus2017phylonetworks], and hybridization is
often tested directly on sets of three taxa with HyDe [@blischak2018hyde]. Both
kinds of result are hard to look at. A network in extended Newick format is a
single line of nested parentheses, and a HyDe analysis can report thousands of
tests, each involving a putative hybrid and two putative parents. Turning such
results into a figure usually requires a scripting environment such as Julia
or R, and turning many HyDe tests into one coherent network has had no
dedicated tool at all.

`phylo-knit` is designed for empirical biologists who want to see, adjust and
export a network without writing code. It fills two needs. First, it gives an
interactive view of any network in extended Newick format, with the operations
that are most often needed before a network can be shown in a paper: choosing
the root, removing taxa and controlling the layout and style. Second, it builds
a network from triplets or from HyDe results using LEV1ATHAN
[@huber2011practical], so that the hybridization events supported by HyDe can
be seen together, optionally on top of a backbone tree that the user provides.

# State of the field

<!-- Every statement about another tool in this section is marked [verify]:
the authors should check it against the current version of that tool. -->

Several programs draw phylogenetic networks. Dendroscope [@huson2012dendroscope]
is a desktop application for rooted trees and networks that reads extended
Newick and offers several layouts and editing operations [verify]. IcyTree
[@vaughan2017icytree] draws trees and networks from extended Newick directly in
the browser, without installation [verify]. Within the PhyloNetworks ecosystem,
networks can be plotted from Julia with the companion package PhyloPlots, which
requires writing code [verify]. SplitsTree [@huson2006application] computes and
draws split networks, which summarize conflict in the data rather than
representing explicit reticulation events, and so address a different question
[verify].

None of these tools builds a network from triplets or from the output of
hybridization tests such as HyDe [verify]. LEV1ATHAN [@huber2011practical]
does build level-1 networks from triplets, but it is a command-line program
whose output must be drawn separately. `phylo-knit` brings these steps together
in one interface: from HyDe results or triplets, through network construction,
to an interactive figure. Rather than adding these features to an existing
viewer, `phylo-knit` relies on existing libraries for the work they already do
well (PhyloNetworks for reading and modifying networks, LEV1ATHAN for building
them from triplets, and d3 [@bostock2011d3] for drawing) and contributes the
connection between them and the interface for non-programmers.

# Software design

`phylo-knit` consists of a server written in Python with Flask and a web page
written in JavaScript. The page sends the user's input to the server as JSON
and draws the network that the server sends back; the server also serves the
page itself, so the application can be used locally or deployed as a website
at any address.

On the server, networks are read, re-rooted and pruned with PhyloNetworks,
called from Python through juliacall, which also installs Julia
[@bezanson2017julia] and PhyloNetworks automatically on first use. Triplets are
passed to LEV1ATHAN, which builds a level-1 network and returns it in Newick
format. Every network is then converted to a graph description that the page
draws with a force-directed layout from d3. Edits made on the page, such as
re-rooting or hiding leaves, are sent back to the server, applied with
PhyloNetworks, and redrawn, so that the extended Newick string that users
download includes the re-rooting and pruning shown on screen.

HyDe results are converted to triplets before they are passed to LEV1ATHAN. For
each test with a $p$-value below a threshold chosen by the user, the putative
hybrid H with parents P1 and P2 contributes the two triplets H P1 | P2 and
H P2 | P1, which together imply a reticulation. A test that is not significant
contributes the single triplet H P1 | P2, which corresponds to HyDe's model
with an inheritance probability $\gamma = 0$. Because these default triplets
carry little information, users can supply a backbone tree; its triplets then
replace the defaults. A backbone network is first reduced to its major tree,
keeping at each hybrid node the parent edge with the larger $\gamma$. Both the
current HyDe results table and an older HyDe output format are accepted.

These choices involve trade-offs. Because PhyloNetworks and LEV1ATHAN do not
run in a browser, `phylo-knit` needs a server, unlike purely client-side
viewers; in return it can build and modify networks, not only draw them.
LEV1ATHAN restricts the networks built from triplets or HyDe results to
level-1 networks, in which reticulation cycles do not overlap; networks given
directly in extended Newick are not restricted. The force-directed layout lets
users arrange large networks by hand, at the cost of not producing a fixed,
tree-like layout. For deployment, the server runs under a production web
server with one Julia process per worker, since Julia must be called from the
main thread of its process.

The code is tested with a pytest suite that covers the conversion of each input
format, re-rooting and pruning, the error messages returned for invalid input,
and every server route, and the tests run on GitHub Actions for every change.
The repository documents installation, local use, deployment on a server and
the input formats.

# Research impact statement

<!-- TODO (authors): JOSS asks for evidence of use, not plans: papers, theses,
courses or groups that have used phylo-knit, and how. -->

# AI usage disclosure

Generative AI was used in preparing this software and paper. Claude (Opus 5.5,
Anthropic) was used through Claude Code to update the software's dependencies,
write the test suite, find and fix bugs, reorganize the repository, write
documentation, and produce a first draft of this paper. All changes were
proposed one at a time and reviewed by the authors before being accepted; the
authors made all design decisions, checked the scientific content, and revised
the text of this paper. <!-- TODO (authors): adjust to what was actually done,
and add any other AI tools used earlier in the project. -->

# Acknowledgements

<!-- TODO (authors): funding sources and grant numbers; contributors who are
not authors (for example, the GitHub user ritikam30 and Arrigo Coen). -->

# Figures

![The `phylo-knit` interface showing a network with ten taxa and two
reticulations, drawn from extended Newick input. Leaves, hybrid nodes and the
root are coloured differently; the menus at the top give access to the inputs,
the display settings and the downloads.\label{fig:screenshot}](figure1.png)

# References
