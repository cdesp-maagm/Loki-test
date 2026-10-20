
const receiverReopenTimeoutMs = 1000;
const receiverKeepAliveTimeoutMs = 30000;

class Receiver {
    constructor(url, sampleSize) {
        this.url        = url;
        this.sampleSize = sampleSize;
        this.open();
    }

    get length() {
        return Math.floor((this.totalSize - this.offset) / this.sampleSize);
    }

    open() {
        this.buffers   = [];
        this.totalSize = 0;
        this.offset    = 0;

        this.ws = new WebSocket(this.url, "binary");
        this.ws.binaryType = "arraybuffer";
        this.ws.onmessage = evt => {
            this.buffers.push(evt.data);
            this.totalSize += evt.data.byteLength;
        };
        this.ws.onerror = evt => {
            console.log(`${this.url} - WebSocket error: ${evt}`);
        }
        this.ws.onclose = evt => {
            console.log(`${this.url} - WebSocket closed: code=${evt.code}, reason=${evt.reason}, timestamp=${Date.now()}`);
            setTimeout(() => this.open(), receiverReopenTimeoutMs);
        };
        if (!this.keepAliveId) {
            this.keepAlive();
        }
    }

    // Conserver la connexion active en envoyant périodiquement un message vide
    // au serveur. Le protocole WebSocket devrait supporter des échanges de messages
    // ping/pong automatiquement mais ça ne fonctionne ni avec Firefox ni avec Chrome.
    keepAlive() {
        if (this.ws.readyState === WebSocket.OPEN) {
            this.ws.send('');
        }
        this.keepAliveId = setTimeout(() => this.keepAlive(), receiverKeepAliveTimeoutMs);
    }

    reopen() {
        console.log(`${this.url} - Reopening WebSocket`);
        this.ws.close(1000, "reopen");
    }

    read(index) {
        // Trouver le buffer qui contient l'échantillon demandé.
        let byteIndex     = index * this.sampleSize + this.offset;
        const bufferIndex = this.buffers.findIndex(b => {
            const found = byteIndex < b.byteLength;
            if (!found) {
                byteIndex -= b.byteLength;
            }
            return found;
        });
        if (bufferIndex < 0) {
            return null;
        }
        const buffer = this.buffers[bufferIndex];

        const nextByteIndex = byteIndex + this.sampleSize;
        if (nextByteIndex <= buffer.byteLength) {
            // Si un échantillon entier est disponible dans ce buffer,
            // retourner la tranche correspondante.
            return buffer.slice(byteIndex, nextByteIndex);
        }
        else {
            // Si l'échantillon n'est pas complet, prendre la fin du buffer courant
            // et la concaténer avec le début du buffer suivant.
            if (bufferIndex === this.buffers.length - 1) {
                return null;
            }
            const left   = buffer.slice(byteIndex, buffer.byteLength);
            const right  = this.buffers[bufferIndex + 1].slice(0, this.sampleSize - left.byteLength);
            const result = new Uint8Array(this.sampleSize);
            result.set(new Uint8Array(left), 0);
            result.set(new Uint8Array(right), left.byteLength);
            return result.buffer;
        }
    }

    keep(count) {
        this.drop(this.length - count);
    }

    drop(count) {
        if (count <= 0) {
            return;
        }
        if (count > this.length) {
            count = this.length;
        }

        let dropBytes = count * this.sampleSize + this.offset;
        while (this.buffers.length && dropBytes >= this.buffers[0].byteLength) {
            const buffer    = this.buffers.shift();
            dropBytes      -= buffer.byteLength;
            this.totalSize -= buffer.byteLength;
        }
        this.offset = dropBytes;
    }
}

// Marge intérieure du canvas pour l'affichage de l'ellipse, en pixels.
const padding  = 10;
const spacing  = 10;
const xNormMax = 1.5;

