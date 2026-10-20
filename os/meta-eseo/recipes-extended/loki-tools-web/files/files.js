
function getFileInfo(name, prefix) {
    // Match  the base file name and remove it if present.
    if (!name.startsWith(`${prefix}-`)) {
        return {valid: false};
    }
    name = name.slice(prefix.length + 1);

    // Match the fields of the file name.
    //                    content year   month  day     hours  mins   s.ms      tz   chan     format
    const m = name.match(/([^_]+)_(\d{4})(\d{2})(\d{2})T(\d{2})(\d{2})(\d+\.\d+)Z(?:_(\d+))?\.([a-z]+)/);
    if (!m) {
        return {valid: false};
    }

    let result = {valid: true};

    switch (m[1]) {
        case "env": result.contentType = "Environment sensors"; break;
        case "xy":  result.contentType = "I/Q samples";         break;
        case "d":   result.contentType = "Displacement";        break;
        default:    result.contentType = "Other"; result.valid = false;
    }

    result.date = `${m[2]}-${m[3]}-${m[4]} ${m[5]}:${m[6]}:${m[7]} (UTC)`;
    result.channel = parseInt(m[8]);
    if (isNaN(m[8])) {
        result.channel = "Multiple";
    }

    switch (m[9]) {
        case "mseed": result.format = "MiniSEED"; break;
        case "raw":   result.format = "Raw";      break;
        default:      result.format = "Other"; result.valid = false;
    }

    return result;
}

function update() {
    const req = new XMLHttpRequest();

    req.addEventListener("load", evt => {
        const resp = req.response;

        document.querySelector("input[name=path]").value = resp.path;
        document.querySelector("input[name=filename]").value = resp.filename;

        const fileList = document.querySelector("#file-list tbody");
        if (resp.error) {
            fileList.innerHTML = "<tr><td>(error)</td></tr>";
        }
        else if (!resp.files.length) {
            fileList.innerHTML = "<tr><td>(empty)</td></tr>";
        }
        else {
            fileList.innerHTML = "";
            for (const entry of resp.files) {
                const info = getFileInfo(entry.name, resp.filename);

                if (!info.valid) {
                    continue;
                }

                const downloadLink = document.createElement("a");
                downloadLink.innerHTML = '<i class="material-icons">file_download</i>'
                downloadLink.href = `services/download?path=${resp.path}/${entry.name}`;
                downloadLink.download = entry.name;

                const downloadCell = document.createElement("td");
                downloadCell.appendChild(downloadLink);

                const typeCell = document.createElement("td");
                typeCell.innerHTML = info.contentType;

                const dateCell = document.createElement("td");
                dateCell.innerHTML = info.date;

                const channelCell = document.createElement("td");
                channelCell.innerHTML = info.channel;

                const formatCell = document.createElement("td");
                formatCell.innerHTML = info.format;

                const sizeCell = document.createElement("td");
                sizeCell.innerHTML = entry.size;

                const fileRow = document.createElement("tr");
                fileRow.appendChild(downloadCell);
                fileRow.appendChild(typeCell);
                fileRow.appendChild(dateCell);
                fileRow.appendChild(channelCell);
                fileRow.appendChild(formatCell);
                fileRow.appendChild(sizeCell);

                fileRow.addEventListener("click", () => downloadLink.click());

                fileList.appendChild(fileRow);
            }
        }
    });

    req.open("GET", "services/files");
    req.responseType = "json";
    req.send();
}

window.addEventListener("load", evt => {
    setInterval(update, 5000);
    update();
});

