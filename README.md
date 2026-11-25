# phylo-knit

`phylo-knit` is a web application that allows biologists to visualize complex phylogenetics networks and quickly generate publication-ready visuals. 
Newick, triplet, and HyDe file formats are accepted.

---

## Running phylo-knit on your computer

phylo-knit has two parts: a Python server that does the computations (using
Julia and Java), and a web page that runs in your browser and sends your
input to that server.

### Requirements

- Python 3.9 or newer (tested with 3.11 and 3.14)
- Java, any version from 6 on; the `java` command must be on your PATH
- Julia does not need to be installed: on the first start, the server
  downloads it if needed, along with the PhyloNetworks package

### Install (once)

```bash
git clone https://github.com/solislemuslab/phylo-knit.git
cd phylo-knit
python3 -m venv .venv
.venv/bin/pip install -r requirements.txt
```

On Windows, use `.venv\Scripts\pip` and `.venv\Scripts\python` instead of
`.venv/bin/pip` and `.venv/bin/python`.

### Start the server

```bash
cd src/Server
../../.venv/bin/python Server.py
```

The first start takes a few minutes while Julia and PhyloNetworks are set
up; later starts are faster. Leave the server running while you use the page.
It listens at `http://127.0.0.1:5001`.

### Open the page

Once the server is running, go to <http://127.0.0.1:5001/> in your web
browser: the server also serves the page. (Opening the file
`src/Website/index.html` directly works too; the page then sends its
requests to the server at that same address.)

If the page says it could not reach the phylo-knit server, check that the
server from the previous step is still running. After updating the code,
reload the page with a hard reload (Cmd+Shift+R on macOS, Ctrl+Shift+R on
Windows and Linux) so the browser does not use old copies of its files.

## Deploying on a server

These notes are for installing phylo-knit as a website, for example on a
university Linux server. Install it as described above (Python, Java, the
virtual environment and `requirements.txt`); only the way the server is run
changes.

1. **Set up Julia once.** As the user account that will run the website,
   start the server by hand once (`../../.venv/bin/python Server.py` in
   `src/Server`), wait until it prints `Running on http://127.0.0.1:5001`,
   and stop it with Ctrl+C. This first start downloads Julia and
   PhyloNetworks and takes several minutes; doing it ahead of time lets the
   website start quickly.

2. **Run it with a production web server.** `python Server.py` uses Flask's
   built-in server, which is meant for one person on one computer. For a
   website, use gunicorn:

   ```bash
   .venv/bin/pip install gunicorn
   cd src/Server
   ../../.venv/bin/gunicorn --workers 2 --timeout 300 --bind 127.0.0.1:5001 Server:app
   ```

   - Each worker is a separate process with its own copy of Julia. It
     handles one request at a time and uses about 800 MB of memory. Two
     workers serve two people at once; add more if memory allows.
   - `--timeout 300` gives large inputs time to finish. With gunicorn's
     default of 30 seconds, a long LEV1ATHAN run could be stopped halfway.
   - Do not use gunicorn's `--preload` option or more than one thread per
     worker (`--threads`, or a threaded worker class). Julia must be called
     from the main thread of the process that started it.

3. **Put it behind the web server that handles HTTPS** (for example nginx
   or Apache), forwarding requests to `http://127.0.0.1:5001`, with a time
   limit of at least 300 seconds for those requests. The page sends its
   requests to the address it was loaded from, so the code needs no changes
   for the site's address.

4. **Keep it running** with the server's service manager (for example a
   systemd service), so that it restarts after a reboot or a crash.

phylo-knit keeps no data: there are no accounts, and user input is not
stored. While a triplets or HyDe request runs, its input is written to a
temporary file in the system's temp folder, which is deleted when the
request ends.

---

## Basic Functionality

### __Create a network__

Under the `Inputs` tab, we accept extended Newick, triplets and `HyDe` formats, or you can choose from one of a few example extended Newick networks. Just upload your respective file or copy-paste your extended Newick and watch your network come to life!

<img src="readme_img/net1.png" width="600" />

### __Re-rooting the network__

After creating a network, click on the node that you want to make the new root. Click the button that appears and the re-rooted network will appear in just a few moments!

<img src="readme_img/reroot_img.png" />

---

## Input Types

