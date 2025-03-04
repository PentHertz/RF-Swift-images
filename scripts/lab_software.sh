#!/bin/bash

function jupyter_soft_install() {
	goodecho "[+] Installing Jupyter lab"
	pip3install "jupyterlab"
	goodecho "[+] Installing Jupyter lab"
	pip3install "notebook"
}


function ml_and_dl_soft_install() {
	goodecho "[+] Installing ML/DL tools"
	pip3install "scikit-learn pandas seaborn Tensorflow"
}
