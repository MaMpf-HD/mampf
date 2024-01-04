const { environment } = require("@rails/webpacker");
const coffee = require("./loaders/coffee");
const css = require("./loaders/css");

// Fix OpenSSL error starting with Node.js 17.
//
// This error occurred since a new version of OpenSSL shipping with Node.js 17+
// removed support for MD4. This is actually very good as MD4 is insecure.
// However, webpack 5 is using MD4 as default hashing algorithm, that's why we
// got the error "error:0308010C:digital envelope routines::unsupported".
// Note that webpacker uses webpack v4.x but this also uses MD4 as default, see [3].
//
// To fix this, we configure webpack (via webpacker) to use a newer hash algorithm.
// This is done by setting the output.hashFunction to "sha256".
// This fix was proposed in [1] and [2]. The syntax for how to configure
// webpack when using webpacker is documented in [4].
// environment.config.set("output.hashFunction", "sha256");
// -> However, that didn't work, even when specifying the hashFunction in the
// webpack loaders, for example for the css loader.
//
// SOLUTION: That's why we use a more brute-force approach here, by replacing the
// crypto.createHash function with a function that replaces the algorithm
// "md4" with "sha256". This way, whenever any code calls crypto.createHash("md4"),
// it will actually call crypto.createHash("sha256") instead. This might not work
// in multiprocess environments, but it works for us as we only compile the assets
// in one container.
// This solution was proposed in [5].
//
// Note that while sha256 is a good choice, sha512 is more secure.
// However, we don't specify hashing for passwords here, just for files we serve
// statically to the client. So we don't need the extra security of sha512,
// and can leverage the benefit of sha256 being faster to compute.
//
// [1] https://stackoverflow.com/a/73027407/
// [2] https://stackoverflow.com/a/69476335/
// [3] Webpack: https://v4.webpack.js.org/configuration/output/#outputhashfunction
// [4] https://github.com/rails/webpacker/blob/5-x-stable/docs/webpack.md#configuration
// [5] https://stackoverflow.com/a/72219174/
const crypto = require("crypto");
const originalHashFunction = crypto.createHash;
crypto.createHash = (algorithm, options) => {
  return originalHashFunction(algorithm === "md4" ? "sha256" : algorithm, options);
};

environment.loaders.prepend("coffee", coffee);
environment.loaders.prepend("css", css);

module.exports = environment;