### Parenthetical/Newick
- Read about it [here](https://en.wikipedia.org/wiki/Newick_format).
- We support the original Newick tree format as well as the [extended Newick format](https://en.wikipedia.org/wiki/Newick_format#Extended_Newick).

### Triplets
- Triplets files [define trees](https://www.researchgate.net/publication/220586945_Constructing_Evolutionary_Trees_from_Rooted_Triples) and [level-1 networks](https://leovaniersel.wordpress.com/wp-content/uploads/2014/09/practicallevel11.pdf) using relationships between sets of three taxa.
- Each line in a triplets file has the form `taxon1 taxon2 taxon3 [weight]`: taxa 1 and 2 are more closely related to each other than to taxon 3. The names are separated by spaces or tabs, so they cannot contain spaces.
- The `[weight]` is optional and must be a whole number. When triplets conflict, those with higher weights count more.
- An [example](https://skelk.sdf-eu.org/lev1athan/example.trips) is provided by the LEV1ATHAN authors.
- Read more under the section [LEV1ATHAN Basics](https://skelk.sdf-eu.org/lev1athan/).

### HyDe
- [HyDe](https://doi.org/10.1093/sysbio/syy023) output files can be used by LEV1ATHAN with internal conversion to triples files. Two formats are accepted (examples of both are in `src/InputFiles/`, in the files whose names start with `hyde_`):
  - the results table written by HyDe, filtered or unfiltered: the columns `P1`, `Hybrid`, `P2`, `Zscore`, `Pvalue` and `Gamma`, followed by the 15 site-pattern counts, separated by tabs, spaces or commas;
  - an older format, with one test per line: `Hybrid: 3 Parents: 2 and 4`, then the $z$-score and the $p$-value.
- The process and limitations are as follows:
  - As unfiltered HyDe results list all possible triples, it is necessary to input a $p$-value. Filtered HyDe results only output relationships that fall below the bonferroni-corrected $p$-value threshold, though further filtering below this $p$-value can also be performed.
  - Only hybrid relationships with a $p$-value strictly below the specified threshold will be converted to triples that specify hybrid relationships (that is, if P1 and P2 were putative parental lineages of hybrid `HYB`, we include triples `HYB P1 P2` and `HYB P2 P1`). For all other combinations of taxa (with a $p$-value at or above the threshold), we keep a single triple relationship per set of three taxa (that is, if P1, P2 and HYB had no hybrid relationship between them, we list only `HYB P1 P2`, with no other permutations: HyDe's model with $\gamma = 0$, in which `HYB` descends from P1 alone).
  - For this reason, **use of a backbone tree in Newick or extended Newick format is highly recommended**. Triples relationships extracted from the provided backbone tree or network are combined with the HyDe hybrid relationships' triples, avoiding the use of arbitrary sets of triples from a HyDe file.
  - If the backbone is a network (extended Newick with hybrid nodes), only its major tree is used: at each hybrid node, the parent edge with the larger inheritance probability ($\gamma$) is kept and the other is dropped. If the backbone gives no $\gamma$ values, which parent is kept is arbitrary, so give $\gamma$ values (or a tree) if it matters. The hybridizations in the result come from the HyDe results.

## Contributions

Users interested in expanding functionalities of `phylo-knit` are welcome to do so. See details on how to contribute in [CONTRIBUTING.md](https://github.com/solislemuslab/phylo-knit/blob/master/CONTRIBUTING.md).

## Citations

phylo-knit reads, re-roots and edits networks with
[PhyloNetworks](https://github.com/JuliaPhylo/PhyloNetworks.jl), and builds
networks from triplets with [LEV1ATHAN](https://skelk.sdf-eu.org/lev1athan/).
If you use phylo-knit, please cite PhyloNetworks; if you use triplets or HyDe
input, please also cite LEV1ATHAN, and for HyDe input, HyDe itself.

```bibtex
@article{solislemus2017phylonetworks,
  title   = {PhyloNetworks: A Package for Phylogenetic Networks},
  author  = {Sol{\'i}s-Lemus, Claudia and Bastide, Paul and An{\'e}, C{\'e}cile},
  journal = {Molecular Biology and Evolution},
  volume  = {34},
  number  = {12},
  pages   = {3292--3298},
  year    = {2017},
  doi     = {10.1093/molbev/msx235}
}

@article{huber2011practical,
  title   = {A Practical Algorithm for Reconstructing Level-1 Phylogenetic Networks},
  author  = {Huber, Katharina T. and van Iersel, Leo and Kelk, Steven and Suchecki, R.},
  journal = {IEEE/ACM Transactions on Computational Biology and Bioinformatics},
  volume  = {8},
  number  = {3},
  pages   = {635--649},
  year    = {2011},
  doi     = {10.1109/TCBB.2010.17}
}

@article{blischak2018hyde,
  title   = {HyDe: A Python Package for Genome-Scale Hybridization Detection},
  author  = {Blischak, Paul D. and Chifman, Julia and Wolfe, Andrea D. and Kubatko, Laura S.},
  journal = {Systematic Biology},
  volume  = {67},
  number  = {5},
  pages   = {821--829},
  year    = {2018},
  doi     = {10.1093/sysbio/syy023}
}
```

## License

Copyright (c) 2023 Solis-Lemus lab. phylo-knit is released under the [MIT License](LICENSE).
