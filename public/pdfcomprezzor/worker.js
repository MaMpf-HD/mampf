importScripts("wasm_exec.js")

self.addEventListener('message', function (e) {
    if (!WebAssembly.instantiateStreaming) { // polyfill
        WebAssembly.instantiateStreaming = async (resp, importObject) => {
            const source = await (await resp).arrayBuffer()
            return await WebAssembly.instantiate(source, importObject)
        }
    }
    const go = new Go();
    WebAssembly.instantiateStreaming(fetch("pdfcomprezzor.wasm"), go.importObject).then((result) => {
        go.run(result.instance);
        var a = performance.now();
        compress(e.data.array, e.data.l, (err, message) => {
            self.postMessage({
                err,
                message,
                type: "log"
            })
        });
        var b = performance.now();
        let result2 = e.data.array.slice(0, e.data.l.l);
        self.postMessage({
            result: result2,
            type: "result",
            time: b - a
        });
    });
}, false);