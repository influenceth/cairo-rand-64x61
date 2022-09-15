const chai = require('chai');
const almost = require('almost-equal');
const starknet = require('hardhat').starknet;
const { toFelt, to64x61, from64x61 } = require('./helpers');

// Setup test suite
const expect = chai.expect;
const REL_TOL = 5e-7;
const ABS_TOL = 5e-7;

describe('simplex', function () {
  this.timeout(600_000);
  let contract;

  before(async () => {
    const contractFactory = await starknet.getContractFactory('simplex_mock');
    contract = await contractFactory.deploy();
  });

  it('should return accurate results for 3D noise', async () => {
    const argsList = [
      [ 0.0, 0.0, 0.0 ],
      [ 0.5, -1.23, 1.63 ],
      [ -1.94, -1.25, -1.63 ],
      [ -9.99, 8.25, 6.98 ],
      [ -0.005, 12.578, -2.87 ]
    ];

    const expected = [ -0.4122, 0.6335, 0.21512, -0.72603, -0.50797 ];

    for (const [ i, args ] of argsList.entries()) {
      const v = args.map((a) => to64x61(a));
      const { res } = await contract.call('Simplex_noise3_test', { v });
      expect(Number(from64x61(res).toFixed(5))).to.equal(expected[i]);
    }
  });
});