function resize() {
    const parent      = xyCanvas.parentNode;
    const top         = parent.getBoundingClientRect().top + spacing;
    const totalWidth  = window.innerWidth;
    const totalHeight = window.innerHeight - top;

    const xyWidth = (totalHeight - 2 * spacing) / 2;
    xyCanvas.style.left     = xyAxisCanvas.style.left     = spacing + "px";
    xyCanvas.style.top      = xyAxisCanvas.style.top      = top     + "px";
    xyCanvas.width          = xyAxisCanvas.width          = xyWidth;
    xyCanvas.height         = xyAxisCanvas.height         = xyWidth;
    xyNormCanvas.style.left = xyNormAxisCanvas.style.left = spacing + "px";
    xyNormCanvas.style.top  = xyNormAxisCanvas.style.top  = (window.innerHeight - xyWidth - spacing) + "px";
    xyNormCanvas.width      = xyNormAxisCanvas.width      = xyWidth;
    xyNormCanvas.height     = xyNormAxisCanvas.height     = xyWidth;

    const dispWidth  = totalWidth - xyWidth - 3 * spacing;
    const dispHeight = totalHeight / record_channels.length - spacing;

    for (let c of record_channels) {
        const dc = dispCanvas[c];
        const ac = dispAxisCanvas[c];
        dc.style.right = ac.style.right = spacing + "px";
        dc.style.top   = ac.style.top   = (top + record_channels.indexOf(c) * (dispHeight + spacing)) + "px";
        dc.width       = ac.width       = dispWidth;
        dc.height      = ac.height      = dispHeight;
    }
}

window.onresize = requestAnimationFrame(resize);

function getColor(c) {
    return (c * 101) % 360;
}

const channelFields = document.querySelectorAll("input[type=checkbox]");
const selectedChannels = new Array(demod_channels);

let timeStep = 17e-3;
let timestampPrev = null;
let a = 0.01, b = 1 - a;

function animationFrame() {
    return new Promise(resolve => {
        requestAnimationFrame(ts => {
            if (timestampPrev !== null && ts !== timestampPrev) {
                rawTimeStep = (ts - timestampPrev) / 1000;
                timeStep = b * timeStep + a * rawTimeStep;
            }
            timestampPrev = ts;
            resolve();
        });
    });
}

window.onload = () => {
    for (let c of record_channels) {
        const field = document.querySelector(`input[name='enable-${c}']`)
        selectedChannels[c] = field.checked;
        field.onchange = () => {
            selectedChannels[c] = field.checked;
        };

        const legend = document.querySelector(`#legend-${c}`);
        const cdeg = getColor(c);
        legend.style.background = `hsl(${cdeg}deg, 60%, 50%)`;
    }

    resize();
    plotXY();
    plotDisplacement();
};

/* -------------------------------------------------------------------------- *
 *  Réception et affichage des données en sortie du démodulateur.
 * -------------------------------------------------------------------------- */

const xyRetentionTime   = 0.1;
const xySampleFreq      = 50000; // TODO obtenir cette valeur depuis le serveur.
const xySampleSize      = 3 * 4;
const xyRetentionLength = Math.round(xyRetentionTime * xySampleFreq * record_channels.length);
const xyCanvas          = document.getElementById("xy-canvas");
const xyAxisCanvas      = document.getElementById("xy-axis-canvas");
const xyNormCanvas      = document.getElementById("xy-norm-canvas");
const xyNormAxisCanvas  = document.getElementById("xy-norm-axis-canvas");

const xyReceiver = new Receiver(`ws://${window.location.host}/stream/xy`, xySampleSize);

function readXY(index) {
    const buffer = xyReceiver.read(index);
    if (buffer === null) {
        return null;
    }
    const u = new Uint32Array(buffer);
    const f = new Float32Array(buffer);
    return {channel: u[0], x: f[1], y: f[2]}
}

function drawXYAxis(canvas, xmin, xmax, ymin, ymax, scale, unitCircle=false) {
    const ctx = canvas.getContext("2d");
    const centerX = canvas.width  / 2;
    const centerY = canvas.height / 2;

    ctx.clearRect(0, 0, canvas.width, canvas.height);

    ctx.strokeStyle = "black";
    ctx.lineWidth = 1;

    // Axe vertical
    ctx.beginPath();
    ctx.moveTo(centerX, 0);
    ctx.lineTo(centerX, canvas.height);
    ctx.stroke();

    // Axe horizontal
    ctx.beginPath();
    ctx.moveTo(0, centerY);
    ctx.lineTo(canvas.width, centerY);
    ctx.stroke();

    // Graduation à droite.
    ctx.beginPath();
    ctx.moveTo(canvas.width - padding, centerY - 4);
    ctx.lineTo(canvas.width - padding, centerY + 4)
    ctx.stroke();

    // Graduation à gauche.
    ctx.beginPath();
    ctx.moveTo(padding, centerY - 4);
    ctx.lineTo(padding, centerY + 4)
    ctx.stroke();

    // Graduation en bas.
    ctx.beginPath();
    ctx.moveTo(centerX - 4, canvas.height - padding);
    ctx.lineTo(centerX + 4, canvas.height - padding)
    ctx.stroke();

    // Graduation en haut.
    ctx.beginPath();
    ctx.moveTo(centerX - 4, padding);
    ctx.lineTo(centerX + 4, padding)
    ctx.stroke();

    // Cercle unité.
    if (unitCircle) {
        ctx.beginPath();
        ctx.arc(centerX, centerX, scale, 0, 2 * Math.PI);
        ctx.stroke();
    }

    ctx.font = "20px sans-serif";
    const xLabel = Math.round((centerX - padding) * 1000 / scale) / 1000;
    const yLabel = Math.round((centerY - padding) * 1000 / scale) / 1000;

    ctx.textAlign = "right";
    ctx.textBaseline = "alphabetic";
    ctx.fillText(xLabel,  canvas.width - padding, centerY - 8);
    ctx.textAlign = "left";
    ctx.fillText(-xLabel, padding, centerY - 8);
    ctx.fillText(-yLabel,  centerX + 8, canvas.height - padding);
    ctx.textBaseline = "hanging";
    ctx.fillText(yLabel, centerX + 8, padding);
}

