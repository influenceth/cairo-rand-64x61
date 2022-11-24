const chai = require('chai');
const starknet = require('hardhat').starknet;
const { getAccounts, to64x61, from64x61 } = require('./helpers');

// Setup test suite
const expect = chai.expect;
const REL_TOL = 5e-7;
const ABS_TOL = 5e-7;

describe('simplex', function () {
  this.timeout(600_000);
  let contract, user;

  before(async () => {
    const contractFactory = await starknet.getContractFactory('simplex_mock');
    contract = await contractFactory.deploy();
    const accounts = await getAccounts({ count: 1 });
    user = accounts[0];
  });

  it('should return accurate results for 3D noise', async () => {
    const argsList = [
      [ 0.0, 0.0, 0.0 ],
      [ 0.5, -1.23, 1.63 ],
      [ -1.94, -1.25, -1.63 ],
      [ -9.99, 8.25, 6.98 ],
      [ -0.005, 12.578, -2.87 ]
    ];

    const expected = [ -0.43587, 0.72507, 0.15408, -0.79204, -0.40012 ];

    for (const [ i, args ] of argsList.entries()) {
      const v = args.map((a) => to64x61(a));
      const { res } = await contract.call('noise3_test', { v });
      expect(Number(from64x61(res).toFixed(5))).to.equal(expected[i]);
    }
  });

  // Based on a 0 to 1 normalized single octave of webgl simplex3
  it('should return noise values for various percentiles', async () => {
    const argsList = [ 0.1, 0.6175, 0.2531 ];
    const expected = [ 0.26077, 0.55215, 0.38259 ];

    for (const [ i, args ] of argsList.entries()) {
      const percentile = to64x61(args);
      const { res } = await contract.call('noise3_at_percentile_test', { percentile });
      expect(Number(from64x61(res).toFixed(5))).to.equal(expected[i]);
    }
  });

  it('should return octave noise with one octave matching ', async () => {
    const argsList = [
      [ 0.0, 0.0, 0.0 ],
      [ 0.5, -1.23, 1.63 ],
      [ -1.94, -1.25, -1.63 ],
      [ -9.99, 8.25, 6.98 ],
      [ -0.005, 12.578, -2.87 ]
    ];

    const expected = [ -0.43587, 0.72507, 0.15408, -0.79204, -0.40012 ];

    for (const [ i, args ] of argsList.entries()) {
      const v = args.map((a) => to64x61(a));
      const { res } = await contract.call('noise3_octaves_test', { v, octaves: 1, persistence: to64x61(1) });
      expect(Number(from64x61(res).toFixed(5))).to.equal(expected[i]);
    }
  });

  it('should return octave noise with multiple octaves', async () => {
    const argsList = [
      { v: [ 0.5, -1.23, 1.63 ], octaves: 3, persistence: 0.5 },
      { v: [ -1.94, -1.25, -1.63 ], octaves: 2, persistence: 0.33 },
      { v: [ -9.99, 8.25, 6.98 ], octaves: 4, persistence: 0.25 }
    ];

    for (const [ i, args ] of argsList.entries()) {
      let expectedNoise = 0;
      let total = 0;

      for (let i = 0; i < args.octaves; i++) {
        total += Math.pow(args.persistence, i);
        const v = args.v.map((a) => to64x61(a / Math.pow(args.persistence, i)));
        const { res } = await contract.call('noise3_test', { v });
        const currentNoise = from64x61(res) * Math.pow(args.persistence, i);
        expectedNoise += currentNoise;
      }

      expectedNoise = expectedNoise / total;

      const { res } = await contract.call('noise3_octaves_test', {
        v: args.v.map((a) => to64x61(a)),
        octaves: args.octaves,
        persistence: to64x61(args.persistence)
      });

      expect(Number(from64x61(res).toFixed(5))).to.equal(Number(expectedNoise.toFixed(5)));
    }
  });

  it('should output information on execution', async () => {
    const args = { v: [ 0.5, -1.23, 1.63 ], octaves: 8, persistence: 0.5 };
    const txHash = await user.invoke(contract, 'noise3_octaves_test', {
      v: args.v.map((a) => to64x61(a)),
      octaves: args.octaves,
      persistence: to64x61(args.persistence)
    });

    const receipt = await starknet.getTransactionReceipt(txHash);
    const steps = receipt.execution_resources.n_steps / 8;
    const gas = steps * 0.05;
    console.log(gas.toLocaleString(), 'gas per noise3 octave');
  });
});
