fs = require("fs")
path = require("path")
expect = require("chai").expect
walk = require("..")

describe 'Mocha self test', ->
    it 'tests are working', ->
        expect(true).to.be.true.and.not.to.be.false;
