<!--
*** Thanks for checking out the Best-README-Template. If you have a suggestion
*** that would make this better, please fork the repo and create a pull request
*** or simply open an issue with the tag "enhancement".
*** Thanks again! Now go create something AMAZING! :D
-->



<!-- PROJECT SHIELDS -->
<!--
*** I'm using markdown "reference style" links for readability.
*** Reference links are enclosed in brackets [ ] instead of parentheses ( ).
*** See the bottom of this document for the declaration of the reference variables
*** for contributors-url, forks-url, etc. This is an optional, concise syntax you may use.
*** https://www.markdownguide.org/basic-syntax/#reference-style-links
-->




<!-- PROJECT LOGO -->


  <h3 align="center">Phylo-knit Developer Guide</h3>

  <p align="center">
    This is the developer guide for Phylo-knit Project
    <br />
</p>



<!-- TABLE OF CONTENTS -->
<details open="open">
  <summary>Table of Contents</summary>
  <ol>
    <li>
      <a href="#about-the-project">About The Project</a>
      <ul>
        <li><a href="#Requirements">Built With</a></li>
      </ul>
    </li>
    <li>
      <a href="#getting-started">Getting Started</a>
      <ul>
        <li><a href="#prerequisites">Backend-Flow</a></li>
        <li><a href="#installation">Frontend-Flow</a></li>
      </ul>
    </li>
    <li><a href="#usage">Server.py()</a></li>
    <li><a href="#roadmap">ServerAction.py()</a></li>
    <li><a href="#contributing">Testing</a></li>
    <li><a href="#license">Sketch.js</a></li>
    <li><a href="#contact">Contact</a></li>
    <li><a href="#acknowledgements">Acknowledgements</a></li>
  </ol>
</details>



<!-- ABOUT THE PROJECT -->
## About The Project

[![Product Name Screen Shot][product-screenshot]](https://example.com)

This is the developer guide for the Phylo-knit visualization project. This Project allows the visualization of phylogentic data in the form of the three formats (Hyde,Parenthetical and Triplet format). This guide allows a better udnerstanding of the project for any future developers and for myself to understanding the current level of the project

Here's why:
* This Project is Flask based application. Uses python for file processing to generate dot files. 
* Dot files are then are used by sketch.js to create an interactive network.  

Of course, This is a very basic overview of the project and this guide will slowly ease you into being fully fleged and able to work on this project. 


### Requirements

1. Install python3. To check try ```python3 --version```

2. Install pip3

3. Install python3 packages using pip3
* ```pip3 install -U flask-cors```
* ```pip3 install pydot```
* ```pip3 install pandas```
* ```pip3 install numpy```
* ```pip3 install flask```

4. JRE 8 & JDK. To check try ```java --version``` or ```java -version```

5. [JQuery](https://jquery.com)




<!-- GETTING STARTED -->
## Getting Started

1. Go to Server and Run the python script using ```python3 Server.py```

2. Navigate to phylo-knit/New/Website/, and open index.html. This should open a browser window with the website.

3. Try Entering a file format and using one of the files in Input files and see the visualization take place

### Backend Flow

A basic understanding of get/post requests might be needed. Here is overview of the backend:

* Server.py: This file handles all the get/post requests from the user input and accordingly calls methods from the Serveraction.py file.

* ServerAction.py: This file handles all processing of the uplaoded documennt (the type of file is provided via a get call from Server.py) after the file type has been processed it is converted to a dot file using the jar file lev1thian.jar in the Server folder. Hyde and triplet Files are converted via the jar file where as server action has seperate methods for converting parenthical files to dot. Please see parentheticaltoDot method for more info

* Lev1athan.jar : This file runs the levithan algorithim on our processed files (Triplet files) to create dot file. See cExample1.dot for an example on how a dot file would look.



### Installation

1. Get a free API Key at [https://example.com](https://example.com)
2. Clone the repo
   ```sh
   git clone https://github.com/your_username_/Project-Name.git
   ```
3. Install NPM packages
   ```sh
   npm install
   ```
4. Enter your API in `config.js`
   ```JS
   const API_KEY = 'ENTER YOUR API';
   ```



<!-- USAGE EXAMPLES -->
## Usage

Use this space to show useful examples of how a project can be used. Additional screenshots, code examples and demos work well in this space. You may also link to more resources.

_For more examples, please refer to the [Documentation](https://example.com)_



<!-- ROADMAP -->
## Roadmap

See the [open issues](https://github.com/othneildrew/Best-README-Template/issues) for a list of proposed features (and known issues).



<!-- CONTRIBUTING -->
## Contributing

Contributions are what make the open source community such an amazing place to be learn, inspire, and create. Any contributions you make are **greatly appreciated**.

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request



<!-- LICENSE -->
## License

Distributed under the MIT License. See `LICENSE` for more information.



<!-- CONTACT -->
## Contact

Your Name - [@your_twitter](https://twitter.com/your_username) - email@example.com

Project Link: [https://github.com/your_username/repo_name](https://github.com/your_username/repo_name)



<!-- ACKNOWLEDGEMENTS -->
## Acknowledgements
* [GitHub Emoji Cheat Sheet](https://www.webpagefx.com/tools/emoji-cheat-sheet)
* [Img Shields](https://shields.io)
* [Choose an Open Source License](https://choosealicense.com)
* [GitHub Pages](https://pages.github.com)
* [Animate.css](https://daneden.github.io/animate.css)
* [Loaders.css](https://connoratherton.com/loaders)
* [Slick Carousel](https://kenwheeler.github.io/slick)
* [Smooth Scroll](https://github.com/cferdinandi/smooth-scroll)
* [Sticky Kit](http://leafo.net/sticky-kit)
* [JVectorMap](http://jvectormap.com)
* [Font Awesome](https://fontawesome.com)





<!-- MARKDOWN LINKS & IMAGES -->
<!-- https://www.markdownguide.org/basic-syntax/#reference-style-links -->
[contributors-shield]: https://img.shields.io/github/contributors/othneildrew/Best-README-Template.svg?style=for-the-badge
[contributors-url]: https://github.com/othneildrew/Best-README-Template/graphs/contributors
[forks-shield]: https://img.shields.io/github/forks/othneildrew/Best-README-Template.svg?style=for-the-badge
[forks-url]: https://github.com/othneildrew/Best-README-Template/network/members
[stars-shield]: https://img.shields.io/github/stars/othneildrew/Best-README-Template.svg?style=for-the-badge
[stars-url]: https://github.com/othneildrew/Best-README-Template/stargazers
[issues-shield]: https://img.shields.io/github/issues/othneildrew/Best-README-Template.svg?style=for-the-badge
[issues-url]: https://github.com/othneildrew/Best-README-Template/issues
[license-shield]: https://img.shields.io/github/license/othneildrew/Best-README-Template.svg?style=for-the-badge
[license-url]: https://github.com/othneildrew/Best-README-Template/blob/master/LICENSE.txt
[linkedin-shield]: https://img.shields.io/badge/-LinkedIn-black.svg?style=for-the-badge&logo=linkedin&colorB=555
[linkedin-url]: https://linkedin.com/in/othneildrew
[product-screenshot]: images/screenshot.png
