# phylo-knit

**phylo-knit** is a web application that allows biologists to visualize complex phylogenetics networks and quickly generate publication-ready visuals. 
Newick, triplet, and HyDe file formats are accepted.

## Creating, updating, and re-rooting a network

Creating a network is as easily as selecting your preferred file type, uploading a file and clicking `Create Network`.

After a network is created, the `Displayed Leaves` section will populate. Here, you can uncheck any number of boxes and then press `Update Network` to change which leaves are displayed. This also removed any redundant internal nodes.

Finally, to re-root your network, click your desired new root (this should highlight the node), then click `Re-root Network`. _Note: Internal node radius, which can be adjusted in the style menu, must be greater than 0 to perform this operation._

---

## Input Types

### Parenthetical/Newick
- Read about it [here](https://en.wikipedia.org/wiki/Newick_format).
- We support the original Newick tree format as well as the [extended Newick format](https://en.wikipedia.org/wiki/Newick_format#Extended_Newick).

### Triplets
- 

### HyDe
- make sure to note the $p$-value and backbone tree

## Visual options





## License

    Copyright [2023] Solis-Lemus lab

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
