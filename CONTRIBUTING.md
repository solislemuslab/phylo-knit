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

---

_These Contributing Guidelines have been adapted from the [Contributing Guidelines](https://github.com/atomneb/AtomNeb-py/blob/master/CONTRIBUTING.md) of [The Turing Way](https://github.com/atomneb/AtomNeb-py)! (License: MIT)_