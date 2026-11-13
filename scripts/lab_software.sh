#!/bin/bash

function jupyter_soft_install() {
	goodecho "[+] Installing Jupyter Notebook"
	# Ubuntu's tornado security updates broke the classic notebook's static files:
	# 6.5.4-0.1ubuntu0.1/0.2 raise "'FileFindHandler' object has no attribute
	# 'allowed_symlink_directory'" (HTTP 500), and 0.3 answers 403 for the JS that
	# python3-notebook symlinks into /usr/share; 0.4 fixes both (LP: #2172317).
	# Refresh the index here, because the Dockerfile's apt update layer sits above
	# COPY scripts and can stay cached. List python3-tornado explicitly, because
	# installing jupyter-notebook doesn't upgrade a tornado an earlier layer pulled in.
	apt-get update -q || criticalecho-noexit "[!] apt-get update reported errors, continuing with the lists that refreshed"
	install_dependencies "jupyter-notebook python3-tornado"
	jupyter_static_smoke_test
}

# Start the notebook briefly and fetch a plain static file plus one symlinked
# into /usr/share, so a broken tornado shows up in the build report.
function jupyter_static_smoke_test() {
	local port=18888 log=/tmp/jupyter-smoke.log pid result
	jupyter-notebook --allow-root --no-browser --ip=127.0.0.1 --port=$port \
		--NotebookApp.token='' --NotebookApp.port_retries=0 --notebook-dir=/tmp > "$log" 2>&1 &
	pid=$!
	result=$(python3 - "$port" <<'EOF'
import sys, time, urllib.error, urllib.request
base = f"http://127.0.0.1:{sys.argv[1]}/static/"
paths = ["base/images/favicon.ico", "components/jquery/jquery.min.js"]
for _ in range(30):
    try:
        urllib.request.urlopen(base, timeout=2)
    except urllib.error.HTTPError:
        break  # server is up (a 403/404 on the bare /static/ is fine)
    except OSError:
        time.sleep(1)
else:
    print("server did not start"); sys.exit()
bad = []
for p in paths:
    try:
        urllib.request.urlopen(base + p, timeout=5)
    except urllib.error.HTTPError as e:
        bad.append(f"{p}={e.code}")
print(" ".join(bad) or "ok")
EOF
)
	kill "$pid" 2>/dev/null || true
	wait "$pid" 2>/dev/null || true
	if [ "$result" = "ok" ]; then
		goodecho "[+] Jupyter Notebook serves its static files"
	else
		record_build_failure "check" "jupyter-notebook" "static files broken ($result), python3-tornado $(dpkg-query -W -f='${Version}' python3-tornado 2>/dev/null); log: $log"
	fi
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