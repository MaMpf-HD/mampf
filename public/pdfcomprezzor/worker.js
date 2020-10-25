importScripts("wasm_exec.js")
//expects an array of uintArray if merge or compress, will only compress first.
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
        if (e.data.action == "merge") {
            console.log(e.data.array)
            bytesCount = merge(e.data.array, (err, message) => {
                self.postMessage({
                    err,
                    message,
                    type: "log"
                })
            });
            bytes = new Uint8Array(bytesCount);
            readBack(bytes);
            var b = performance.now();
            self.postMessage({
                result: bytes,
                type: "result",
                time: b - a
            });
            return;
        } else {
            let bytesCount = compress(e.data.array[0], (err, message) => {
                self.postMessage({
                    err,
                    message,
                    type: "log"
                })
            });
            bytes = new Uint8Array(bytesCount);
            readBack(bytes);
            var b = performance.now();
            self.postMessage({
                result: bytes,
                type: "result",
                time: b - a
            });
        }
    });
}, false);