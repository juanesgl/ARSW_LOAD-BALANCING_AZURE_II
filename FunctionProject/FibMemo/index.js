var bigInt = require("big-integer");

var memo = {};
memo[0] = bigInt.zero;
memo[1] = bigInt.one;

var instanceStartedAt = new Date().toISOString();

function fibonacci(n) {
    if (memo[n] !== undefined) return memo[n];
    memo[n] = fibonacci(n - 1).add(fibonacci(n - 2));
    return memo[n];
}

module.exports = async function (context, req) {
    context.log('JavaScript HTTP trigger function processed a request.');

    let nth = req.body.nth;

    if (nth < 0)
        throw 'must be greater than 0';

    let cacheHit = memo[nth] !== undefined;
    let answer = fibonacci(nth);

    context.res = {
        headers: {
            "x-cache-hit": String(cacheHit),
            "x-cache-size": String(Object.keys(memo).length),
            "x-instance-started": instanceStartedAt
        },
        body: answer.toString()
    };
};