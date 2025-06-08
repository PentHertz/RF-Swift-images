#!/bin/bash

function jupyter_soft_install() {
	goodecho "[+] Installing Jupyter Notebook"
	install_dependencies "jupyter-notebook"
}


function ml_and_dl_soft_install() {
	goodecho "[+] Installing ML/DL tools"
	pip3install "scikit-learn pandas seaborn Tensorflow"
	pip3install 'numpy<2.0'
}