function getXYFrameLength() {
    return Math.round(timeStep * xySampleFreq) * record_channels.length;
}

async function plotXY() {
    const centerX = xyCanvas.width / 2;
    const centerY = xyCanvas.height / 2;
    const ctx     = xyCanvas.getContext("2d");

    // Les seuils initiaux pour l'hysteresis.
    let xlow  = Infinity, xhigh = -Infinity;
    let ylow  = Infinity, yhigh = -Infinity;

    xy_loop: while (true) {
        xyReceiver.keep(xyRetentionLength);

        const xyLength = xyReceiver.length;
        if (xyLength < getXYFrameLength()) {
            await animationFrame();
            continue;
        }

        // Déterminer les bornes de x et y.
        let xmax = -Infinity, ymax = -Infinity;
        for (let i = 0; i < xyLength; i ++) {
            const sample = readXY(i);
            if (!sample) {
                continue xy_loop;
            }
            if (selectedChannels[sample.channel]) {
                const ax = Math.abs(sample.x);
                const ay = Math.abs(sample.y);
                if (sample.channel < demod_channels && selectedChannels[sample.channel]) {
                    xmax = ax > xmax ? ax : xmax;
                    ymax = ay > ymax ? ay : ymax;
                }
            }
        }

        if (xmax > xhigh || xmax < xlow) {
            xhigh = xmax * 1.2;
            xlow  = xmax * 0.6;
        }
        xmax = xhigh * 1.1;

        if (ymax > yhigh || ymax < ylow) {
            yhigh = ymax * 1.2;
            ylow  = ymax * 0.6;
        }
        ymax = yhigh * 1.1;

        // Calculer la transformation de coordonnées du canvas.
        const scaleX  = (centerX - padding) / xmax;
        const scaleY  = (centerY - padding) / ymax;
        const scale   = Math.min(scaleX, scaleY);
        const r       = 1.5 / scale;

        // Effacer le canvas et appliquer la transformation de coordonnées.
        drawXYAxis(xyAxisCanvas, -xmax, xmax, -ymax, ymax, scale);
        ctx.setTransform(1, 0, 0, 1, 0, 0);
        // ctx.clearRect(0, 0, xyCanvas.width, xyCanvas.height);
        ctx.fillStyle = "rgba(255, 255, 255, 70%)";
        ctx.fillRect(0, 0, xyCanvas.width, xyCanvas.height);

        // Dessiner les points en sortie du démodulateur.
        ctx.save();
        ctx.setTransform(scale, 0, 0, -scale, centerX, centerY);

        let frameLength = getXYFrameLength();
        for (let i = 0; i < xyLength; i += frameLength) {
            let jmax = i + frameLength;
            if (jmax > xyLength) {
                jmax = xyLength;
            }
            for (let j = i; j < jmax; j ++) {
                const sample = readXY(j);
                if (!sample) {
                    continue xy_loop;
                }
                if (selectedChannels[sample.channel]) {
                    ctx.beginPath();
                    ctx.ellipse(sample.x, sample.y, r, r, 0, 0, Math.PI * 2);
                    const cdeg = getColor(sample.channel);
                    ctx.fillStyle = `hsl(${cdeg}deg, 60%, 50%)`;
                    ctx.fill();
                }
            }
            await animationFrame();
            frameLength = getXYFrameLength();
        }

        ctx.restore();
    }
}

