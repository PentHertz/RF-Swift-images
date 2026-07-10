#!/bin/bash

function jupyter_soft_install() {
	goodecho "[+] Installing Jupyter Notebook"
	install_dependencies "jupyter-notebook"
}


function ml_and_dl_soft_install() {
    goodecho "[+] Installing ML/DL tools"
    # Core scientific stack first — wheels exist for the image's Python, so this
    # no longer hinges on TensorFlow being installable. Dropped the old numpy<2.0
    # pin: it was there for legacy TensorFlow, but on Python 3.14 numpy 1.26 has no
    # wheel (it caps at CPython <3.13) and pip falls back to a slow 1.26.4 source
    # build; numpy 2.x ships cp314 wheels and is supported by scikit-learn/pandas/seaborn.
    pip3 install --break-system-packages --ignore-installed typing_extensions \
        numpy scikit-learn pandas seaborn

    # TensorFlow lags new CPython releases (no cp314 wheel as of this image's
    # Python 3.14: "No matching distribution found for tensorflow"), so install it
    # best-effort — if there's no wheel for the running interpreter, record it in
    # the build report and continue instead of aborting the whole ML/DL stage.
    if pip3 install --break-system-packages tensorflow; then
        goodecho "[+] TensorFlow installed"
    else
        record_build_failure "pip" "tensorflow" "no wheel for $(python3 --version 2>&1); needs CPython <=3.13"
    fi
}