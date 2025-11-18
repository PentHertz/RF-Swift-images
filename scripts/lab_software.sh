#!/bin/bash

function jupyter_soft_install() {
	goodecho "[+] Installing Jupyter Notebook"
	install_dependencies "jupyter-notebook"
}


function ml_and_dl_soft_install() {
    goodecho "[+] Installing ML/DL tools"
    pip3 install "numpy>=1.26.0,<2.0" scikit-learn pandas seaborn tensorflow --break-system-packages
}