/* -------------------------------------------------------------------------- *
 *  Réception et affichage des déplacements.
 * -------------------------------------------------------------------------- */

const dispRetentionTime   = 10;
const dispSampleFreq      = 200; // TODO obtenir cette valeur depuis le serveur.
const dispSampleSize      = 4 * 4;
const dispRetentionLength = Math.round(dispRetentionTime * dispSampleFreq * record_channels.length);
const dispAxisCanvas      = new Array(demod_channels);
const dispCanvas          = new Array(demod_channels);
for (let c of record_channels) {
    dispCanvas[c]     = document.getElementById(`disp-canvas-${c}`);
    dispAxisCanvas[c] = document.getElementById(`disp-axis-canvas-${c}`);
}

const xyNormRetentionLength = Math.round(xyRetentionTime * dispSampleFreq * record_channels.length);

const dispReceiver = new Receiver(`ws://${window.location.host}/stream/d`, dispSampleSize);

function readDisp(index) {
    const buffer = dispReceiver.read(index);
    if (buffer === null) {
        return null;
    }
    const u = new Uint32Array(buffer);
    const f = new Float32Array(buffer);
    return {channel: u[0], d: f[1], x: f[2], y: f[3]}
}

function drawDisplacementAxis(channel, dmin, dmax) {
    const canvas  = dispAxisCanvas[channel];
    const ctx     = canvas.getContext("2d");
    const centerY = canvas.height / 2;

    ctx.clearRect(0, 0, canvas.width, canvas.height);

    // Dessiner les axes et les indicateurs d'échelle.
    ctx.strokeStyle = "black";
    ctx.lineWidth = 1;

    ctx.beginPath();
    ctx.moveTo(0, centerY);
    ctx.lineTo(canvas.width, centerY);
    ctx.stroke();

    ctx.beginPath();
    ctx.moveTo(canvas.width - padding, centerY - 4);
    ctx.lineTo(canvas.width - padding, centerY + 4)
    ctx.stroke();

    ctx.beginPath();
    ctx.moveTo(padding, centerY - 4);
    ctx.lineTo(padding, centerY + 4)
    ctx.stroke();

    ctx.beginPath();
    ctx.moveTo(0, canvas.height - padding);
    ctx.lineTo(4, canvas.height - padding)
    ctx.stroke();

    ctx.beginPath();
    ctx.moveTo(0, padding);
    ctx.lineTo(4, padding);
    ctx.stroke();

    ctx.font = "20px sans-serif";
    const xLabel = Math.round(dispRetentionTime * 1000) + " ms";
    const yLabel = (dmax + dmin) / 2;
    const dLabel = (dmax - dmin) / 2;

    ctx.textAlign = "left";
    ctx.textBaseline = "alphabetic";
    ctx.fillText(yLabel,  8, centerY - 8);
    ctx.fillText(-dLabel, 8, canvas.height - padding);
    ctx.textBaseline = "hanging";
    ctx.fillText("0 ms", padding, centerY + 8);
    ctx.fillText("+" + dLabel, 8, padding);
    ctx.textAlign = "right";
    ctx.fillText(xLabel, canvas.width - padding, centerY + 8);
}

function getDispFrameLength() {
    return Math.round(timeStep * dispSampleFreq) * record_channels.length;
}

