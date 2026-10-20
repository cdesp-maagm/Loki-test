
const fields = document.querySelector("form").elements;

const dirtySet = new Set();
const openFoldableSet = new Set();

function markAsDirty(elt) {
    elt.parentElement.classList.add("dirty");
    dirtySet.add(elt.name);
    document.querySelector("input[name=dirty]").value = Array.from(dirtySet).join(" ");
}

function toggleFoldable(elt, index) {
    const close = elt.classList.contains("fold-open");
    if (close) {
        elt.classList.remove("fold-open");
        elt.classList.add("fold-closed");
        openFoldableSet.delete(index);
    }
    else {
        elt.classList.remove("fold-closed");
        elt.classList.add("fold-open");
        openFoldableSet.add(index);
    }

    fields.foldables.value = JSON.stringify(Array.from(openFoldableSet));

    while (true) {
        elt = elt.nextElementSibling;
        if (!elt || !elt.classList.contains("input-field")) {
            break;
        }
        elt.style.display = close ? "none" : "block";
    }
}

function updateField(name, value) {
    const elt = fields[name];
    elt.value = value;
    markAsDirty(elt);
}

function setOsc2Frequency(f) {
    updateField("mod_osc2_wave_frequency", f);

    if (demod_mixerless) {
        updateField("demod_xy_sampling_frequency", f);
        updateField("demod_sampling_frequency", f * demod_decimation);
    }
    else {
        updateField("demod_osc_wave_frequency", f);
    }
}

fields.mod_osc2_wave_frequency.addEventListener("change", evt => {
    setOsc2Frequency(evt.currentTarget.value);
});

fields.demod_osc_wave_frequency.addEventListener("change", evt => {
    setOsc2Frequency(evt.currentTarget.value);
});

fields.demod_sampling_frequency.addEventListener("change", evt => {
    const freq = evt.currentTarget.value;
    if (demod_mixerless) {
        setOsc2Frequency(freq / demod_decimation);
    }
    else {
        updateField("demod_xy_sampling_frequency", freq / demod_decimation);
        updateField("demod_sampling_frequency", freq);
    }
});

fields.demod_xy_sampling_frequency.addEventListener("change", evt => {
    const freq = evt.currentTarget.value;
    if (demod_mixerless) {
        setOsc2Frequency(freq);
    }
    else {
        updateField("demod_xy_sampling_frequency", freq);
        updateField("demod_sampling_frequency", freq * demod_decimation);
    }
});

const sizeUnits     = [[1e12, "T"], [1e9, "G"], [1e6, "M"], [1e3, "k"]];
const sizePrecision = 10;

function humanSize(value) {
    const us = sizeUnits.find(mu => value >= mu[0]);
    if (!us) {
        return value;
    }

    return Math.round(value * sizePrecision / us[0]) / sizePrecision + us[1];
}

let active = 0;
let startStopState = "pending";

function updateStatus() {
    const req = new XMLHttpRequest();

    if (active >= 2) {
        fields.active.value = "Unreachable";
    }
    else {
        active ++;
    }

    req.addEventListener("load", evt => {
        const resp = req.response;

        fields.modem_is_streaming.checked       = resp.modem_is_streaming;
        fields.env_sensors_is_streaming.checked = resp.env_sensors_is_streaming;
        fields.dropped_packets.value            = resp.modem_dropped_packets;

        const modemState = !resp.modem_is_streaming && !resp.modem_is_recording ? "stopped" :
                           resp.modem_is_streaming  && resp.modem_is_recording  ? "running" :
                                                                                  "pending";

        const envSensorsState = !resp.env_sensors_is_streaming && !resp.env_sensors_is_recording ? "stopped" :
                                resp.env_sensors_is_streaming  && resp.env_sensors_is_recording  ? "running" :
                                                                                                   "pending";

        startStopState = modemState === "stopped" && envSensorsState === "stopped" ? "stopped" :
                         modemState === "pending" || envSensorsState === "pending" ? "pending" :
                                                                                     "running";

        const btn = document.querySelector("#start-stop-button");
        switch (startStopState) {
            case "stopped": 
                btn.innerHTML = 'Start <i class="material-icons right">play_arrow</i>';
                btn.title = "Ready";
                btn.disabled = !fields.record_enable.checked && !fields.sensors_record_enable.checked;
                break;
            case "running": 
                btn.innerHTML = 'Stop <i class="material-icons right">stop</i>';
                btn.title = "Recording";
                btn.disabled = false;
                break;
            default:
                btn.querySelector("i").innerHTML = "hourglass_empty";
                btn.title = "Operation in progress";
                btn.disabled = true;
        }

        resp.demod_adc_min_ratio.forEach((r, i) => {
            fields[`demod_adc_min_ratio$${i}`].value = r;
        });
        resp.demod_adc_max_ratio.forEach((r, i) => {
            fields[`demod_adc_max_ratio$${i}`].value = r;
        });

        // Network info.
        fields.hostname.value    = resp.hostname;
        fields.mac_address.value = resp.mac_address;

        let ip_addresses_html = "";
        for (const [nic, ip] of Object.entries(resp.ip_addresses)) {
            ip_addresses_html += `<tr><th>${nic}</th><td>${ip}</td></tr>`;
        }
        document.querySelector("#ip_addresses").innerHTML = ip_addresses_html;

        // Activity
        active = 0;
        fields.active.value = "On";

        // Clock and NTP status
        fields.ntp_status.value = resp.ntp_status ? "Synchronized" : "Not synchronized";
        fields.clkmon_ppm.value = resp.clkmon_ppm;

        // Date and time. Do not update the field if focused or modified.
        const [date, time] = resp.datetime.split(/[T.]/);
        if (document.activeElement !== fields.datetime && !fields.datetime.parentElement.classList.contains("dirty")) {
            fields.datetime.value = `${date}, ${time}`;
        }

        // Uptime
        const ud = Math.floor(resp.uptime         / 86400)
        const uh = Math.floor(resp.uptime % 86400 / 3600);
        const um = Math.floor(resp.uptime % 3600  / 60);
        const us = Math.floor(resp.uptime % 60);
        fields.uptime.value = `${ud}d ${uh}:${um}:${us}`;

        // Disk usage
        if (typeof resp.disk_usage === "string") {
            fields.disk_usage.value = resp.disk_usage;
        }
        else {
            let [diskTotal, diskUsed, diskFree] = resp.disk_usage;
            diskRatio = Math.floor(100 * diskFree / diskTotal);
            diskFree  = humanSize(diskFree);
            diskTotal = humanSize(diskTotal);
            fields.disk_usage.value = `${diskFree} / ${diskTotal} (${diskRatio}%)`;
        }

        // Environment sensor values
        resp.env_sensors_values.forEach((val, chan) => {
            fields[`last_data$${chan}`].value = val;
        });

        // XADC values
        resp.xadc_values.forEach((val, chan) => {
            fields[`xadc_value$${chan}`].value = val;
        });

        // Hardware monitor values
        resp.hwmon_temp.forEach((val, chan) => {
            fields[`hwmon_temp$${chan}`].value = val;
        });
    });

    req.open("GET", "status");
    req.responseType = "json";
    req.send();
}

