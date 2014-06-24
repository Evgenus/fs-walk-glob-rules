fs = require("fs")
mock = require("mock-fs")
yaml = require("js-yaml")
path = require("path")
chai = require("chai")
expect = chai.expect
walker = require("..")

chai.use (chai, util) ->
    chai.Assertion.addMethod "consist", (b) ->
        obj = util.flag(this, 'object');
        new chai.Assertion(obj).to.be.an("Array");
        new chai.Assertion(obj).to.have.length(b.length);
        ourB = b.concat()
        return obj.every (item) =>
            index = ourB.indexOf(item)
            if index < 0
                this.assert(false, "#{item} was not found in #{b}")
                return false
            else
                ourB.splice(index, 1)
                return true

describe 'Mocha self test', ->
    it 'tests are working', ->
        expect(true).to.be.true.and.not.to.be.false;

beforeEach ->
    @old_cwd = process.cwd()
    process.chdir("/")

describe 'Async', ->
    beforeEach ->
        mock(yaml.safeLoad("""
            a.js: //empty
            a/b.js: //empty
            aa/c.js: //empty
            test/d.js: //empty
            test/e.js: //empty
        """))

    it './**/(*.js) -> $1', (done) ->
        walked = []
        walker.walk
            root: "/"
            rules:
                "./**/(*.js)": "$1"
            callback: (p, next) ->
                walked.push(p)
                next()
            error: (error) ->
                expect(err).to.be.null
            complete: () ->
                expect(walked).to.deep.equal([
                    {
                        "result": "b.js",
                        "source": "./a/b.js"
                    },
                    {
                        "result": "c.js",
                        "source": "./aa/c.js"
                    },
                    {
                        "result": "d.js",
                        "source": "./test/d.js"
                    },
                    {
                        "result": "e.js",
                        "source": "./test/e.js"
                    }
                ])
                done()

    it './(a*/*.js) -> $1', (done) ->
        walked = []
        walker.walk
            root: "/"
            rules:
                "./(a*/*.js)": "$1"
            callback: (p, next) ->
                walked.push(p)
                next()
            error: (error) ->
                expect(err).to.be.null
            complete: () ->
                expect(walked).to.deep.equal([
                    {
                        "result": "a/b.js",
                        "source": "./a/b.js"
                    },
                    {
                        "result": "aa/c.js",
                        "source": "./aa/c.js"
                    }
                ])
                done()

    it './(a*/*.js) -> $1', (done) ->
        walked = []
        walker.walk
            root: "/"
            rules:
                "./(a*/*.js)": "$1"
            excludes:[
                "./aa/**"
            ]
            callback: (p, next) ->
                walked.push(p)
                next()
            error: (error) ->
                expect(err).to.be.null
            complete: () ->
                expect(walked).to.deep.equal([
                    {
                        "result": "a/b.js",
                        "source": "./a/b.js"
                    }
                ])
                done()

describe 'Sync', ->
    beforeEach ->
        mock(yaml.safeLoad("""
            a.js: //empty
            a/b.js: //empty
            aa/c.js: //empty
            test/d.js: //empty
            test/e.js: //empty
        """))

    it './**/(*.js) -> $1', ->
        walked = walker.walkSync
            root: "/"
            rules:
                "./**/(*.js)": "$1"

        expect(walked).to.deep.equal([
            {
                "result": "b.js",
                "source": "./a/b.js"
            },
            {
                "result": "c.js",
                "source": "./aa/c.js"
            },
            {
                "result": "d.js",
                "source": "./test/d.js"
            },
            {
                "result": "e.js",
                "source": "./test/e.js"
            }
        ])

    it './(a*/*.js) -> $1', ->
        walked =  walker.walkSync
            root: "/"
            rules:
                "./(a*/*.js)": "$1"
        expect(walked).to.deep.equal([
            {
                "result": "a/b.js",
                "source": "./a/b.js"
            },
            {
                "result": "aa/c.js",
                "source": "./aa/c.js"
            }
        ])

    it './(a*/*.js) -> $1', ->
        walked =  walker.walkSync
            root: "/"
            rules:
                "./(a*/*.js)": "$1"
            excludes:[
                "./aa/**"
            ]
        expect(walked).to.deep.equal([
            {
                "result": "a/b.js",
                "source": "./a/b.js"
            }
        ])

afterEach ->
    mock.restore()
    process.chdir(@old_cwd)