async function plotDisplacement() {
    const dispCtx     = dispCanvas.map(c => c && c.getContext("2d"));
    const width       = dispCanvas[record_channels[0]].width;
    const height      = dispCanvas[record_channels[0]].height;
    const leftX       = padding;
    const scaleX      = (width - 2 * padding) * record_channels.length / dispRetentionLength;

    const xyNormCtx   = xyNormCanvas.getContext("2d");
    const xyNormWidth = xyNormAxisCanvas.width;
    const xyNormScale = (xyNormWidth / 2 - padding) / xNormMax;
    const r           = 1.5 / xyNormScale;

    const dmin = new Array(demod_channels);
    const dmax = new Array(demod_channels);

    disp_loop: while (true) {
        // Ne démarrer qu'après réception d'un nombre d'échantillons correspondant
        // à une trame d'animation.
        while (dispReceiver.length < getDispFrameLength()) {
            await animationFrame();
        }
        const dispLength = dispReceiver.length;

        // Déterminer les bornes du déplacement.
        for (let c of record_channels) {
            dmin[c] = Infinity;
            dmax[c] = -Infinity;
        }
        for (let i = 0; i < dispLength; i ++) {
            const sample = readDisp(i);
            if (!sample) {
                continue disp_loop;
            }
            if (sample.channel < demod_channels && selectedChannels[sample.channel]) {
                if (sample.d < dmin[sample.channel]) {
                    dmin[sample.channel] = sample.d;
                }
                if (sample.d > dmax[sample.channel]) {
                    dmax[sample.channel] = sample.d;
                }
            }
        }

        // Redessiner les axes.
        for (let c of record_channels) {
            if (selectedChannels[c]) {
                drawDisplacementAxis(c, dmin[c], dmax[c]);
            }
        }

        drawXYAxis(xyNormAxisCanvas, -xNormMax, xNormMax, -xNormMax, xNormMax, xyNormScale, true);

        // Effacer/atténuer les tracés précédents.
        for (let c of dispCtx) {
            if (!c) {
                continue;
            }
            c.setTransform(1, 0, 0, 1, 0, 0);
            c.fillStyle = "rgba(255, 255, 255, 70%)";
            c.fillRect(0, 0, width, height);
            // c.clearRect(0, 0, width, height);
        }

        // Démarrer le tracé des nouvelles données.
        let frameStart = 0, frameEnd = -1;
        const dPrev = new Array(demod_channels);

        let frameLength = getDispFrameLength();
        for (let i = 0; i < dispRetentionLength; i += frameLength) {
            // Attendre d'avoir reçu assez d'échantillons pour afficher la trame courante.
            while (dispReceiver.length < i + frameLength) {
                await animationFrame();
            }

            if (i % xyNormRetentionLength === 0) {
                xyNormCtx.setTransform(1, 0, 0, 1, 0, 0);
                xyNormCtx.fillStyle = "rgba(255, 255, 255, 30%)";
                xyNormCtx.fillRect(0, 0, xyNormWidth, xyNormWidth);
                xyNormCtx.setTransform(xyNormScale, 0, 0, -xyNormScale, xyNormWidth / 2, xyNormWidth / 2);
            }

            let jmax = i + frameLength;
            let k, kPrev;

            for (let c of record_channels) {
                if (!selectedChannels[c]) {
                    continue;
                }

                // Calculer la transformation de coordonnées des canvas.
                const scaleY = (height - 2 * padding) / (dmax[c] - dmin[c]);
                const deltaY = height / 2 + padding + scaleY * (dmax[c] + dmin[c]) / 2;

                // Affecter la couleurs de tracé pour cette voie.
                const cdeg = getColor(c);
                dispCtx[c].strokeStyle = `hsl(${cdeg}deg, 60%, 50%)`;
                dispCtx[c].lineWidth   = 1.5;

                // Afficher les points des ellipses normalisées avec la couleur courante.
                xyNormCtx.fillStyle = dispCtx[c].strokeStyle;

                // Pour que l'épaisseur du trait soit indépendante de l'échelle,
                // on applique la recette suivante :
                // 1. Appliquer une tranformation au contexte courant.
                // 2. Construire le chemin.
                // 3. Restaurer le contexte courant.
                // 4. Tracer le chemin.

                dispCtx[c].save();
                dispCtx[c].setTransform(scaleX, 0, 0, -scaleY, leftX, deltaY);

                dispCtx[c].beginPath();

                k     = frameStart;
                kPrev = frameEnd;

                if (k > 0) {
                    dispCtx[c].moveTo(kPrev, dPrev[c]);
                }

                for (let j = i; j < jmax; j ++) {
                    const sample = readDisp(j);
                    if (!sample) {
                        continue disp_loop;
                    }
                    if (sample.channel !== c) {
                        continue;
                    }

                    if (k * scaleX > kPrev * scaleX) {
                        if (k === 0) {
                            dispCtx[c].moveTo(k, sample.d);
                        }
                        else {
                            dispCtx[c].lineTo(k, sample.d);
                        }
                        kPrev    = k;
                        dPrev[c] = sample.d;
                    }
                    k ++;

                    // Afficher un point d'une ellipse normalisée.
                    xyNormCtx.beginPath();
                    xyNormCtx.ellipse(sample.x, sample.y, r, r, 0, 0, Math.PI * 2);
                    xyNormCtx.fill();
                }

                dispCtx[c].restore();
                dispCtx[c].stroke();
            }

            frameStart = k;
            frameEnd   = kPrev;

            await animationFrame();

            frameLength = getDispFrameLength();
        }

        // Éliminer les échantillons traités.
        dispReceiver.drop(dispRetentionLength);
    }
}