document.querySelector("#start-stop-button").addEventListener("click", evt => {
    if (startStopState === "pending") {
        return;
    }

    const btn = evt.currentTarget;
    btn.querySelector("i").innerHTML = "hourglass_empty";
    btn.disabled = true;

    const req = new XMLHttpRequest();
    req.addEventListener("load", updateStatus);
    req.open("GET", startStopState == "stopped" ? "start" : "stop");
    req.send();
});

document.querySelector("#load-button").addEventListener("click", evt => {
    document.querySelector("#file-input").click();
});

document.querySelector("#file-input").addEventListener("change", evt => {
    const fileInput = evt.currentTarget;

    if (!fileInput.files.length > 0) {
        return;
    }

    const reader = new FileReader();
    reader.addEventListener("load", evt => {
        const data = JSON.parse(fileInput.result);
        Object.keys(data).forEach(key => {
            const elt = fields[key];
            if (elt.type === "checkbox") {
                elt.checked = data[key];
            }
            else {
                elt.value = data[key];
            }
        });
    });
    reader.readAsText(fileInput.files[0]);
});

document.querySelector("#export-button").addEventListener("click", evt => {
    const data = {};
    for (let i = 0; i < fields.length; i ++) {
        const elt = fields[i];
        if (elt.name) {
            if (elt.type === "checkbox") {
                data[elt.name] = elt.checked;
            }
            else {
                data[elt.name] = elt.value;
            }
        }
    }
    window.open('data:application/json;charset=utf-8,' + escape(JSON.stringify(data)));
});

document.querySelector("#disp-reset-button").addEventListener("click", evt => {
    const icon = document.querySelector("#disp-reset-button i");
    icon.innerHTML = "hourglass_empty";

    const req = new XMLHttpRequest();
    req.addEventListener("load", () => icon.innerHTML = "restart_alt");
    req.open("GET", "disp-reset");
    req.send();
});

window.addEventListener("load", evt => {
    // Retirer les arguments de la requête dans l'URL.
    history.replaceState(null, "Loki", location.protocol + "//" + location.host + location.pathname + location.hash);

    // Détecter et marquer les champs modifiés.
    for (const f of document.querySelectorAll(".input-field")) {
        const g = f.querySelector("input:not([readonly]),select");
        if (g) {
            g.addEventListener("change", () => markAsDirty(g));
        }
    }

    // Gérer les sections repliables.
    for (const i of JSON.parse(fields.foldables.value)) {
        openFoldableSet.add(i);
    }

    const foldables = Array.from(document.querySelectorAll(".fold-open"));

    foldables.forEach((elt, index) => {
        elt.addEventListener("click", () => toggleFoldable(elt, index));
        if (!openFoldableSet.has(index)) {
            toggleFoldable(elt, index);
        }
    });

    // Effacer la zone de messages au bout de 5 secondes.
    function hideMessages(evt) {
        for (let m of document.querySelectorAll(".message")) {
            m.style.display = "none";
        }
    }

    setTimeout(hideMessages, 5000);

    // Gérer l'affichage des onglets.
    const tabs = {};
    for (let item of document.querySelectorAll(".tabs li")) {
        const selector = item.querySelector("a").getAttribute("href");
        const page = document.querySelector(selector);
        if (page) {
            tabs[selector] = {item, page};
        }
    }

    function showTab(evt) {
        if (evt) {
            evt.preventDefault();
        }

        const selector = window.location.hash in tabs ?
            window.location.hash :
            Object.keys(tabs)[0];

        for (let [h, t] of Object.entries(tabs)) {
            if (h === selector) {
                t.page.style.visibility = "visible";
                t.item.classList.add("active");
            }
            else {
                t.page.style.visibility = "hidden";
                t.item.classList.remove("active");
            }
        }

        window.scroll(0, 0);
    }

    showTab();
    window.addEventListener("hashchange", showTab);

    setInterval(updateStatus, 5000);
    updateStatus();
});
